<#
  CI checks for the starter kit. Runs on Windows PowerShell 5.1 (windows-latest).
  Builds a vault with New-Vault.ps1, then checks that Test-Vault.ps1 passes it
  and fails it when it is broken in known ways. Exit code = number of failed checks.
#>
$ErrorActionPreference = 'Continue'
$kit = Split-Path -Parent $PSScriptRoot
$failed = 0
function Check([bool]$ok, [string]$m) {
    if ($ok) { Write-Host "ok    $m" } else { $script:failed++; Write-Host "FAIL  $m" -ForegroundColor Red }
}
function Run-Ps([string]$file, [string[]]$scriptArgs) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $file @scriptArgs | Out-Host
    return $LASTEXITCODE
}

Write-Host "PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
Check ($PSVersionTable.PSVersion.Major -eq 5) "running on Windows PowerShell 5.x, the version Windows ships"

# Scripts must be pure ASCII (5.1 reads BOM-less UTF-8 as the ANSI code page) and must parse.
$scripts = @(Get-ChildItem -LiteralPath $kit -Recurse -Filter *.ps1 -Force)
foreach ($s in $scripts) {
    $bytes = [IO.File]::ReadAllBytes($s.FullName)
    $nonAscii = @($bytes | Where-Object { $_ -gt 127 }).Count
    Check ($nonAscii -eq 0) "$($s.Name) is ASCII-only"
    $tokens = $null; $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($s.FullName, [ref]$tokens, [ref]$errs)
    Check ($errs.Count -eq 0) "$($s.Name) parses"
}

$tempRoot = $env:RUNNER_TEMP
if (-not $tempRoot) { $tempRoot = [IO.Path]::GetTempPath() }
$work = Join-Path $tempRoot ("starter-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null
$vault = Join-Path $work 'Vault'
$newVault = Join-Path $kit 'tools\New-Vault.ps1'

# 1. A fresh vault is created and passes.
$code = Run-Ps $newVault @('-Path', $vault, '-Name', 'CI User', '-Email', 'ci@example.invalid')
Check ($code -eq 0) "New-Vault.ps1 creates a vault (exit $code)"
Check (Test-Path -LiteralPath (Join-Path $vault '.gitignore')) "dotfiles were copied"
Check (Test-Path -LiteralPath (Join-Path $vault '.obsidian\daily-notes.json')) "Obsidian settings were copied"
$settingsOk = $false
try { $settings = [IO.File]::ReadAllText((Join-Path $vault '.claude\settings.json')) | ConvertFrom-Json; $allow = @($settings.permissions.allow); $settingsOk = (($allow -contains 'Bash(git commit *)') -and ($allow -contains 'PowerShell(git commit *)')) } catch { }
Check $settingsOk "Claude project settings were copied, parse, and cover both Bash and PowerShell"
$tracked = @(& git -C $vault ls-files 2>$null)
Check ($tracked -contains '.claude/settings.json') "Claude project settings are committed"
Check ($tracked -contains '.obsidian/templates.json') "shipped Obsidian settings are committed"
$skill = Join-Path $vault '.claude\skills\my-voice\SKILL.md'
$skillText = ''
if (Test-Path -LiteralPath $skill) { $skillText = [IO.File]::ReadAllText($skill) }
Check ($skillText.StartsWith('---') -and $skillText -match '(?m)^description: .+' -and $skillText -match 'Voice\.md') "the my-voice skill has frontmatter and points at Voice.md"
Check ($tracked -contains '.claude/skills/my-voice/SKILL.md' -and $tracked -contains 'Voice.md') "the voice skill and note are committed"
$count = "$(& git -C $vault rev-list --count HEAD 2>$null)".Trim()
Check ($count -eq '1') "the vault has its first commit ($count)"
$branch = "$(& git -C $vault rev-parse --abbrev-ref HEAD 2>$null)".Trim()
Check ($branch -eq 'main') "the branch is main ($branch)"
$testVault = Join-Path $vault '_system\Test-Vault.ps1'
$code = Run-Ps $testVault @()
Check ($code -eq 0) "Test-Vault.ps1 passes a fresh vault (exit $code)"

# 2. It refuses to overwrite a folder that has files in it.
$code = Run-Ps $newVault @('-Path', $vault, '-Name', 'CI User', '-Email', 'ci@example.invalid')
Check ($code -ne 0) "New-Vault.ps1 refuses a non-empty folder (exit $code)"
Check ("$(& git -C $vault rev-list --count HEAD 2>$null)".Trim() -eq '1') "the existing vault was left alone"

# 3. Test-Vault fails a broken vault.
$agents = Join-Path $vault 'AGENTS.md'
$original = [IO.File]::ReadAllText($agents)
$enc = New-Object System.Text.UTF8Encoding($false)

[IO.File]::WriteAllText($agents, $original.Replace("## Standing rules", "6. **Extra.** An added rule.`n`n## Standing rules"), $enc)
Check ((Run-Ps $testVault @()) -ne 0) "Test-Vault.ps1 fails a sixth starter rule"

$eleven = (1..11 | ForEach-Object { "- **R-$_** (2026-01-01, from C-00$_): rule $_" }) -join "`n"
[IO.File]::WriteAllText($agents, $original.Replace("_None yet._`n`n## When I correct you", "$eleven`n`n## When I correct you").Replace("_None yet._`r`n`r`n## When I correct you", "$eleven`r`n`r`n## When I correct you"), $enc)
Check ((Run-Ps $testVault @()) -ne 0) "Test-Vault.ps1 fails an eleventh standing rule"
[IO.File]::WriteAllText($agents, $original, $enc)

$claudeMd = Join-Path $vault 'CLAUDE.md'
[IO.File]::WriteAllText($claudeMd, "nothing here`n", $enc)
Check ((Run-Ps $testVault @()) -ne 0) "Test-Vault.ps1 fails when CLAUDE.md does not point at AGENTS.md"
[IO.File]::WriteAllText($claudeMd, "@AGENTS.md`n", $enc)

Remove-Item -LiteralPath (Join-Path $vault 'Open Loops.md') -Force
Check ((Run-Ps $testVault @()) -ne 0) "Test-Vault.ps1 fails when a starter note is missing"
& git -C $vault checkout -q -- 'Open Loops.md'

Check ((Run-Ps $testVault @()) -eq 0) "Test-Vault.ps1 passes again once repaired"

# 4. Obsidian's own per-device files stay out of Git.
[IO.File]::WriteAllText((Join-Path $vault '.obsidian\app.json'), "{}", $enc)
$status = @(& git -C $vault status --porcelain --ignored=no -- .obsidian 2>$null | Where-Object { $_ })
Check ($status.Count -eq 0) "Obsidian's app.json is ignored"

# 5. Show-Usage counts app commits.
Add-Content -LiteralPath (Join-Path $vault 'Inbox.md') -Value 'test item'
& git -C $vault add -A
& git -C $vault commit -q -m "claude: test commit"
$out = (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $vault '_system\Show-Usage.ps1') -Path $vault) -join "`n"
Write-Host $out
Check ($out -match 'Days with at least one change: 1 of 14') "Show-Usage.ps1 counts active days"
Check ($out -match 'Changes by Claude: 1') "Show-Usage.ps1 counts commits by app"

# 6. The one-step installer (apps skipped; Obsidian settings in a scratch APPDATA).
$realAppData = $env:APPDATA
$env:APPDATA = Join-Path $work 'appdata'
$env:REALITYOS_NO_AUTORUN = '1'
. (Join-Path $kit 'install.ps1')
$vault2 = Join-Path $work 'Vault2'
$r = @(Install-RealityOS -SkipApps -NoBackupTask -LocalKit (Split-Path -Parent $kit) -VaultPath $vault2 -Name 'CI User' -Email 'ci@example.invalid')
Check ($r[-1] -eq $true) "install.ps1 completes with apps skipped"
Check (Test-Path -LiteralPath (Join-Path $vault2 'AGENTS.md')) "install.ps1 creates the vault"
$obs = Join-Path $env:APPDATA 'obsidian\obsidian.json'
$reg = $null
try { $reg = [IO.File]::ReadAllText($obs) | ConvertFrom-Json } catch { }
$entries = @()
if ($reg) { $entries = @($reg.vaults.PSObject.Properties | ForEach-Object { $_.Value }) }
Check ($entries.Count -eq 1 -and $entries[0].path -eq $vault2 -and $entries[0].open -eq $true) "install.ps1 registers the vault in Obsidian and marks it open"
$r = @(Install-RealityOS -SkipApps -NoBackupTask -LocalKit (Split-Path -Parent $kit) -VaultPath $vault2)
$reg = [IO.File]::ReadAllText($obs) | ConvertFrom-Json
Check ($r[-1] -eq $true -and @($reg.vaults.PSObject.Properties).Count -eq 1) "running install.ps1 again changes nothing"
Check ("$(& git -C $vault2 rev-list --count HEAD 2>$null)".Trim() -eq '1') "the second run left the vault's history alone"
$env:APPDATA = $realAppData
Remove-Item Env:\REALITYOS_NO_AUTORUN

# 7. Automatic backup: snapshot, push to a remote, stop on secrets, scheduled task.
$backup = Join-Path $vault2 '_system\Backup-Vault.ps1'
$bare = Join-Path $work 'remote.git'
& git init -q --bare $bare
& git -C $vault2 remote add origin $bare
$noteFile = Join-Path $vault2 'Notes\Edited in Obsidian.md'
[IO.File]::WriteAllText($noteFile, "typed directly in Obsidian`n", $enc)
(Get-Item -LiteralPath $noteFile).LastWriteTime = (Get-Date).AddMinutes(-30)
$code = Run-Ps $backup @('-Path', $vault2)
$last = "$(& git -C $vault2 log -1 --format=%s 2>$null)".Trim()
Check ($code -eq 0 -and $last -eq 'auto: snapshot') "Backup-Vault.ps1 snapshots quiet uncommitted edits ($last)"
$remoteHead = "$(& git -C $bare rev-parse main 2>$null)".Trim()
$localHead = "$(& git -C $vault2 rev-parse HEAD 2>$null)".Trim()
Check ($remoteHead -and $remoteHead -eq $localHead) "Backup-Vault.ps1 pushes to the backup remote"
$bj = [IO.File]::ReadAllText((Join-Path $vault2 '.git\realityos-backup.json')) | ConvertFrom-Json
Check ($bj.pushed -eq $true -and $bj.lastPush) "Backup-Vault.ps1 records the push"
Check ((Run-Ps (Join-Path $vault2 '_system\Test-Vault.ps1') @('-Path', $vault2)) -eq 0) "Test-Vault.ps1 passes after a backup"

$fresh = Join-Path $vault2 'Notes\Typed just now.md'
[IO.File]::WriteAllText($fresh, "still typing`n", $enc)
[void](Run-Ps $backup @('-Path', $vault2))
Check ("$(& git -C $vault2 status --porcelain 2>$null)".Trim() -ne '') "Backup-Vault.ps1 waits while edits are recent"
(Get-Item -LiteralPath $fresh).LastWriteTime = (Get-Date).AddMinutes(-30)

$keyFile = Join-Path $vault2 'Notes\Pasted setup.md'
$fakeKey = 'sk-ant-' + ('a' * 40)
[IO.File]::WriteAllText($keyFile, "my key: $fakeKey`n", $enc)
(Get-Item -LiteralPath $keyFile).LastWriteTime = (Get-Date).AddMinutes(-30)
$before = "$(& git -C $vault2 rev-parse HEAD 2>$null)".Trim()
[void](Run-Ps $backup @('-Path', $vault2))
Check ("$(& git -C $vault2 rev-parse HEAD 2>$null)".Trim() -eq $before) "Backup-Vault.ps1 refuses to save a note containing an API key"
Check ((Run-Ps (Join-Path $vault2 '_system\Test-Vault.ps1') @('-Path', $vault2)) -ne 0) "Test-Vault.ps1 fails while a key is in a note"
Remove-Item -LiteralPath $keyFile -Force
[void](Run-Ps $backup @('-Path', $vault2))
Check ("$(& git -C $vault2 log -1 --format=%s 2>$null)".Trim() -eq 'auto: snapshot') "the backup resumes once the key is removed"

$usage = (& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $vault2 '_system\Show-Usage.ps1') -Path $vault2) -join "`n"
Check ($usage -match 'Automatic backup snapshots \(not counted as use\): 2') "Show-Usage.ps1 doesn't count backup snapshots as use"

$taskName = 'RealityOS CI ' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$enable = Join-Path $vault2 '_system\Enable-Backup.ps1'
$code = Run-Ps $enable @('-Path', $vault2, '-TaskName', $taskName)
Check ($code -eq 0 -and (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) "Enable-Backup.ps1 registers the hourly task"
$code = Run-Ps $enable @('-Path', $vault2, '-TaskName', $taskName, '-Disable')
Check ($code -eq 0 -and -not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) "Enable-Backup.ps1 -Disable removes it"

Write-Host ""
Write-Host "$failed check(s) failed."
exit $failed
