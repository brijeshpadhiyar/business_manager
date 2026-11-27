<#
.SYNOPSIS
    Automated Flutter Web build & archive packaging for StitchFlow.

.DESCRIPTION
    Builds StitchFlow Web output for `dev` or `prod` in `release` (default) or `profile` mode,
    then copies the built `build/web` directory and creates a timestamped `.zip` archive inside
    `build/releases/<flavor>/web/`.

.USAGE
    powershell -ExecutionPolicy Bypass -File .\scripts\build_web.ps1 dev
    powershell -ExecutionPolicy Bypass -File .\scripts\build_web.ps1 prod
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
    Write-Host "StitchFlow Web Build Automation" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "Usage:"
    Write-Host "  .\scripts\build_web.ps1 <flavor> [mode]"
    Write-Host ""
    Write-Host "Flavors (required): dev, prod"
    Write-Host "Modes (optional, default: release): release, profile"
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
if ($ModeNorm -notin @("release", "profile")) {
    Write-Host "[ERROR] Invalid Web build mode '$Mode'. Supported modes: 'release', 'profile'." -ForegroundColor Red
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

    $WebOutDir = Join-Path $ProjectRoot "build\web"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $buildArgs = @(
        "build", "web",
        "--$ModeNorm",
        "-t", $TargetFile,
        "--dart-define-from-file=$ConfigFile"
    )
    Write-Host "Running: flutter $($buildArgs -join ' ')" -ForegroundColor Yellow
    & flutter @buildArgs
    $buildExitCode = $LASTEXITCODE
    $stopwatch.Stop()

    if ($buildExitCode -ne 0) {
        Write-Host "[ERROR] Web build failed with exit code $buildExitCode." -ForegroundColor Red
        exit $buildExitCode
    }

    $indexFile = Join-Path $WebOutDir "index.html"
    if (-not (Test-Path $indexFile)) {
        Write-Host "[ERROR] Expected Web entrypoint not found: $indexFile" -ForegroundColor Red
        exit 1
    }

    $OutputRoot = Join-Path $ProjectRoot "build\releases\$FlavorNorm\web"
    if (-not (Test-Path $OutputRoot)) {
        New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
    }

    $istZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("India Standard Time")
    $istNow = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $istZone)
    $timestamp = $istNow.ToString("yyyyMMdd_HHmmss")
    $modeSuffix = if ($ModeNorm -eq "release") { "" } else { "_$ModeNorm" }
    $bundleName = "StitchFlow_${FlavorLabel}_${timestamp}${modeSuffix}_web"

    $destDir = Join-Path $OutputRoot $bundleName
    $counter = 1
    while (Test-Path $destDir) {
        $suffix = $counter.ToString("D2")
        $destDir = Join-Path $OutputRoot "${bundleName}_${suffix}"
        $counter++
    }

    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Copy-Item -Path (Join-Path $WebOutDir "*") -Destination $destDir -Recurse -Force

    $zipPath = "$destDir.zip"
    Compress-Archive -Path (Join-Path $destDir "*") -DestinationPath $zipPath -Force

    $zipSizeMb = [Math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    $durationSec = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 1)

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " WEB BUILD SUCCEEDED" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " Flavor        : $FlavorNorm"
    Write-Host " Mode          : $ModeNorm"
    Write-Host " Duration      : ${durationSec}s"
    Write-Host " Web Folder    : $destDir"
    Write-Host " Zip Archive   : $zipPath (${zipSizeMb} MB)"
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}
finally {
    Pop-Location
}
