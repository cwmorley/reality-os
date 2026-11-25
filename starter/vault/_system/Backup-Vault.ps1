<#
.SYNOPSIS
  Automatic backup for the vault. Run by a scheduled task; safe to run by hand.
.DESCRIPTION
  1. If notes have uncommitted changes and nothing has changed for QuietMinutes,
     commits them as "auto: snapshot". This catches edits made directly in
     Obsidian and anything an app forgot to commit.
  2. If the vault has a backup remote named "origin", pushes to it. It never
     asks for a password: if GitHub needs you to sign in again, it records the
     failure and Test-Vault.ps1 warns you.
  The result is written to .git\realityos-backup.json (not part of your notes).
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File _system\Backup-Vault.ps1
#>
param(
    [string]$Path = (Split-Path -Parent $PSScriptRoot),
    [int]$QuietMinutes = 10
)
$ErrorActionPreference = 'Continue'
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'

$status = [ordered]@{ ran = (Get-Date).ToString('o'); committed = $false; pushed = $false; remote = $false; message = '' }
function Save-Status {
    $file = Join-Path $Path '.git\realityos-backup.json'
    $previous = $null
    if (Test-Path -LiteralPath $file) { try { $previous = [IO.File]::ReadAllText($file) | ConvertFrom-Json } catch { } }
    if ($status.pushed) { $status['lastPush'] = $status.ran }
    elseif ($previous -and $previous.lastPush) { $status['lastPush'] = $previous.lastPush }
    [IO.File]::WriteAllText($file, (New-Object PSObject -Property $status | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { exit 1 }
if (-not (Test-Path -LiteralPath (Join-Path $Path '.git'))) { exit 1 }

# 0. Never back up anything that looks like a password, key or token.
$secretPattern = 'sk-ant-[A-Za-z0-9_-]{20,}|sk-(proj-)?[A-Za-z0-9_-]{32,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----'
$hits = @(Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike (Join-Path $Path '.git\*') -and $_.Length -lt 5MB } |
    Select-String -Pattern $secretPattern -List -ErrorAction SilentlyContinue)
if ($hits.Count -gt 0) {
    $files = ($hits | ForEach-Object { $_.Path.Substring($Path.Length).TrimStart('\') } | Select-Object -Unique) -join ', '
    $status.message = "stopped: something that looks like a key or password is in $files. Remove it, then the backup resumes."
    $status['secret'] = $files
    Save-Status
    exit 0
}

# 1. Snapshot uncommitted changes once the vault has been quiet for a while.
$changes = @(& git -C $Path -c core.quotepath=off status --porcelain --untracked-files=all 2>$null | Where-Object { $_ })
if ($changes.Count -gt 0) {
    $cutoff = (Get-Date).AddMinutes(-$QuietMinutes)
    $recent = @()
    foreach ($line in $changes) {
        $rel = $line.Substring(3)
        if ($rel -like '* -> *') { $rel = $rel.Split(@(' -> '), [StringSplitOptions]::None)[-1] }
        $rel = $rel.Trim('"')
        $file = Join-Path $Path ($rel -replace '/', '\')
        if ((Test-Path -LiteralPath $file -PathType Leaf) -and (Get-Item -LiteralPath $file -Force).LastWriteTime -gt $cutoff) { $recent += $rel }
    }
    if ($recent.Count -eq 0) {
        & git -C $Path add -A 2>$null
        & git -C $Path commit -q -m "auto: snapshot" 2>$null
        if ($LASTEXITCODE -eq 0) { $status.committed = $true }
    } else {
        $status.message = 'changes are recent; snapshot skipped this time'
    }
}

# 2. Push to the backup remote, if there is one.
$url = "$(& git -C $Path remote get-url origin 2>$null)".Trim()
if ($url) {
    $status.remote = $true
    $branch = "$(& git -C $Path rev-parse --abbrev-ref HEAD 2>$null)".Trim()
    $out = (& git -C $Path push -q origin $branch 2>&1 | ForEach-Object { "$_" }) -join ' '
    if ($LASTEXITCODE -eq 0) { $status.pushed = $true }
    else { $status.message = "push failed: $out" }
}

Save-Status
exit 0
