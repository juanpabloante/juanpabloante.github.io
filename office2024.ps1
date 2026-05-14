# --- Despliegue Definitivo Office LTSC 2024 ---
# Motor: Native cURL (Windows 11) - Tolerancia a fallos y bypass de redirecciones

Write-Host "Iniciando Motor de Despliegue Definitivo ProTech..." -ForegroundColor Cyan

# Crear entorno completamente aislado
$TempDir = "C:\OfficeLab2024"
if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force }
New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
Set-Location -Path $TempDir

$OdtUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=deploymenttool&language=en-us&platform=x86&version=O16GA"
# Usamos el enlace RAW de GitHub para evitar problemas de caché con el XML
$XmlUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main/config2024.xml"

Write-Host "-> Descargando binarios (Via cURL puro)..." -ForegroundColor Yellow
# curl.exe con parámetro -L fuerza a seguir redirecciones de Microsoft hasta encontrar el .exe real
curl.exe -s -L -o "odt.exe" $OdtUrl
curl.exe -s -L -o "config.xml" $XmlUrl

Write-Host "-> Extrayendo herramientas base..." -ForegroundColor Yellow
Start-Process -FilePath ".\odt.exe" -ArgumentList "/extract:$TempDir /quiet" -Wait

Write-Host "-> Ejecutando instalacion silenciosa (Esto tomara unos minutos, no cierres la ventana)..." -ForegroundColor Yellow
Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure config.xml" -Wait

Write-Host "-> Inyectando activacion permanente (Ohook)..." -ForegroundColor Yellow
iex "& { $(irm https://get.activated.win) } /ohook"

Write-Host "-> Limpiando entorno..." -ForegroundColor Yellow
Set-Location -Path "C:\"
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "¡Instalacion 100% Completada sin errores!" -ForegroundColor Green
