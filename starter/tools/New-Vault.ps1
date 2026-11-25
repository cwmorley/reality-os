<#
.SYNOPSIS
  Creates a new Reality OS starter vault from this kit.
.DESCRIPTION
  Copies starter\vault to a new folder (default: C:\Users\<you>\Vault), starts a
  Git repository there, makes the first commit, and runs Test-Vault.ps1.
  It never overwrites an existing folder that has files in it.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\RealityOS-kit\starter\tools\New-Vault.ps1"
#>
param(
    [string]$Path = (Join-Path $HOME 'Vault'),
    [string]$Name,
    [string]$Email
)

$source = Join-Path (Split-Path -Parent $PSScriptRoot) 'vault'
if (-not (Test-Path -LiteralPath (Join-Path $source 'AGENTS.md'))) {
    Write-Host "Can't find the starter vault next to this script ($source). Run this from inside the downloaded kit." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Run:  winget install --id Git.Git -e" -ForegroundColor Red
    Write-Host "Then close this window, open a new PowerShell window, and run this script again."
    exit 1
}

if (Test-Path -LiteralPath $Path) {
    $existing = @(Get-ChildItem -LiteralPath $Path -Force)
    if ($existing.Count -gt 0) {
        Write-Host "$Path already exists and has files in it. Nothing was changed." -ForegroundColor Red
        Write-Host "Pick another folder:  ...New-Vault.ps1 -Path C:\Users\<you>\Vault2"
        exit 1
    }
    Get-ChildItem -LiteralPath $source -Force | Copy-Item -Destination $Path -Recurse -Force
} else {
    Copy-Item -LiteralPath $source -Destination $Path -Recurse -Force
}
Write-Host "Created $Path"

& git -C $Path init -q 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "git init failed in $Path" -ForegroundColor Red; exit 1 }
& git -C $Path symbolic-ref HEAD refs/heads/main 2>$null

# Use the global Git identity if there is one; otherwise ask once and set it for this vault only.
$globalName = "$(& git config --global user.name 2>$null)".Trim()
$globalMail = "$(& git config --global user.email 2>$null)".Trim()
if (-not $Name) { $Name = $globalName }
if (-not $Email) { $Email = $globalMail }
$canAsk = -not [Console]::IsInputRedirected
if (-not $Name -and $canAsk) { $Name = Read-Host "Your name (used to label your own changes in the vault's history)" }
if (-not $Email -and $canAsk) { $Email = Read-Host "Your email (stays on this computer; Git just needs one)" }
if (-not $Name -or -not $Email) { Write-Host "No name or email given; using placeholders. Change them later with git config in the vault." }
if (-not $Name) { $Name = 'Vault owner' }
if (-not $Email) { $Email = 'owner@localhost' }
if ($Name -ne $globalName) { & git -C $Path config user.name $Name }
if ($Email -ne $globalMail) { & git -C $Path config user.email $Email }

& git -C $Path add -A
& git -C $Path commit -q -m "setup: starter vault"
if ($LASTEXITCODE -ne 0) { Write-Host "The first commit failed. Run Test-Vault.ps1 to see why." -ForegroundColor Red; exit 1 }

Write-Host ""
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Path '_system\Test-Vault.ps1') -Path $Path
$fails = $LASTEXITCODE
Write-Host ""
if ($fails -ne 0) { Write-Host "Fix the FAIL lines above before going on." -ForegroundColor Red; exit $fails }

Write-Host "Next: open the Claude desktop app, click the Code tab, choose Select folder, pick $Path,"
Write-Host "leave the permission mode on Ask, and type:  Read _system/SETUP.md and follow it."
exit 0
