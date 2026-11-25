<#
.SYNOPSIS
  Turns on the vault's automatic backup, and optionally connects a private
  GitHub repository so the backup also goes to the cloud.
.DESCRIPTION
  Registers a Windows scheduled task for your user that runs Backup-Vault.ps1
  every hour and when you sign in. No administrator rights needed.
  With -Remote, it also connects the repository and does the first push here,
  so Git can open the GitHub sign-in in your browser once.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File _system\Enable-Backup.ps1
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File _system\Enable-Backup.ps1 -Remote https://github.com/you/my-vault.git
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File _system\Enable-Backup.ps1 -Disable
#>
param(
    [string]$Path = (Split-Path -Parent $PSScriptRoot),
    [string]$Remote,
    [switch]$Disable,
    [string]$TaskName
)
$ErrorActionPreference = 'Continue'
$Path = (Resolve-Path -LiteralPath $Path).ProviderPath
if (-not $TaskName) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $hash = ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Path.ToLowerInvariant())) | Select-Object -First 4 | ForEach-Object { $_.ToString('x2') }) -join ''
    $TaskName = "Reality OS vault backup $hash"
}

if ($Disable) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Automatic backup is off ($TaskName removed). Your notes and their history are unchanged."
    exit 0
}

if ($Remote) {
    $existing = "$(& git -C $Path remote get-url origin 2>$null)".Trim()
    if ($existing -and $existing -ne $Remote) {
        Write-Host "This vault already backs up to $existing. To change it, run: git -C `"$Path`" remote set-url origin $Remote" -ForegroundColor Red
        exit 1
    }
    if (-not $existing) { & git -C $Path remote add origin $Remote }
    $branch = "$(& git -C $Path rev-parse --abbrev-ref HEAD 2>$null)".Trim()
    Write-Host "Sending your vault to $Remote. If a GitHub sign-in opens in your browser, sign in there."
    & git -C $Path push -u origin $branch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "The first push didn't work. Check that the repository exists, is empty and is yours, then run this again." -ForegroundColor Red
        exit 1
    }
    Write-Host "Connected. The vault is now backed up to $Remote."
}

$script = Join-Path $Path '_system\Backup-Vault.ps1'
$psArgs = "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`" -Path `"$Path`""
$conhost = Join-Path $env:SystemRoot 'System32\conhost.exe'
if (Test-Path -LiteralPath $conhost) {
    $action = New-ScheduledTaskAction -Execute $conhost -Argument "--headless powershell.exe $psArgs" -WorkingDirectory $Path
} else {
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $psArgs -WorkingDirectory $Path
}
$hourly = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Hours 1)
$logon = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger @($hourly, $logon) -Settings $settings -Principal $principal `
        -Description "Saves and backs up the Reality OS vault at $Path every hour. Remove with Enable-Backup.ps1 -Disable." -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Host "Couldn't create the scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host "Automatic backup is on: every hour and when you sign in, as the task '$TaskName'."
if (-not "$(& git -C $Path remote get-url origin 2>$null)".Trim()) {
    Write-Host "It saves snapshots on this computer. To also back up to the cloud, see 'Back it up to the cloud' in the kit's README."
}
exit 0
