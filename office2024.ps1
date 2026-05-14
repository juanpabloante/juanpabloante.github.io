# --- Script de Despliegue Empresarial Office LTSC 2024 ---
# Arquitectura: .NET WebClient / Rutas Absolutas / Fail-Fast

# 1. Validacion de privilegios
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "[X] Error Critico: El script requiere elevacion de privilegios (Administrador)."
    exit
}

# 2. Configuracion de variables absolutas y protocolos seguros
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$TempDir = "C:\OfficeLabSetup2024"
$OdtExe  = "$TempDir\odt_setup.exe"
$XmlFile = "$TempDir\configuration.xml"
$SetupExe= "$TempDir\setup.exe"

$XmlUrl = "https://juanpabloante.github.io/config2024.xml"
$OdtUrl = "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=deploymenttool&language=en-us&platform=x86&version=O16GA"

Write-Host "[*] Iniciando despliegue de alta disponibilidad - Office 2024..." -ForegroundColor Cyan

# 3. Preparacion del entorno aislado
if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force }
New-Item -Path $TempDir -ItemType Directory -Force | Out-Null

# 4. Motor de descarga robusto (.NET Framework)
Write-Host "[*] Descargando binarios desde Microsoft CDN..." -ForegroundColor Yellow
try {
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($OdtUrl, $OdtExe)
} catch {
    Write-Host "[X] Falla critica en la descarga de ODT. Verifica conexion." -ForegroundColor Red
    exit
}

# 5. Desbloqueo de seguridad de Windows (Eliminar Mark of the Web)
Unblock-File -Path $OdtExe

# 6. Extraccion validada
if (Test-Path $OdtExe) {
    Write-Host "[*] Extrayendo herramientas de despliegue..." -ForegroundColor Yellow
    $process = Start-Process -FilePath $OdtExe -ArgumentList "/extract:$TempDir /quiet" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Host "[X] Error interno de extraccion. Exit Code: $($process.ExitCode)" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "[X] El binario ODT no se escribio en el disco." -ForegroundColor Red
    exit
}

# 7. Descarga de matriz de configuracion XML
Write-Host "[*] Obteniendo parametros de instalacion desde GitHub..." -ForegroundColor Yellow
$WebClient.DownloadFile($XmlUrl, $XmlFile)
Unblock-File -Path $XmlFile

# 8. Instalacion silenciosa (Proceso pesado)
if (Test-Path $SetupExe) {
    Write-Host "[*] Instalando motor de Office LTSC 2024. Por favor espere..." -ForegroundColor Cyan
    $installProc = Start-Process -FilePath $SetupExe -ArgumentList "/configure `"$XmlFile`"" -Wait -PassThru
} else {
    Write-Host "[X] Binario maestro (setup.exe) no encontrado. Abortando." -ForegroundColor Red
    exit
}

# 9. Inyeccion de licenciamiento desatendido
Write-Host "[*] Desplegando modulo de activacion (Ohook)..." -ForegroundColor Yellow
try {
    iex "& { $(irm https://get.activated.win) } /ohook"
} catch {
    Write-Host "[!] Advertencia no critica en el modulo de activacion." -ForegroundColor DarkYellow
}

# 10. Limpieza de rastros
Write-Host "[*] Ejecutando recoleccion de basura..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[OK] Infraestructura desplegada exitosamente." -ForegroundColor Green
