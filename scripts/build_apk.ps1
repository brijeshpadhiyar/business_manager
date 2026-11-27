<#
.SYNOPSIS
    Automated Android APK build & timestamped release packaging for StitchFlow.

.DESCRIPTION
    Builds StitchFlow Android APKs for `dev` or `prod` in `release` (default) or `debug` mode,
    then copies and renames the generated APK into `build/releases/<flavor>/` using an
    Asia/Kolkata (IST) timestamp without ever overwriting previous APKs.

.USAGE
    .\build_apk.bat dev
    .\build_apk.bat prod
    .\build_apk.bat dev debug
    .\build_apk.bat prod debug
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
    Write-Host "StitchFlow APK Build Automation" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "Usage:"
    Write-Host "  .\build_apk.bat <flavor> [mode]"
    Write-Host ""
    Write-Host "Flavors (required):"
    Write-Host "  dev    -> com.brijesh.stitchflow.dev  (StitchFlow Dev)"
    Write-Host "  prod   -> com.brijesh.stitchflow      (StitchFlow)"
    Write-Host ""
    Write-Host "Modes (optional, default: release):"
    Write-Host "  release -> Builds release APK"
    Write-Host "  debug   -> Builds debug APK"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\build_apk.bat dev"
    Write-Host "  .\build_apk.bat prod"
    Write-Host "  .\build_apk.bat dev debug"
    Write-Host "  .\build_apk.bat prod debug"
    Write-Host ""
}

# 1. Validate flavor
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

# 2. Validate mode
$ModeNorm = $Mode.Trim().ToLowerInvariant()
if ($ModeNorm -notin @("release", "debug")) {
    Write-Host "[ERROR] Invalid build mode '$Mode'. Supported modes: 'release', 'debug'." -ForegroundColor Red
    Show-Usage
    exit 1
}

# 3. Verify Flutter availability
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "[ERROR] 'flutter' was not found on PATH. Install Flutter SDK and add it to PATH." -ForegroundColor Red
    exit 1
}

# Resolve project root & flavor parameters
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $ProjectRoot

try {
    $TargetFile = "lib/main_$FlavorNorm.dart"
    $LocalConfigFile = "config/$FlavorNorm.local.json"
    $ConfigFile = $LocalConfigFile
    $FlavorLabel = if ($FlavorNorm -eq "dev") { "Dev" } else { "Prod" }
    $AppId = if ($FlavorNorm -eq "dev") { "com.brijesh.stitchflow.dev" } else { "com.brijesh.stitchflow" }

    if (-not (Test-Path $TargetFile)) {
        Write-Host "[ERROR] Missing entrypoint file: $TargetFile" -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "[ERROR] Missing flavor config file: $ConfigFile" -ForegroundColor Red
        exit 1
    }

    $KeyPropsFile = Join-Path $ProjectRoot "android\key.properties"
    $HasKeyProps = Test-Path $KeyPropsFile
    if ($FlavorNorm -eq "prod" -and $ModeNorm -eq "release" -and -not $HasKeyProps) {
        Write-Host ""
        Write-Host "[ERROR] Missing android/key.properties for production release signing." -ForegroundColor Red
        Write-Host "Copy android/key.properties.example to android/key.properties and configure your local upload keystore." -ForegroundColor Yellow
        Write-Host "See docs/v1.3/RELEASE_CONFIGURATION_IMPLEMENTATION_REPORT.md for keytool setup steps." -ForegroundColor Yellow
        exit 1
    }

    $SigningLabel = if ($ModeNorm -eq "debug") {
        "debug"
    } elseif ($HasKeyProps) {
        "release (android/key.properties)"
    } else {
        "debug (dev fallback - local QA only)"
    }

    $ExpectedSourceApk = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-$FlavorNorm-$ModeNorm.apk"

    # Never risk copying a stale APK from a previous build if this build fails
    if (Test-Path $ExpectedSourceApk) {
        Remove-Item -Force $ExpectedSourceApk
    }

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " StitchFlow Android APK Build" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " Flavor         : $FlavorNorm ($FlavorLabel)"
    Write-Host " Application ID : $AppId"
    Write-Host " Build Mode     : $ModeNorm"
    Write-Host " Signing        : $SigningLabel"
    Write-Host " Entrypoint     : $TargetFile"
    Write-Host " Config         : $ConfigFile"
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # 4. Execute Flutter build
    $buildArgs = @(
        "build", "apk",
        "--$ModeNorm",
        "--flavor", $FlavorNorm,
        "-t", $TargetFile,
        "--dart-define-from-file=$ConfigFile"
    )
    Write-Host "Running: flutter $($buildArgs -join ' ')" -ForegroundColor Yellow
    & flutter @buildArgs
    $buildExitCode = $LASTEXITCODE
    $stopwatch.Stop()

    # 5. Stop immediately if Flutter build failed
    if ($buildExitCode -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Flutter build failed with exit code $buildExitCode. No APK was copied." -ForegroundColor Red
        exit $buildExitCode
    }

    # 6. Verify expected APK exists and is non-empty
    if (-not (Test-Path $ExpectedSourceApk)) {
        Write-Host "[ERROR] Expected APK not found at: $ExpectedSourceApk" -ForegroundColor Red
        exit 1
    }
    $sourceItem = Get-Item $ExpectedSourceApk
    if ($sourceItem.Length -le 0) {
        Write-Host "[ERROR] Generated APK is empty (0 bytes): $ExpectedSourceApk" -ForegroundColor Red
        exit 1
    }

    # 7. Create output folder
    $OutputDir = Join-Path $ProjectRoot "build\releases\$FlavorNorm"
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    }

    # 8. Generate Asia/Kolkata (IST) timestamp
    $istZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("India Standard Time")
    $istNow = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $istZone)
    $timestamp = $istNow.ToString("yyyyMMdd_HHmmss")

    $modeSuffix = if ($ModeNorm -eq "debug") { "_debug" } else { "" }
    $baseName = "StitchFlow_${FlavorLabel}_${timestamp}${modeSuffix}"
    $destPath = Join-Path $OutputDir "$baseName.apk"

    # Safe unique filename guard if two builds complete within the same second
    $counter = 1
    while (Test-Path $destPath) {
        $suffix = $counter.ToString("D2")
        $destPath = Join-Path $OutputDir "${baseName}_${suffix}.apk"
        $counter++
    }

    # 9. Copy and rename APK
    Copy-Item -Path $ExpectedSourceApk -Destination $destPath -Force

    # 10. Verify copied APK exists and is non-empty
    if (-not (Test-Path $destPath)) {
        Write-Host "[ERROR] Failed to copy APK to: $destPath" -ForegroundColor Red
        exit 1
    }
    $destItem = Get-Item $destPath
    if ($destItem.Length -le 0 -or $destItem.Length -ne $sourceItem.Length) {
        Write-Host "[ERROR] Copied APK integrity check failed (size mismatch)." -ForegroundColor Red
        exit 1
    }

    $sizeMb = [Math]::Round($destItem.Length / 1MB, 2)
    $durationSec = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 1)

    # 11. Print final summary
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " BUILD SUCCEEDED" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " Flavor         : $FlavorNorm ($AppId)"
    Write-Host " Mode           : $ModeNorm"
    Write-Host " Timestamp (IST): $($istNow.ToString('yyyy-MM-dd HH:mm:ss')) IST"
    Write-Host " Duration       : ${durationSec}s"
    Write-Host " APK Size       : ${sizeMb} MB ($($destItem.Length) bytes)"
    Write-Host " Output Path    : $destPath"
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}
finally {
    Pop-Location
}
