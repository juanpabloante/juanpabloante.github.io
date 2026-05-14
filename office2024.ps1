# --- Motor de Despliegue ProTech (A Prueba de Fallos) ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$TempDir = "C:\OfficeLab2024"
if (!(Test-Path $TempDir)) { New-Item -Path $TempDir -ItemType Directory -Force | Out-Null }
Set-Location $TempDir

$OdtUrl = "https://go.microsoft.com/fwlink/p/?LinkID=626065"
$XmlUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main/config2024.xml"

Write-Host "-> Descargando herramientas de despliegue Microsoft..." -ForegroundColor Cyan
# Usamos curl nativo de Windows con seguimiento de redirecciones y evasión de certificados
curl.exe -s -L -A "Mozilla/5.0" --ssl-no-revoke -o odt.exe $OdtUrl
curl.exe -s -L -A "Mozilla/5.0" --ssl-no-revoke -o config.xml $XmlUrl

# Control de Integridad con Pausa (No cerrará la ventana)
if ((Get-Item "odt.exe").Length -lt 1000000) {
    Write-Host "[X] ERROR: Microsoft bloqueo la descarga (Tamano descargado: $((Get-Item 'odt.exe').Length) bytes)." -ForegroundColor Red
    Read-Host "Presiona Enter para abortar sin cerrar la ventana..."
    return
}

Write-Host "-> Extrayendo instalador base..." -ForegroundColor Yellow
Start-Process -FilePath ".\odt.exe" -ArgumentList "/extract:`"$TempDir`" /quiet" -Wait

if (!(Test-Path "$TempDir\setup.exe")) {
    Write-Host "[X] ERROR: No se logro extraer el motor setup.exe." -ForegroundColor Red
    Read-Host "Presiona Enter para abortar sin cerrar la ventana..."
    return
}

Write-Host "-> Descargando e Instalando Office LTSC 2024 (Esto tomara varios minutos, ten paciencia)..." -ForegroundColor Yellow
Start-Process -FilePath "$TempDir\setup.exe" -ArgumentList "/configure `"config.xml`"" -Wait

Write-Host "-> Inyectando activacion permanente (Ohook)..." -ForegroundColor Yellow
iex "& { $(irm https://get.activated.win) } /ohook"

Write-Host "-> Limpiando entorno..." -ForegroundColor Yellow
Set-Location "C:\"
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "¡Despliegue finalizado al 100%!" -ForegroundColor Green
Read-Host "Presiona Enter para cerrar la consola de forma segura..."
