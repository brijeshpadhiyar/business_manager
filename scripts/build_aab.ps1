<#
.SYNOPSIS
    Automated Android App Bundle (.aab) build & release packaging for StitchFlow.

.DESCRIPTION
    Builds StitchFlow Android App Bundle for Google Play (`prod` or `dev`),
    and copies the timestamped `.aab` to `build/releases/<flavor>/`.

.USAGE
    powershell -ExecutionPolicy Bypass -File .\scripts\build_aab.ps1 prod
    powershell -ExecutionPolicy Bypass -File .\scripts\build_aab.ps1 dev
#>

param(
    [Parameter(Position = 0)]
    [string]$Flavor,

    [Parameter(Position = 1)]
    [string]$Mode = "release"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Show-Usage {
    Write-Host ""
    Write-Host "StitchFlow Android App Bundle (.aab) Build Automation" -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
    Write-Host "Usage:"
    Write-Host "  .\scripts\build_aab.ps1 <flavor> [mode]"
    Write-Host ""
    Write-Host "Flavors (required): dev, prod"
    Write-Host "Modes (optional, default: release): release, debug"
    Write-Host ""
}

if ([string]::IsNullOrWhiteSpace($Flavor)) {
    Write-Host "[ERROR] Missing required <flavor> argument ('dev' or 'prod')." -ForegroundColor Red
    Show-Usage
    exit 1
}

$FlavorNorm = $Flavor.Trim().ToLowerInvariant()
if ($FlavorNorm -notin @("dev", "prod")) {
    Write-Host "[ERROR] Invalid flavor '$Flavor'. Supported flavors: 'dev', 'prod'." -ForegroundColor Red
    Show-Usage
    exit 1
}

$ModeNorm = $Mode.Trim().ToLowerInvariant()
if ($ModeNorm -notin @("release", "debug")) {
    Write-Host "[ERROR] Invalid build mode '$Mode'. Supported modes: 'release', 'debug'." -ForegroundColor Red
    Show-Usage
    exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] 'flutter' was not found on PATH." -ForegroundColor Red
    exit 1
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $ProjectRoot

try {
    $TargetFile = "lib/main_$FlavorNorm.dart"
    $ConfigFile = "config/$FlavorNorm.local.json"
    $FlavorLabel = if ($FlavorNorm -eq "dev") { "Dev" } else { "Prod" }

    if (-not (Test-Path $TargetFile)) {
        Write-Host "[ERROR] Missing entrypoint file: $TargetFile" -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "[ERROR] Missing flavor config file: $ConfigFile" -ForegroundColor Red
        exit 1
    }

    $KeyPropsFile = Join-Path $ProjectRoot "android\key.properties"
    if ($FlavorNorm -eq "prod" -and $ModeNorm -eq "release" -and -not (Test-Path $KeyPropsFile)) {
        Write-Host "[ERROR] Missing android/key.properties for production release signing." -ForegroundColor Red
        Write-Host "Copy android/key.properties.example to android/key.properties and configure your upload keystore." -ForegroundColor Yellow
        exit 1
    }

    $ModePascal = if ($ModeNorm -eq "release") { "Release" } else { "Debug" }
    $ExpectedAab = Join-Path $ProjectRoot "build\app\outputs\bundle\${FlavorNorm}${ModePascal}\app-$FlavorNorm-$ModeNorm.aab"
    if (Test-Path $ExpectedAab) {
        Remove-Item -Force $ExpectedAab
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $buildArgs = @(
        "build", "appbundle",
        "--$ModeNorm",
        "--flavor", $FlavorNorm,
        "-t", $TargetFile,
        "--dart-define-from-file=$ConfigFile"
    )
    Write-Host "Running: flutter $($buildArgs -join ' ')" -ForegroundColor Yellow
    & flutter @buildArgs
    $buildExitCode = $LASTEXITCODE
    $stopwatch.Stop()

    if ($buildExitCode -ne 0) {
        Write-Host "[ERROR] App Bundle build failed with exit code $buildExitCode." -ForegroundColor Red
        exit $buildExitCode
    }

    if (-not (Test-Path $ExpectedAab) -or (Get-Item $ExpectedAab).Length -le 0) {
        Write-Host "[ERROR] Expected AAB not found or empty: $ExpectedAab" -ForegroundColor Red
        exit 1
    }

    $OutputDir = Join-Path $ProjectRoot "build\releases\$FlavorNorm"
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    }

    $istZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("India Standard Time")
    $istNow = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $istZone)
    $timestamp = $istNow.ToString("yyyyMMdd_HHmmss")
    $modeSuffix = if ($ModeNorm -eq "debug") { "_debug" } else { "" }
    $destPath = Join-Path $OutputDir "StitchFlow_${FlavorLabel}_${timestamp}${modeSuffix}.aab"

    Copy-Item -Path $ExpectedAab -Destination $destPath -Force
    $destItem = Get-Item $destPath
    $sizeMb = [Math]::Round($destItem.Length / 1MB, 2)
    $durationSec = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 1)

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " ANDROID AAB BUILD SUCCEEDED" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " Flavor      : $FlavorNorm"
    Write-Host " Mode        : $ModeNorm"
    Write-Host " Duration    : ${durationSec}s"
    Write-Host " Size        : ${sizeMb} MB"
    Write-Host " Output Path : $destPath"
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}
finally {
    Pop-Location
}
