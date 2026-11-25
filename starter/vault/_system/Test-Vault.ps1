<#
.SYNOPSIS
  Checks that a Reality OS starter vault is set up correctly.
.DESCRIPTION
  Prints one PASS, WARN or FAIL line per check. Exit code = number of FAILs.
  Runs on Windows PowerShell 5.1 with no modules. Read-only except for one
  temporary probe file in _system, which it deletes.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File _system\Test-Vault.ps1
#>
param(
    [string]$Path = (Split-Path -Parent $PSScriptRoot)
)

$script:Fails = 0
$script:Warns = 0

function Pass([string]$m) { Write-Host "PASS  $m" }
function Warn([string]$m) { $script:Warns++; Write-Host "WARN  $m" -ForegroundColor Yellow }
function Fail([string]$m) { $script:Fails++; Write-Host "FAIL  $m" -ForegroundColor Red }

$Path = (Resolve-Path -LiteralPath $Path).ProviderPath
Write-Host "Checking vault: $Path"
Write-Host ""

# 1. Files and folders
$files = @('AGENTS.md', 'CLAUDE.md', 'Home.md', 'Inbox.md', 'Open Loops.md', 'About.md', 'Prompts.md',
           '.gitattributes', '.gitignore', '_system\Corrections.md', '_system\SETUP.md', '.claude\settings.json', '_system\Backup-Vault.ps1', '_system\Enable-Backup.ps1',
           'Templates\Daily.md', 'Templates\Project.md', 'Templates\Decision.md',
           'Templates\Meeting.md', 'Templates\Person.md', 'Templates\Weekly Review.md')
$dirs = @('Daily', 'Projects', 'Decisions', 'Meetings', 'People', 'Notes', 'Templates',
          '_proposals\claude', '_proposals\chatgpt')
$missing = @()
foreach ($f in $files) { if (-not (Test-Path -LiteralPath (Join-Path $Path $f) -PathType Leaf)) { $missing += $f } }
foreach ($d in $dirs) { if (-not (Test-Path -LiteralPath (Join-Path $Path $d) -PathType Container)) { $missing += "$d\" } }
if ($missing.Count -eq 0) { Pass "all starter files and folders are present" }
else { Fail ("missing: " + ($missing -join ', ') + ". Copy them back from the kit's starter\vault folder.") }

# 2. AGENTS.md rules
$agentsPath = Join-Path $Path 'AGENTS.md'
if (Test-Path -LiteralPath $agentsPath) {
    $lines = [IO.File]::ReadAllLines($agentsPath)
    $section = ''
    $starter = 0
    $standing = 0
    foreach ($l in $lines) {
        if ($l -match '^##\s+(.+?)\s*$') { $section = $Matches[1]; continue }
        if ($section -eq 'Starter rules' -and $l -match '^\d+\.\s+\*\*') { $starter++ }
        if ($section -eq 'Standing rules' -and $l -match '^-\s+\*\*R-\d+\*\*') { $standing++ }
    }
    if ($starter -eq 5) { Pass "AGENTS.md has the 5 starter rules" }
    else { Fail "AGENTS.md has $starter starter rules; it should have exactly 5. Restore them from the kit." }
    if ($standing -le 10) { Pass "AGENTS.md has $standing of at most 10 standing rules" }
    else { Fail "AGENTS.md has $standing standing rules; the limit is 10. Retire some in the weekly review." }
}

# 3. CLAUDE.md points at AGENTS.md
$claudePath = Join-Path $Path 'CLAUDE.md'
if ((Test-Path -LiteralPath $claudePath) -and (([IO.File]::ReadAllText($claudePath)) -match '(?m)^@AGENTS\.md\s*$')) {
    Pass "CLAUDE.md points Claude at AGENTS.md"
} else {
    Fail "CLAUDE.md must contain the line @AGENTS.md so Claude reads the same rules as ChatGPT."
}

# 4. Git
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Fail "Git is not installed or not on PATH. Run: winget install --id Git.Git -e   then close and reopen this window (and restart the Claude and ChatGPT apps)."
} else {
    Pass "Git is installed"
    $inside = (& git -C $Path rev-parse --is-inside-work-tree 2>&1 | ForEach-Object { "$_" }) -join "`n"
    if ($inside -match 'dubious ownership') {
        Fail "Git refuses this folder because a different Windows user owns it (this can happen when an app runs commands as a sandbox user). Run: git config --global --add safe.directory `"$($Path -replace '\\','/')`""
    } elseif ($LASTEXITCODE -eq 0 -and $inside.Trim() -eq 'true') {
        Pass "the vault is a Git repository"
        $name = & git -C $Path config user.name 2>$null
        $mail = & git -C $Path config user.email 2>$null
        if ("$name".Trim() -and "$mail".Trim()) { Pass "Git knows who is committing" }
        else { Fail "Git has no user name or email. Run: git -C `"$Path`" config user.name `"Your Name`"  and  git -C `"$Path`" config user.email `"you@example.com`"" }
        $dirty = @(& git -C $Path status --porcelain 2>$null | Where-Object { $_ })
        if ($dirty.Count -eq 0) { Pass "no uncommitted changes" }
        else { Warn "$($dirty.Count) uncommitted change(s). Ask the AI to commit them, or run: git -C `"$Path`" add -A; git -C `"$Path`" commit -m `"manual: save`"" }
    } else {
        Fail "the vault is not a Git repository. Run: git -C `"$Path`" init"
    }
}

# 5. Write and read back UTF-8 without a BOM, including non-ASCII text
$probe = Join-Path $Path '_system\.probe'
try {
    $text = "probe " + [string][char]0x00E9 + [string][char]0x2014 + [string][char]0x2713 + "`n"
    $enc = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($probe, $text, $enc)
    $bytes = [IO.File]::ReadAllBytes($probe)
    $back = $enc.GetString($bytes)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    if ($back -eq $text -and -not $hasBom) { Pass "notes can be written and read back as UTF-8" }
    else { Fail "a test write did not read back exactly. Check that the folder is not read-only or being synced." }
} catch {
    Fail "could not write in _system: $($_.Exception.Message)"
} finally {
    if (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue }
}

# 6. Not inside a synced folder
$synced = $false
foreach ($root in @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) {
    if ($root -and $Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { $synced = $true }
}
if ($synced) { Warn "the vault is inside OneDrive. Sync can create conflict copies; a folder like C:\Users\<you>\Vault is safer." }
else { Pass "the vault is not inside OneDrive" }

# 7. Backup
$backupFile = Join-Path $Path '.git\realityos-backup.json'
if (Test-Path -LiteralPath $backupFile) {
    $b = $null
    try { $b = [IO.File]::ReadAllText($backupFile) | ConvertFrom-Json } catch { }
    if ($b -and $b.secret) { Fail "the backup stopped: something that looks like a key or password is in $($b.secret). Remove it from the note." }
    elseif ($b -and $b.remote -and -not $b.pushed) {
        Warn "the last cloud backup didn't go through: $($b.message) If GitHub wants you to sign in again, run: git -C `"$Path`" push"
    } elseif ($b) { Pass "automatic backup ran at $($b.ran)" }
} else {
    Warn "automatic backup hasn't run yet. To turn it on: powershell -NoProfile -ExecutionPolicy Bypass -File _system\Enable-Backup.ps1"
}

# 8. Setup finished
$homePath = Join-Path $Path 'Home.md'
if ((Test-Path -LiteralPath $homePath) -and (([IO.File]::ReadAllText($homePath)) -match 'Setup: not started')) {
    Warn "setup is not finished yet. In the Claude Code tab, say: Read _system/SETUP.md and follow it."
} else {
    Pass "setup has been run"
}

Write-Host ""
Write-Host "$script:Fails failed, $script:Warns warning(s)."
exit $script:Fails
