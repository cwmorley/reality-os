<#
.SYNOPSIS
  One-step installer for the Reality OS starter on Windows.
.DESCRIPTION
  Installs Git, Obsidian, the Claude desktop app and the ChatGPT desktop app
  with winget (skipping any already installed), downloads the kit to
  C:\Users\<you>\RealityOS-kit, creates the vault at C:\Users\<you>\Vault,
  turns on an hourly automatic backup (a scheduled task for your user),
  and adds the vault to Obsidian. Safe to run again: it never overwrites an
  existing vault and never adds the vault to Obsidian twice.

  Run it by pasting this into PowerShell:
    irm https://raw.githubusercontent.com/cwmorley/reality-os/main/starter/install.ps1 | iex

  To add Reality OS to a vault you already have (alpha), set the folder first:
    $env:REALITYOS_ADOPT = "C:\Users\you\Documents\My Vault"; irm https://raw.githubusercontent.com/cwmorley/reality-os/main/starter/install.ps1 | iex

  Read it first if you like:
    https://github.com/cwmorley/reality-os/blob/main/starter/install.ps1
#>

function Write-Step([string]$m) { Write-Host ""; Write-Host "== $m" -ForegroundColor Cyan }
function Write-Ok([string]$m) { Write-Host "   ok    $m" }
function Write-Note([string]$m) { Write-Host "   note  $m" -ForegroundColor Yellow }
function Write-Bad([string]$m) { Write-Host "   FAIL  $m" -ForegroundColor Red }

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Register-ObsidianVault([string]$VaultPath) {
    $dir = Join-Path $env:APPDATA 'obsidian'
    $file = Join-Path $dir 'obsidian.json'
    if (Get-Process -Name 'Obsidian' -ErrorAction SilentlyContinue) {
        Write-Note "Obsidian is open, so the vault wasn't added automatically. In Obsidian choose Open folder as vault and pick $VaultPath."
        return
    }
    $data = $null
    if (Test-Path -LiteralPath $file) {
        try { $data = [IO.File]::ReadAllText($file) | ConvertFrom-Json } catch { $data = $null }
        if (-not $data) {
            Write-Note "Couldn't read Obsidian's settings, so the vault wasn't added. In Obsidian choose Open folder as vault and pick $VaultPath."
            return
        }
        Copy-Item -LiteralPath $file -Destination "$file.bak-realityos" -Force
    } else {
        $data = New-Object PSObject
    }
    if (-not ($data.PSObject.Properties.Name -contains 'vaults') -or -not $data.vaults) {
        $data | Add-Member -NotePropertyName 'vaults' -NotePropertyValue (New-Object PSObject) -Force
    }
    $existing = @($data.vaults.PSObject.Properties)
    foreach ($p in $existing) {
        if ("$($p.Value.path)".TrimEnd('\') -ieq $VaultPath.TrimEnd('\')) { Write-Ok "the vault is already in Obsidian"; return }
    }
    $id = -join (1..16 | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
    $entry = New-Object PSObject
    $entry | Add-Member -NotePropertyName 'path' -NotePropertyValue $VaultPath
    $entry | Add-Member -NotePropertyName 'ts' -NotePropertyValue ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    $entry | Add-Member -NotePropertyName 'open' -NotePropertyValue ($existing.Count -eq 0)
    $data.vaults | Add-Member -NotePropertyName $id -NotePropertyValue $entry
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    [IO.File]::WriteAllText($file, ($data | ConvertTo-Json -Depth 8), (New-Object System.Text.UTF8Encoding($false)))
    if ($existing.Count -eq 0) { Write-Ok "added the vault to Obsidian; it opens there the first time you start Obsidian" }
    else { Write-Ok "added the vault to Obsidian's vault list (choose it from the vault switcher)" }
}

function Install-RealityOS {
    param(
        [string]$VaultPath = (Join-Path $HOME 'Vault'),
        [string]$KitPath = (Join-Path $HOME 'RealityOS-kit'),
        [string]$Repo = 'https://github.com/cwmorley/reality-os',
        [string]$LocalKit,
        [switch]$SkipApps,
        [switch]$NoChatGPT,
        [switch]$NoBackupTask,
        [string]$Adopt = $env:REALITYOS_ADOPT,
        [string]$Name,
        [string]$Email
    )
    $ErrorActionPreference = 'Continue'
    Write-Host "Reality OS starter installer"

    # 1. Apps
    $apps = @(
        @{ Id = 'Git.Git'; Source = 'winget'; Name = 'Git' },
        @{ Id = 'Obsidian.Obsidian'; Source = 'winget'; Name = 'Obsidian' },
        @{ Id = 'Anthropic.Claude'; Source = 'winget'; Name = 'Claude desktop app' },
        @{ Id = '9PLM9XGG6VKS'; Source = 'msstore'; Name = 'ChatGPT desktop app' }
    )
    if ($NoChatGPT) { $apps = @($apps | Where-Object { $_.Id -ne '9PLM9XGG6VKS' }) }
    if (-not $SkipApps) {
        Write-Step "Installing apps (any you already have are skipped)"
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Bad "winget isn't available. Install App Installer from the Microsoft Store, then run this again."
            return $false
        }
        Write-Host "   Windows may ask whether to let an installer make changes. Say yes."
        foreach ($a in $apps) {
            & winget list --id $a.Id -e --accept-source-agreements --disable-interactivity *> $null
            if ($LASTEXITCODE -eq 0) { Write-Ok "$($a.Name) is already installed"; continue }
            Write-Host "   ...   installing $($a.Name)"
            & winget install --id $a.Id -e --source $a.Source --accept-source-agreements --accept-package-agreements --disable-interactivity *> $null
            if ($LASTEXITCODE -eq 0) { Write-Ok "$($a.Name) installed" }
            else { Write-Note "$($a.Name) didn't install (winget code $LASTEXITCODE). Install it by hand afterwards; everything else carries on." }
        }
        Update-SessionPath
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Bad "Git isn't available. Run: winget install --id Git.Git -e --source winget   then open a new PowerShell window and run this installer again."
        return $false
    }

    # 2. Kit
    Write-Step "Getting the kit"
    if ($LocalKit) {
        $kit = $LocalKit
        Write-Ok "using the kit at $kit"
    } else {
        $kit = $KitPath
        if (Test-Path -LiteralPath (Join-Path $kit '.git')) {
            & git -C $kit pull -q --ff-only 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Ok "updated the kit at $kit" } else { Write-Note "couldn't update $kit; using it as it is" }
        } elseif ((Test-Path -LiteralPath $kit) -and @(Get-ChildItem -LiteralPath $kit -Force).Count -gt 0) {
            Write-Bad "$kit exists and isn't the kit. Move it, or run with a different -KitPath."
            return $false
        } else {
            & git clone -q --depth 1 $Repo $kit 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) { Write-Bad "couldn't download the kit from $Repo. Check the internet connection and run this again."; return $false }
            Write-Ok "downloaded the kit to $kit"
        }
    }
    $newVault = Join-Path $kit 'starter\tools\New-Vault.ps1'
    if (-not (Test-Path -LiteralPath $newVault)) { Write-Bad "the kit at $kit is incomplete (no starter\tools\New-Vault.ps1)."; return $false }

    # 3. Vault
    if ($Adopt) {
        Write-Step "Adopting your existing vault (alpha)"
        $VaultPath = (Resolve-Path -LiteralPath $Adopt -ErrorAction SilentlyContinue).ProviderPath
        if (-not $VaultPath) { Write-Bad "$Adopt doesn't exist."; return $false }
        $adoptArgs = @('-Path', $VaultPath)
        if ($Name) { $adoptArgs += @('-Name', $Name) }
        if ($Email) { $adoptArgs += @('-Email', $Email) }
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $kit 'starter\tools\Adopt-Vault.ps1') @adoptArgs | Out-Host
        if ($LASTEXITCODE -ne 0) { Write-Bad "the vault wasn't adopted; see the messages above. Nothing in your notes was changed."; return $false }
    } else {
    Write-Step "Making your vault"
    if (Test-Path -LiteralPath (Join-Path $VaultPath 'AGENTS.md')) {
        Write-Ok "a vault already exists at $VaultPath; leaving it as it is"
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $VaultPath '_system\Test-Vault.ps1') -Path $VaultPath | Out-Host
    } else {
        $vaultArgs = @('-Path', $VaultPath)
        if ($Name) { $vaultArgs += @('-Name', $Name) }
        if ($Email) { $vaultArgs += @('-Email', $Email) }
        & powershell -NoProfile -ExecutionPolicy Bypass -File $newVault @vaultArgs | Out-Host
        if ($LASTEXITCODE -ne 0) { Write-Bad "the vault wasn't created; see the messages above."; return $false }
    }
    }

    # 4. Automatic backup
    if (-not $NoBackupTask) {
        Write-Step "Turning on automatic backup"
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $VaultPath '_system\Enable-Backup.ps1') -Path $VaultPath | Out-Host
    }

    # 5. Obsidian
    Write-Step "Adding the vault to Obsidian"
    Register-ObsidianVault -VaultPath $VaultPath

    # 6. Next steps
    Write-Step "Done. Next:"
    Write-Host "   1. Open the Claude app, sign in, and click the Code tab. Choose Local, then Open folder..., and pick $VaultPath."
    $first = 'Read _system/SETUP.md and follow it.'
    if ($Adopt) { $first = 'Read _system/ADOPT.md and follow it.' }
    Write-Host "      If it asks whether you trust the folder, say yes. Then type:  $first"
    Write-Host "   2. Afterwards, open Obsidian. Your vault is there; Home is the front page."
    if (-not $NoChatGPT) { Write-Host "   3. Open the ChatGPT app, sign in, press Ctrl+O and pick $VaultPath (the README has the first prompt)." }
    return $true
}

if (-not $env:REALITYOS_NO_AUTORUN) { [void](Install-RealityOS) }
