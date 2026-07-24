# Build web listo para Firebase Hosting / cualquier static host.
# Uso:
#   .\scripts\build_web.ps1                 # demo (default)
#   .\scripts\build_web.ps1 -DemoMode false # producción Firebase
#   .\scripts\build_web.ps1 -BaseHref /app/

param(
    [ValidateSet("true", "false")]
    [string]$DemoMode = "true",
    [string]$BaseHref = "/"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "🐦 Building Picaflor Web · DEMO_MODE=$DemoMode · base-href=$BaseHref" -ForegroundColor Cyan

flutter pub get
flutter build web `
    --release `
    --dart-define=DEMO_MODE=$DemoMode `
    --base-href $BaseHref

Write-Host ""
Write-Host "✅ Listo: $root\build\web" -ForegroundColor Green
Write-Host "   Deploy: firebase deploy --only hosting"
Write-Host "   Local:  npx serve build/web"
