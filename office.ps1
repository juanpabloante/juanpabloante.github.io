# --- Script de Despliegue Desatendido Office LTSC + MAS ---
# Ejecutar siempre desde PowerShell como Administrador

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Error: Debes ejecutar la consola como Administrador."
    break
}

$TempDir = "C:\OfficeLabSetup"
$XmlUrl = "https://juanpabloante.github.io/configuration.xml"
$OdtUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=deploymenttool&language=en-us&platform=x86&version=O16GA"

Write-Host "Iniciando despliegue automatizado..." -ForegroundColor Cyan

if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force }
New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
Set-Location -Path $TempDir

Write-Host "-> Descargando Office Deployment Tool..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $OdtUrl -OutFile "odt_setup.exe"

Write-Host "-> Extrayendo herramientas..." -ForegroundColor Yellow
Start-Process -FilePath ".\odt_setup.exe" -ArgumentList "/extract:$TempDir /quiet" -Wait

Write-Host "-> Obteniendo configuration.xml desde GitHub..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $XmlUrl -OutFile "configuration.xml"

Write-Host "-> Descargando e instalando Office. Esto tomara algunos minutos..." -ForegroundColor Yellow
Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure configuration.xml" -Wait

Write-Host "-> Validando red e inyectando activacion..." -ForegroundColor Yellow
tnc get.activated.win -port 443 | Out-Null
irm https://get.activated.win | iex

Write-Host "-> Limpiando el entorno y recuperando espacio..." -ForegroundColor Yellow
Set-Location -Path "C:\"
Remove-Item -Path $TempDir -Recurse -Force

Write-Host "¡Despliegue finalizado con exito! Laboratorio listo." -ForegroundColor Green
