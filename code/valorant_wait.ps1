# valorant_wait.ps1 - wait for the user-facing official installer to finish.
#
# It watches only known E: installation paths and does not automate UAC,
# terms, Vanguard, or reboot actions. If the installer is no longer running,
# it may relaunch the downloaded official installer so the user can continue.
#
# Invoked only by the exact handshake note:
#     monitor-valorant-install-e-drive
#
# ASCII-only for Windows PowerShell 5.1.

param(
    [int]$TimeoutMinutes = 25,
    [int]$IntervalSeconds = 15
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo

$statePath = Join-Path $repo 'results\status\valorant_install.json'
$driveRoot = 'E:\'
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)

function Save-State {
    param(
        [string]$Phase,
        [string]$Message,
        [string]$GamePath = '',
        [string]$InstallerPath = '',
        [string]$Version = ''
    )
    $state = [ordered]@{
        schema = 'valorant-install.v1'
        at = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        host = $env:COMPUTERNAME
        drive = 'E:'
        phase = $Phase
        message = $Message
        version = $Version
        game_path = $GamePath
        installer = $InstallerPath
        target_hint = 'E:\Riot Games'
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $statePath) | Out-Null
    $state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding UTF8
}

$installerPath = ''
$version = ''
try {
    if (Test-Path -LiteralPath $statePath) {
        $old = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $installerPath = [string]$old.installer
        $version = [string]$old.version
    }
} catch { }

$gameCandidates = @(
    (Join-Path $driveRoot 'Riot Games\VALORANT\live\VALORANT.exe'),
    (Join-Path $driveRoot 'Riot Games\VALORANT\live\ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe'),
    (Join-Path $driveRoot 'Games\VALORANT\live\VALORANT.exe'),
    (Join-Path $driveRoot 'VALORANT\live\VALORANT.exe')
)

function Find-GamePath {
    foreach ($p in $gameCandidates) {
        if (Test-Path -LiteralPath $p) {
            try {
                if ((Get-Item -LiteralPath $p).Length -gt 1MB) { return $p }
            } catch { }
        }
    }
    return ''
}

function Test-InstallerProcess {
    $found = $false
    if ($installerPath -and (Test-Path -LiteralPath $installerPath)) {
        try {
            $full = [IO.Path]::GetFullPath($installerPath)
            $same = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
                try { $_.Path -and ([IO.Path]::GetFullPath($_.Path) -ieq $full) } catch { $false }
            })
            if ($same.Count -gt 0) { $found = $true }
        } catch { }
    }
    foreach ($name in @('RiotClientServices', 'RiotClientUx', 'RiotClientUxRender', 'VALORANT')) {
        if (Get-Process -Name $name -ErrorAction SilentlyContinue) { $found = $true }
    }
    return $found
}

if (-not (Test-Path -LiteralPath $driveRoot)) {
    Save-State -Phase 'failed' -Message 'E: drive is not available' -InstallerPath $installerPath -Version $version
    Write-Output '[FAIL] E: drive is not available'
    exit 1
}

Write-Output ('== waiting up to ' + $TimeoutMinutes + ' minute(s) for VALORANT on E:')
Write-Output '== expected game path: E:\Riot Games\VALORANT\live\VALORANT.exe'
$launched = $false
$lastMessageAt = Get-Date

while ((Get-Date) -lt $deadline) {
    $game = Find-GamePath
    if ($game) {
        Save-State -Phase 'installed' -Message 'VALORANT executable detected on E:' -GamePath $game -InstallerPath $installerPath -Version $version
        Write-Output ('== VALORANT installation detected: ' + $game)
        exit 0
    }

    $active = Test-InstallerProcess
    if (-not $active -and -not $launched -and $installerPath -and (Test-Path -LiteralPath $installerPath)) {
        try {
            Write-Output ('== installer is not running; launching: ' + $installerPath)
            Start-Process -FilePath $installerPath -WorkingDirectory (Split-Path -Parent $installerPath) | Out-Null
            $launched = $true
            Save-State -Phase 'waiting-for-user' -Message 'installer relaunched; choose E:\Riot Games and continue locally' -InstallerPath $installerPath -Version $version
            Write-Output '== choose Advanced Options -> E:\Riot Games, approve UAC/Vanguard locally'
        } catch {
            Save-State -Phase 'failed' -Message ('could not relaunch installer: ' + $_.Exception.Message) -InstallerPath $installerPath -Version $version
            Write-Output ('[FAIL] could not relaunch installer: ' + $_.Exception.Message)
            exit 1
        }
    }

    if (((Get-Date) - $lastMessageAt).TotalSeconds -ge 60) {
        $remaining = [math]::Max(0, [math]::Round(($deadline - (Get-Date)).TotalMinutes, 1))
        Write-Output ('   waiting; installer/client active=' + $active + ', remaining_minutes=' + $remaining)
        $lastMessageAt = Get-Date
    }
    Start-Sleep -Seconds $IntervalSeconds
}

Save-State -Phase 'waiting-timeout' -Message 'game executable not detected before the local polling timeout' -InstallerPath $installerPath -Version $version
Write-Output '[FAIL] VALORANT was not detected on E: before the polling timeout'
Write-Output '      finish the installer UI, then request the monitor round again'
exit 1
