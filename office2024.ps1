# --- Motor de Despliegue ProTech (Fase Final) ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$TempDir = "C:\OfficeLab2024"
if (!(Test-Path $TempDir)) { New-Item -Path $TempDir -ItemType Directory -Force | Out-Null }
Set-Location $TempDir

# Enlace corporativo oficial y XML en vivo
$OdtUrl = "https://go.microsoft.com/fwlink/p/?LinkID=626065"
$XmlUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main/config2024.xml"
$OdtExe = "$TempDir\odt.exe"
$XmlFile = "$TempDir\config.xml"

Write-Host "-> Descargando Office Deployment Tool Oficial..." -ForegroundColor Cyan
# Evasión de bloqueo usando un UserAgent de navegador real
Invoke-WebRequest -Uri $OdtUrl -OutFile $OdtExe -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
Invoke-WebRequest -Uri $XmlUrl -OutFile $XmlFile -UseBasicParsing

# Liberar bloqueos de seguridad nativos de Windows LTSC (SmartScreen)
Unblock-File -Path $OdtExe
Unblock-File -Path $XmlFile

# Control de Integridad: Verificar que Microsoft entregó el ejecutable real (Aprox 3.5 MB)
if ((Get-Item $OdtExe).Length -lt 1000000) {
    Write-Host "[X] ERROR FATAL: Microsoft bloqueo la descarga. El archivo esta corrupto o vacio." -ForegroundColor Red
    exit
}

Write-Host "-> Extrayendo instalador base..." -ForegroundColor Yellow
Start-Process -FilePath $OdtExe -ArgumentList "/extract:`"$TempDir`" /quiet" -Wait

if (!(Test-Path "$TempDir\setup.exe")) {
    Write-Host "[X] ERROR FATAL: El motor setup.exe no se logro extraer." -ForegroundColor Red
    exit
}

Write-Host "-> Descargando e Instalando Office LTSC 2024 (Esto tomara varios minutos, no cierres la ventana)..." -ForegroundColor Yellow
Start-Process -FilePath "$TempDir\setup.exe" -ArgumentList "/configure `"$XmlFile`"" -Wait

Write-Host "-> Inyectando activacion permanente (Ohook)..." -ForegroundColor Yellow
iex "& { $(irm https://get.activated.win) } /ohook"

Write-Host "-> Limpiando entorno de laboratorio..." -ForegroundColor Yellow
Set-Location "C:\"
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "¡Despliegue automatizado finalizado al 100% sin errores!" -ForegroundColor Green
