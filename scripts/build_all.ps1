<#
.SYNOPSIS
    One-command multi-platform build runner on Windows for StitchFlow.

.DESCRIPTION
    Builds all platforms supported natively on Windows (`apk`, `windows`, `web`, and
    optionally `aab`) for the chosen flavour (`dev` or `prod`).
    macOS/iOS (`build_ios.sh`, `build_macos.sh`) and Linux (`build_linux.sh`) must be
    run on their native OS hosts.

.USAGE
    powershell -ExecutionPolicy Bypass -File .\scripts\build_all.ps1 dev
    powershell -ExecutionPolicy Bypass -File .\scripts\build_all.ps1 prod
    powershell -ExecutionPolicy Bypass -File .\scripts\build_all.ps1 dev -Targets apk,windows,web
    powershell -ExecutionPolicy Bypass -File .\scripts\build_all.ps1 prod -Targets apk,aab,windows,web -SkipChecks
#>

param(
    [Parameter(Position = 0)]
    [string]$Flavor,

    [Parameter()]
    [ValidateSet("release", "debug")]
    [string]$Mode = "release",

    [Parameter()]
    [string[]]$Targets = @(),

    [Parameter()]
    [switch]$SkipChecks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Flavor)) {
    Write-Host "Usage: .\scripts\build_all.ps1 <dev|prod> [-Mode release|debug] [-Targets apk,aab,windows,web] [-SkipChecks]" -ForegroundColor Cyan
    exit 1
}

$FlavorNorm = $Flavor.Trim().ToLowerInvariant()
if ($FlavorNorm -notin @("dev", "prod")) {
    Write-Host "[ERROR] Invalid flavor '$Flavor'. Use 'dev' or 'prod'." -ForegroundColor Red
    exit 1
}

if ($Targets.Count -eq 0) {
    $Targets = if ($FlavorNorm -eq "prod" -and $Mode -eq "release") {
        @("apk", "aab", "windows", "web")
    } else {
        @("apk", "windows", "web")
    }
} else {
    # Handle comma-separated string passed from batch/CLI
    $Targets = $Targets | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ }
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $ProjectRoot

try {
    if (-not $SkipChecks) {
        Write-Host "Running pre-build checks (flutter pub get, gen-l10n, analyze)..." -ForegroundColor Cyan
        & flutter pub get; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        & flutter gen-l10n; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        & flutter analyze --fatal-infos; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    $results = @()

    foreach ($target in $Targets) {
        switch ($target) {
            "apk" {
                & "$PSScriptRoot\build_apk.ps1" -Flavor $FlavorNorm -Mode $Mode
                if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                $results += "Android APK ($FlavorNorm/$Mode)"
            }
            "aab" {
                & "$PSScriptRoot\build_aab.ps1" -Flavor $FlavorNorm -Mode $Mode
                if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                $results += "Android AAB ($FlavorNorm/$Mode)"
            }
            "windows" {
                & "$PSScriptRoot\build_windows.ps1" -Flavor $FlavorNorm -Mode $Mode
                if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                $results += "Windows EXE ($FlavorNorm/$Mode)"
            }
            "web" {
                $webMode = if ($Mode -eq "debug") { "profile" } else { "release" }
                & "$PSScriptRoot\build_web.ps1" -Flavor $FlavorNorm -Mode $webMode
                if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                $results += "Web ($FlavorNorm/$webMode)"
            }
            "ios" {
                Write-Host "[SKIP] iOS builds require a macOS host with Xcode. Run scripts/build_ios.sh on macOS." -ForegroundColor Yellow
            }
            "macos" {
                Write-Host "[SKIP] macOS builds require a macOS host with Xcode. Run scripts/build_macos.sh on macOS." -ForegroundColor Yellow
            }
            "linux" {
                Write-Host "[SKIP] Linux builds require a Linux host. Run scripts/build_linux.sh on Linux." -ForegroundColor Yellow
            }
            default {
                Write-Host "[ERROR] Unknown target '$target'. Valid: apk, aab, windows, web, ios, macos, linux." -ForegroundColor Red
                exit 1
            }
        }
    }

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " ALL SELECTED BUILDS SUCCEEDED ($FlavorNorm)" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    foreach ($item in $results) {
        Write-Host "  [OK] $item" -ForegroundColor Green
    }
    Write-Host " Outputs saved under: $ProjectRoot\build\releases\$FlavorNorm\" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    exit 0
}
finally {
    Pop-Location
}
