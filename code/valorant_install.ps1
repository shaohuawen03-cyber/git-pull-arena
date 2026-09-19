# valorant_install.ps1 - download and launch the official China installer.
#
# This script deliberately does not attempt to click the installer, bypass UAC,
# accept terms, install Vanguard, or reboot Windows. The official installer
# must be allowed to show its own UI so the user can choose the E: path.
#
# It is invoked only by the exact handshake note:
#     install-valorant-e-drive
#
# ASCII-only for Windows PowerShell 5.1.

param(
    [string]$Drive = 'E:'
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo

$statePath = Join-Path $repo 'results\status\valorant_install.json'

function Save-State {
    param(
        [string]$Phase,
        [string]$Message,
        [string]$InstallerPath = '',
        [string]$Version = '',
        [int]$ProcessId = 0,
        [double]$FreeGb = 0
    )
    $state = [ordered]@{
        schema = 'valorant-install.v1'
        at = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        host = $env:COMPUTERNAME
        drive = $Drive
        phase = $Phase
        message = $Message
        version = $Version
        installer = $InstallerPath
        process_id = $ProcessId
        free_gb = $FreeGb
        target_hint = ($Drive + '\Riot Games')
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $statePath) | Out-Null
    $state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding UTF8
}

function Fail-Task {
    param([string]$Message, [string]$Version = '', [string]$InstallerPath = '', [double]$FreeGb = 0)
    Save-State -Phase 'failed' -Message $Message -InstallerPath $InstallerPath -Version $Version -FreeGb $FreeGb
    Write-Output ('[FAIL] valorant task: ' + $Message)
    exit 1
}

if ($Drive -notmatch '^[A-Za-z]:$') {
    Fail-Task ('invalid drive argument: ' + $Drive)
}

$driveRoot = $Drive.Substring(0, 1).ToUpperInvariant() + ':\'
if (-not (Test-Path -LiteralPath $driveRoot)) {
    Fail-Task ('drive is not available: ' + $driveRoot)
}

$freeGb = 0.0
try {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $Drive) -ErrorAction Stop
    if ($disk -and $disk.FreeSpace) {
        $freeGb = [math]::Round(([double]$disk.FreeSpace / 1GB), 2)
    }
} catch {
    Write-Output ('[WARN] could not read free space for ' + $driveRoot + ': ' + $_.Exception.Message)
}
Write-Output ('== E drive free space: ' + $freeGb + ' GB')

$knownInstalls = @(
    (Join-Path $driveRoot 'Riot Games\VALORANT\live\VALORANT.exe'),
    (Join-Path $driveRoot 'Games\VALORANT\live\VALORANT.exe'),
    (Join-Path $driveRoot 'VALORANT\live\VALORANT.exe')
)
$installed = @($knownInstalls | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
if ($installed.Count -gt 0) {
    Save-State -Phase 'already-installed' -Message ('found existing game: ' + $installed[0]) -InstallerPath '' -FreeGb $freeGb
    Write-Output ('== VALORANT already appears installed: ' + $installed[0])
    exit 0
}

$apiUrl = 'https://api.val.qq.com/go/agame/resource/kv?key=aclos_download_center'
$version = ''
$installerUrl = ''
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $info = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -ErrorAction Stop
    $version = [string]$info.aclos_download_center.verNum
    $installerUrl = [string]$info.aclos_download_center.verUrl
} catch {
    Fail-Task ('official download metadata request failed: ' + $_.Exception.Message) -FreeGb $freeGb
}

if (-not $installerUrl -or $installerUrl -notmatch '^https://down\.val\.qq\.com/') {
    Fail-Task 'official metadata returned an unexpected installer URL' -Version $version -FreeGb $freeGb
}
if (-not $version) { $version = 'current' }

$downloadDir = Join-Path $driveRoot '0github\valorant-installer'
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
$fileName = [IO.Path]::GetFileName(([Uri]$installerUrl).AbsolutePath)
if (-not $fileName -or $fileName -notmatch '\.exe$') {
    Fail-Task 'official metadata did not return an executable installer URL' -Version $version -FreeGb $freeGb
}
$installerPath = Join-Path $downloadDir $fileName
$tmpPath = $installerPath + '.part'

if (-not (Test-Path -LiteralPath $installerPath) -or ((Get-Item -LiteralPath $installerPath).Length -lt 1MB)) {
    if (Test-Path -LiteralPath $tmpPath) {
        Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
    }
    Write-Output ('== downloading official VALORANT CN installer v' + $version)
    Write-Output ('   source: ' + $installerUrl)
    Write-Output ('   file  : ' + $installerPath)
    try {
        $bits = Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue
        if ($bits) {
            Start-BitsTransfer -Source $installerUrl -Destination $tmpPath -DisplayName 'VALORANT CN installer'
        } else {
            Invoke-WebRequest -Uri $installerUrl -UseBasicParsing -OutFile $tmpPath -ErrorAction Stop
        }
        Move-Item -LiteralPath $tmpPath -Destination $installerPath -Force
    } catch {
        Fail-Task ('installer download failed: ' + $_.Exception.Message) -Version $version -InstallerPath $installerPath -FreeGb $freeGb
    }
} else {
    Write-Output ('== official installer already downloaded: ' + $installerPath)
}

$size = (Get-Item -LiteralPath $installerPath).Length
if ($size -lt 1MB) {
    Fail-Task ('downloaded installer is unexpectedly small: ' + $size + ' bytes') -Version $version -InstallerPath $installerPath -FreeGb $freeGb
}

$running = @()
try {
    $fullInstaller = [IO.Path]::GetFullPath($installerPath)
    $running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        try {
            $_.Path -and ([IO.Path]::GetFullPath($_.Path) -ieq $fullInstaller)
        } catch {
            $false
        }
    })
} catch { }
if ($running.Count -gt 0) {
    Save-State -Phase 'installer-running' -Message 'official installer is already running' -InstallerPath $installerPath -Version $version -ProcessId $running[0].Id -FreeGb $freeGb
    Write-Output ('== official installer is already running, pid=' + $running[0].Id)
    exit 0
}

Save-State -Phase 'downloaded' -Message 'official installer downloaded; launching its UI' -InstallerPath $installerPath -Version $version -FreeGb $freeGb
try {
    $proc = Start-Process -FilePath $installerPath -WorkingDirectory $downloadDir -PassThru
} catch {
    Fail-Task ('could not launch installer: ' + $_.Exception.Message) -Version $version -InstallerPath $installerPath -FreeGb $freeGb
}

Save-State -Phase 'installer-launched' -Message 'installer UI launched; choose E:\Riot Games in Advanced Options' -InstallerPath $installerPath -Version $version -ProcessId $proc.Id -FreeGb $freeGb
Write-Output ('== installer launched, pid=' + $proc.Id)
Write-Output '== in the installer UI choose Advanced Options and set the game path to E:\Riot Games'
Write-Output '== accept the Vanguard/UAC prompt locally; do not reboot until the installer asks'
exit 0
