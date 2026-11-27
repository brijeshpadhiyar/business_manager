<#
.SYNOPSIS
    Automated Windows (.exe) build & release packaging for StitchFlow.

.DESCRIPTION
    Builds StitchFlow Windows executable for `dev` or `prod` in `release` (default),
    `debug`, or `profile` mode. Refreshes PATH so newly installed tools like `nuget.exe`
    are discovered automatically, clears stale `NUGET_EXE-NOTFOUND` CMake caches,
    copies the full runnable bundle (StitchFlow.exe + DLLs + data/) into
    `build/releases/<flavor>/windows/`, and creates a distributable .zip archive.

.USAGE
    powershell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 dev
    powershell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 prod
    powershell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1 dev debug
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
    Write-Host "StitchFlow Windows (.exe) Build Automation" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Usage:"
    Write-Host "  .\scripts\build_windows.ps1 <flavor> [mode]"
    Write-Host ""
    Write-Host "Flavors (required): dev, prod"
    Write-Host "Modes (optional, default: release): release, debug, profile"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\scripts\build_windows.ps1 dev"
    Write-Host "  .\scripts\build_windows.ps1 prod"
    Write-Host "  .\scripts\build_windows.ps1 dev debug"
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
if ($ModeNorm -notin @("release", "debug", "profile")) {
    Write-Host "[ERROR] Invalid build mode '$Mode'. Supported modes: 'release', 'debug', 'profile'." -ForegroundColor Red
    Show-Usage
    exit 1
}

# Reload PATH from Machine + User registry so newly installed tools (like winget nuget.exe) are visible
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = ($machinePath, $userPath | Where-Object { $_ }) -join ";"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] 'flutter' was not found on PATH. Install Flutter SDK and add it to PATH." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command nuget -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] 'nuget.exe' was not found on PATH (required by flutter_tts on Windows)." -ForegroundColor Red
    Write-Host "Install via: winget install Microsoft.NuGet" -ForegroundColor Yellow
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
        Write-Host "Copy config/$FlavorNorm.example.json to $ConfigFile and fill in your credentials." -ForegroundColor Yellow
        exit 1
    }

    # Clear stale CMakeCache if a prior run cached NUGET_EXE-NOTFOUND
    $cmakeCache = Join-Path $ProjectRoot "build\windows\x64\CMakeCache.txt"
    if ((Test-Path $cmakeCache) -and (Select-String -Path $cmakeCache -Pattern "NUGET_EXE-NOTFOUND" -Quiet)) {
        Write-Host "Clearing stale build\windows CMake cache (NUGET_EXE-NOTFOUND detected)..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force (Join-Path $ProjectRoot "build\windows")
    }

    $ModeFolder = switch ($ModeNorm) {
        "release" { "Release" }
        "debug" { "Debug" }
        "profile" { "Profile" }
    }
    $RunnerDir = Join-Path $ProjectRoot "build\windows\x64\runner\$ModeFolder"
    $ExpectedExe = Join-Path $RunnerDir "StitchFlow.exe"

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " StitchFlow Windows (.exe) Build" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " Flavor     : $FlavorNorm ($FlavorLabel)"
    Write-Host " Build Mode : $ModeNorm"
    Write-Host " Entrypoint : $TargetFile"
    Write-Host " Config     : $ConfigFile"
    Write-Host " NuGet      : $((Get-Command nuget).Source)"
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $buildArgs = @(
        "build", "windows",
        "--$ModeNorm",
        "-t", $TargetFile,
        "--dart-define-from-file=$ConfigFile"
    )
    Write-Host "Running: flutter $($buildArgs -join ' ')" -ForegroundColor Yellow
    & flutter @buildArgs
    $buildExitCode = $LASTEXITCODE
    $stopwatch.Stop()

    if ($buildExitCode -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Windows build failed with exit code $buildExitCode." -ForegroundColor Red
        exit $buildExitCode
    }

    if (-not (Test-Path $ExpectedExe) -or (Get-Item $ExpectedExe).Length -le 0) {
        Write-Host "[ERROR] Expected executable not found or empty: $ExpectedExe" -ForegroundColor Red
        exit 1
    }

    $OutputRoot = Join-Path $ProjectRoot "build\releases\$FlavorNorm\windows"
    if (-not (Test-Path $OutputRoot)) {
        New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null
    }

    $istZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("India Standard Time")
    $istNow = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $istZone)
    $timestamp = $istNow.ToString("yyyyMMdd_HHmmss")
    $modeSuffix = if ($ModeNorm -eq "release") { "" } else { "_$ModeNorm" }
    $bundleName = "StitchFlow_${FlavorLabel}_${timestamp}${modeSuffix}_windows"

    $destDir = Join-Path $OutputRoot $bundleName
    $counter = 1
    while (Test-Path $destDir) {
        $suffix = $counter.ToString("D2")
        $destDir = Join-Path $OutputRoot "${bundleName}_${suffix}"
        $counter++
    }

    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Copy-Item -Path (Join-Path $RunnerDir "*") -Destination $destDir -Recurse -Force

    $zipPath = "$destDir.zip"
    Compress-Archive -Path (Join-Path $destDir "*") -DestinationPath $zipPath -Force

    $destExe = Get-Item (Join-Path $destDir "StitchFlow.exe")
    $zipItem = Get-Item $zipPath
    $durationSec = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
    $zipSizeMb = [Math]::Round($zipItem.Length / 1MB, 2)

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " WINDOWS BUILD SUCCEEDED" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " Flavor         : $FlavorNorm"
    Write-Host " Mode           : $ModeNorm"
    Write-Host " Timestamp (IST): $($istNow.ToString('yyyy-MM-dd HH:mm:ss')) IST"
    Write-Host " Duration       : ${durationSec}s"
    Write-Host " Bundle Folder  : $destDir"
    Write-Host " Executable     : $($destExe.FullName)"
    Write-Host " Portable Zip   : $zipPath (${zipSizeMb} MB)"
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}
finally {
    Pop-Location
}
