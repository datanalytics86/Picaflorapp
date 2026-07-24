# Build APK Android release.
# Requiere Android SDK + (opcional) android/key.properties para firma real.
#
# Uso:
#   .\scripts\build_apk.ps1
#   .\scripts\build_apk.ps1 -DemoMode false

param(
    [ValidateSet("true", "false")]
    [string]$DemoMode = "true"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "🐦 Building Picaflor APK · DEMO_MODE=$DemoMode" -ForegroundColor Cyan

if (-not (Test-Path "android\key.properties")) {
    Write-Host "⚠️  Sin android/key.properties → se firmará con debug (solo pruebas)." -ForegroundColor Yellow
    Write-Host "   Copia android/key.properties.example → android/key.properties"
}

flutter pub get
flutter build apk --release --dart-define=DEMO_MODE=$DemoMode

Write-Host ""
Write-Host "✅ APK: $root\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
