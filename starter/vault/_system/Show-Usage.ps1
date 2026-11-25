<#
.SYNOPSIS
  Shows how often the vault was used, from the Git history.
.DESCRIPTION
  Counts the days with at least one commit in the last N days, and commits by
  app (messages starting with "claude:" or "chatgpt:"). The starter's target
  is use on at least 10 of the first 14 days.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File _system\Show-Usage.ps1 -Days 14
#>
param(
    [string]$Path = (Split-Path -Parent $PSScriptRoot),
    [int]$Days = 14
)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Run: winget install --id Git.Git -e"
    exit 1
}

$since = (Get-Date).Date.AddDays(1 - $Days).ToString('yyyy-MM-dd')
$log = @(& git -C $Path log --since="$since 00:00" --date=short --format='%ad|%s' 2>$null | Where-Object { $_ })
if ($LASTEXITCODE -ne 0) {
    Write-Host "This folder is not a Git repository."
    exit 1
}

$activeDays = @{}
$auto = 0
$claude = 0
$chatgpt = 0
$other = 0
foreach ($entry in $log) {
    $parts = $entry.Split('|', 2)
    $msg = $parts[1].Trim().ToLowerInvariant()
    if ($msg.StartsWith('auto:')) { $auto++; continue }
    $activeDays[$parts[0]] = $true
    if ($msg.StartsWith('claude:')) { $claude++ }
    elseif ($msg.StartsWith('chatgpt:')) { $chatgpt++ }
    else { $other++ }
}

Write-Host "Last $Days days (since $since):"
Write-Host ("  Days with at least one change: {0} of {1}" -f $activeDays.Count, $Days)
Write-Host ("  Changes by Claude: {0}   by ChatGPT: {1}   other: {2}" -f $claude, $chatgpt, $other)
Write-Host ("  Automatic backup snapshots (not counted as use): {0}" -f $auto)
if ($Days -eq 14) {
    if ($activeDays.Count -ge 10) { Write-Host "  On target (10 of 14 days)." }
    else { Write-Host "  Below the 10-of-14 target. Look at what got in the way before adding anything new." }
}
exit 0
