# --- Configuración de Entorno ProTech ---
$RepoUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main"
$TempDir = "C:\ProTechDeploy"

# 1. Crear carpeta temporal limpia
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -Path $TempDir -ItemType Directory | Out-Null
Set-Location $TempDir

Write-Host "-> Descargando motor de instalación desde tu GitHub..." -ForegroundColor Cyan
# Descarga el setup.exe que acabas de subir
Invoke-WebRequest -Uri "$RepoUrl/setup.exe" -OutFile "setup.exe" -UseBasicParsing

Write-Host "-> Obteniendo archivo de configuración XML..." -ForegroundColor Cyan
# Descarga tu configuración de Office 2024
Invoke-WebRequest -Uri "$RepoUrl/config2024.xml" -OutFile "config.xml" -UseBasicParsing

# 2. Validación de descarga
if ((Get-Item "setup.exe").Length -lt 1000000) {
    Write-Host "[X] ERROR: El archivo setup.exe se descargó mal o está incompleto." -ForegroundColor Red
    return
}

Write-Host "-> Iniciando instalación silenciosa de Office LTSC 2024..." -ForegroundColor Yellow
Write-Host "Este proceso descarga ~3GB en segundo plano. No cierres la ventana." -ForegroundColor White

# 3. Ejecutar instalación y esperar a que termine
$proc = Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure config.xml" -Wait -PassThru

if ($proc.ExitCode -eq 0) {
    Write-Host "-> Instalación exitosa. Iniciando activación (Ohook)..." -ForegroundColor Green
    iex "& { $(irm https://get.activated.win) } /ohook"
    Write-Host "¡PROCESO FINALIZADO AL 100%!" -ForegroundColor Green
} else {
    Write-Host "[X] El instalador falló con el código: $($proc.ExitCode)" -ForegroundColor Red
}

# Limpieza opcional
# Set-Location C:\ ; Remove-Item $TempDir -Recurse -Force
