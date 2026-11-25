<#
.SYNOPSIS
  ALPHA. Adds Reality OS to a vault you already have, without moving, renaming
  or rewriting your notes.
.DESCRIPTION
  1. Checks the folder looks like a vault and holds nothing that looks like a
     password or API key (if it does, it stops and changes nothing).
  2. Takes a snapshot: commits everything as "adopt: before Reality OS", so the
     whole adoption can be undone. If the vault has no Git yet and lives in
     OneDrive, Git's history is kept outside OneDrive (sync can corrupt it).
  3. Adds only the Reality OS files that are missing. Where you already have a
     file with the same job (AGENTS.md, CLAUDE.md, .claude\settings.json), it
     leaves yours alone and puts the Reality OS version in _proposals\claude\
     for the AI to merge with you.
  4. Writes _system\vault.json with what it can tell about your vault (daily
     notes folder, templates folder). The AI maps the rest with you by
     following _system\ADOPT.md.
  Running it again is safe: it only adds what's still missing and refreshes
  the kit's own scripts.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\RealityOS-kit\starter\tools\Adopt-Vault.ps1" -Path "C:\Users\you\Documents\My Vault"
#>
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Name,
    [string]$Email
)
$ErrorActionPreference = 'Continue'
$enc = New-Object System.Text.UTF8Encoding($false)
function Say([string]$m) { Write-Host $m }
function Bad([string]$m) { Write-Host $m -ForegroundColor Red }

$kitVault = Join-Path (Split-Path -Parent $PSScriptRoot) 'vault'
if (-not (Test-Path -LiteralPath (Join-Path $kitVault 'AGENTS.md'))) { Bad "Can't find the kit's starter\vault next to this script. Run it from inside the downloaded kit."; exit 1 }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Bad "Git is not installed. Run: winget install --id Git.Git -e --source winget   then open a new PowerShell window."; exit 1 }
if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Bad "$Path doesn't exist."; exit 1 }
$Path = (Resolve-Path -LiteralPath $Path).ProviderPath.TrimEnd('\')

$notes = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Filter *.md -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notlike "$Path\.git\*" })
if ($notes.Count -eq 0) { Bad "$Path has no Markdown notes. For a new vault, use New-Vault.ps1 instead."; exit 1 }
Say "Adopting $Path ($($notes.Count) notes). ALPHA: your notes are not moved, renamed or rewritten."

# 1. Nothing that looks like a key or password.
$secretPattern = 'sk-ant-[A-Za-z0-9_-]{20,}|sk-(proj-)?[A-Za-z0-9_-]{32,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----'
$hits = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "$Path\.git\*" -and $_.Length -lt 5MB } |
    Select-String -Pattern $secretPattern -List -ErrorAction SilentlyContinue)
if ($hits.Count -gt 0) {
    Bad "Stopped before changing anything: these files contain something that looks like a password, API key or token:"
    $hits | ForEach-Object { Bad ("  " + $_.Path.Substring($Path.Length).TrimStart('\')) }
    Bad "Move the key to the app or service it belongs to (or move the file out of the vault), then run this again."
    exit 2
}

# 2. Git and the snapshot.
$inside = "$(& git -C $Path rev-parse --is-inside-work-tree 2>$null)".Trim()
if ($inside -eq 'true') {
    $top = "$(& git -C $Path rev-parse --show-toplevel 2>$null)".Trim() -replace '/', '\'
    if ($top.TrimEnd('\') -ine $Path) { Bad "$Path is inside another Git repository ($top). Adopt the vault from its own folder, or move it out first."; exit 1 }
    Say "The vault already uses Git; keeping its history."
} else {
    $inOneDrive = $false
    foreach ($root in @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) {
        if ($root -and $Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { $inOneDrive = $true }
    }
    if ($inOneDrive) {
        $sha = [Security.Cryptography.SHA256]::Create()
        $hash = ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Path.ToLowerInvariant())) | Select-Object -First 4 | ForEach-Object { $_.ToString('x2') }) -join ''
        $leaf = (Split-Path -Leaf $Path) -replace '[^A-Za-z0-9_-]', '-'
        $gitDir = Join-Path $HOME ".realityos\git\$leaf-$hash"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $gitDir) | Out-Null
        & git init -q --separate-git-dir $gitDir $Path 2>$null
        Say "The vault is in OneDrive, so its Git history is kept outside it, at $gitDir."
    } else {
        & git init -q $Path 2>$null
    }
    if ($LASTEXITCODE -ne 0) { Bad "git init failed in $Path."; exit 1 }
    & git -C $Path symbolic-ref HEAD refs/heads/main 2>$null
    if (-not (Test-Path -LiteralPath (Join-Path $Path '.gitignore'))) {
        # In an adopted vault, keep the owner's Obsidian settings and plugins; ignore only per-device state.
        [IO.File]::WriteAllText((Join-Path $Path '.gitignore'), "# Obsidian per-device state`n.obsidian/workspace*.json`n.obsidian/cache`n.trash/`n# Per-device Claude settings`n.claude/settings.local.json`n# Setup probe file`n_system/.probe`n", $enc)
    }
}

$globalName = "$(& git config --global user.name 2>$null)".Trim()
$globalMail = "$(& git config --global user.email 2>$null)".Trim()
$localName = "$(& git -C $Path config --local user.name 2>$null)".Trim()
if (-not $globalName -and -not $localName) {
    if (-not $Name -and -not [Console]::IsInputRedirected) { $Name = Read-Host "Your name (used to label your own changes in the vault's history)" }
    if (-not $Email -and -not [Console]::IsInputRedirected) { $Email = Read-Host "Your email (stays on this computer; Git just needs one)" }
    if (-not $Name) { $Name = 'Vault owner' }
    if (-not $Email) { $Email = 'owner@localhost' }
    & git -C $Path config user.name $Name
    & git -C $Path config user.email $Email
} elseif ($Name -or $Email) {
    if ($Name) { & git -C $Path config user.name $Name }
    if ($Email) { & git -C $Path config user.email $Email }
}

$dirty = @(& git -C $Path status --porcelain 2>$null | Where-Object { $_ })
if ($dirty.Count -gt 0) {
    & git -C $Path add -A 2>$null
    & git -C $Path commit -q -m "adopt: before Reality OS" 2>$null
    if ($LASTEXITCODE -ne 0) { Bad "The snapshot commit failed. Nothing else was changed."; exit 1 }
    Say "Snapshot saved as the commit 'adopt: before Reality OS'. Everything Reality OS changes from here can be undone back to it."
}

# 3. Add what's missing. Never overwrite the owner's files.
$added = @(); $proposed = @()
function Add-IfMissing([string]$rel, [string]$srcRel) {
    if (-not $srcRel) { $srcRel = $rel }
    $dst = Join-Path $Path $rel
    if (Test-Path -LiteralPath $dst) { return $false }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    Copy-Item -LiteralPath (Join-Path $kitVault $srcRel) -Destination $dst
    $script:added += $rel
    return $true
}
function Propose([string]$name, [string]$content) {
    $dst = Join-Path $Path "_proposals\claude\$name"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    [IO.File]::WriteAllText($dst, $content, $enc)
    $script:proposed += "_proposals\claude\$name"
}

foreach ($d in @('_proposals\claude', '_proposals\chatgpt')) {
    $dir = Join-Path $Path $d
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null; [IO.File]::WriteAllText((Join-Path $dir '.gitkeep'), '', $enc); $added += "$d\" }
}

if (-not (Add-IfMissing 'AGENTS.md')) {
    $kitAgents = [IO.File]::ReadAllText((Join-Path $kitVault 'AGENTS.md'))
    if (-not ([IO.File]::ReadAllText((Join-Path $Path 'AGENTS.md')) -match '(?m)^## Starter rules')) { Propose 'AGENTS.reality-os.md' $kitAgents }
}
$claudeMd = Join-Path $Path 'CLAUDE.md'
if (-not (Add-IfMissing 'CLAUDE.md')) {
    $theirs = [IO.File]::ReadAllText($claudeMd)
    if (-not ($theirs -match '(?m)^@AGENTS\.md\s*$')) { Propose 'CLAUDE.reality-os.md' ($theirs.TrimEnd() + "`n`n@AGENTS.md`n") }
}
if (-not (Add-IfMissing '.claude\settings.json')) {
    $kitSettings = Join-Path $kitVault '.claude\settings.json'
    if ((Get-FileHash -LiteralPath $kitSettings).Hash -ne (Get-FileHash -LiteralPath (Join-Path $Path '.claude\settings.json')).Hash) {
        Propose 'settings.reality-os.json' ([IO.File]::ReadAllText($kitSettings))
    }
}
[void](Add-IfMissing '.claude\skills\my-voice\SKILL.md')
[void](Add-IfMissing '.gitattributes')
$mapPath = Join-Path $Path '_system\vault.json'
$existingMap = $null
if (Test-Path -LiteralPath $mapPath) { try { $existingMap = [IO.File]::ReadAllText($mapPath) | ConvertFrom-Json } catch { } }
if ($existingMap) {
    # Already adopted: keep the names chosen the first time.
    $voiceName = $existingMap.voice; $promptsName = $existingMap.prompts
    if ($voiceName) { [void](Add-IfMissing ($voiceName -replace '/', '\') 'Voice.md') }
    if ($promptsName) { [void](Add-IfMissing ($promptsName -replace '/', '\') 'Prompts.md') }
} else {
    # The owner may already have a note called Voice.md or Prompts.md; never overwrite it.
    $voiceName = 'Voice.md'
    if (-not (Add-IfMissing 'Voice.md')) { $voiceName = 'Reality OS Voice.md'; [void](Add-IfMissing $voiceName 'Voice.md') }
    $promptsName = 'Prompts.md'
    if (-not (Add-IfMissing 'Prompts.md')) { $promptsName = 'Reality OS Prompts.md'; [void](Add-IfMissing $promptsName 'Prompts.md') }
}
foreach ($f in @('_system\Corrections.md', '_system\ADOPT.md')) { [void](Add-IfMissing $f) }

# The kit's own scripts: add, or refresh to this kit's version.
foreach ($s in @('Test-Vault.ps1', 'Show-Usage.ps1', 'Backup-Vault.ps1', 'Enable-Backup.ps1')) {
    $src = Join-Path $kitVault "_system\$s"; $dst = Join-Path $Path "_system\$s"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    $same = (Test-Path -LiteralPath $dst) -and ((Get-FileHash -LiteralPath $src).Hash -eq (Get-FileHash -LiteralPath $dst).Hash)
    if (-not $same) { Copy-Item -LiteralPath $src -Destination $dst -Force; $added += "_system\$s" }
}

# 4. The map of the vault.
if (-not $existingMap) {
    $daily = $null; $templates = $null
    $dn = Join-Path $Path '.obsidian\daily-notes.json'
    if (Test-Path -LiteralPath $dn) { try { $daily = ([IO.File]::ReadAllText($dn) | ConvertFrom-Json).folder } catch { } }
    $tp = Join-Path $Path '.obsidian\templates.json'
    if (Test-Path -LiteralPath $tp) { try { $templates = ([IO.File]::ReadAllText($tp) | ConvertFrom-Json).folder } catch { } }
    if ($daily -and -not (Test-Path -LiteralPath (Join-Path $Path $daily))) { $daily = $null }
    if ($templates -and -not (Test-Path -LiteralPath (Join-Path $Path $templates))) { $templates = $null }
    $map = [ordered]@{
        mode = 'adopted'; adoption = 'pending'
        home = $null; inbox = $null; openLoops = $null; about = $null
        voice = $voiceName; prompts = $promptsName
        daily = $daily; templates = $templates; folders = @()
    }
    [IO.File]::WriteAllText($mapPath, ((New-Object PSObject -Property $map) | ConvertTo-Json -Depth 4), $enc)
    $added += '_system\vault.json'
}

$changes = @(& git -C $Path status --porcelain 2>$null | Where-Object { $_ })
if ($changes.Count -gt 0) {
    & git -C $Path add -A 2>$null
    & git -C $Path commit -q -m "adopt: add Reality OS files" 2>$null
}

Say ""
if ($added.Count -gt 0) { Say ("Added: " + ($added -join ', ')) } else { Say "Nothing new to add; the vault already has the Reality OS files." }
if ($proposed.Count -gt 0) { Say ("Left yours alone and put the Reality OS version here for the AI to merge with you: " + ($proposed -join ', ')) }
Say ""
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Path '_system\Test-Vault.ps1') -Path $Path | Out-Host
$fails = $LASTEXITCODE
Say ""
if ($fails -ne 0) { Bad "Fix the FAIL lines above before going on."; exit $fails }
Say "Next: open the Claude desktop app, click the Code tab, choose Local, then Open folder... and pick $Path."
Say "Say yes if it asks whether you trust the folder, then type:  Read _system/ADOPT.md and follow it."
exit 0
