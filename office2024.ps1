# --- Script de Despliegue Desatendido Office LTSC 2024 + MAS ---
# Ejecutar siempre desde PowerShell como Administrador

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Error: Debes ejecutar la consola como Administrador."
    break
}

# FIX CRÍTICO: Forzar TLS 1.2 para evitar que Microsoft entregue un archivo corrupto
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$TempDir = "C:\OfficeLabSetup2024"
$XmlUrl = "https://juanpabloante.github.io/config2024.xml"
$OdtUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=deploymenttool&language=en-us&platform=x86&version=O16GA"

Write-Host "Iniciando despliegue automatizado de Office 2024..." -ForegroundColor Cyan

if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force }
New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
Set-Location -Path $TempDir

Write-Host "-> Descargando Office Deployment Tool..." -ForegroundColor Yellow
# FIX CRÍTICO: Añadir -UseBasicParsing para evitar bloqueos internos del motor web
Invoke-WebRequest -Uri $OdtUrl -OutFile "odt_setup.exe" -UseBasicParsing

Write-Host "-> Extrayendo herramientas..." -ForegroundColor Yellow
Start-Process -FilePath ".\odt_setup.exe" -ArgumentList "/extract:$TempDir /quiet" -Wait

Write-Host "-> Obteniendo config2024.xml desde GitHub..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $XmlUrl -OutFile "configuration.xml" -UseBasicParsing

Write-Host "-> Descargando e instalando Office LTSC 2024. Esto tomara algunos minutos..." -ForegroundColor Yellow
Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure configuration.xml" -Wait

Write-Host "-> Validando red e inyectando activacion permanente silenciosa..." -ForegroundColor Yellow
tnc get.activated.win -port 443 | Out-Null
# FIX CRÍTICO: Modo totalmente desatendido para Office (Ohook)
iex "& { $(irm https://get.activated.win) } /ohook"

Write-Host "-> Limpiando el entorno y recuperando espacio..." -ForegroundColor Yellow
Set-Location -Path "C:\"
Remove-Item -Path $TempDir -Recurse -Force

Write-Host "¡Despliegue de Office 2024 finalizado con exito!" -ForegroundColor Green
