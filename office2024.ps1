# --- Motor de Despliegue ProTech Solutions v6.0 (Professional Edition) ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$RepoUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main"
$TempDir = "C:\ProTechDeploy"

# 1. Elevación y Seguridad
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "[X] Error: Ejecuta PowerShell como Administrador."
    return
}
Set-MpPreference -DisableRealtimeMonitoring $true

# 2. VERIFICACIÓN DE INSTALACIONES PREVIAS
Write-Host "[*] Verificando rastro de instalaciones previas de Office..." -ForegroundColor Cyan
$ExistingOffice = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*Microsoft Office*" }

if ($ExistingOffice) {
    Write-Host "[!] Se detecto una version previa: $($ExistingOffice.DisplayName)" -ForegroundColor Yellow
    $Confirm = Read-Host "¿Deseas DESINSTALAR la version actual antes de proceder? (S/N)"
    if ($Confirm -eq 'S' -or $Confirm -eq 's') {
        Write-Host "-> Iniciando purga de Office existente..." -ForegroundColor Yellow
        # Descargamos el motor de instalacion para usarlo como desinstalador
        if (!(Test-Path $TempDir)) { New-Item $TempDir -ItemType Directory | Out-Null }
        curl.exe -s -L -o "$TempDir\setup.exe" "$RepoUrl/setup.exe"
        
        $UninstallXml = "<Configuration><Remove All='TRUE'></Remove><Display Level='Full' AcceptEULA='TRUE' /></Configuration>"
        $UninstallXml | Out-File "$TempDir\uninstall.xml" -Encoding ascii
        
        Start-Process -FilePath "$TempDir\setup.exe" -ArgumentList "/configure uninstall.xml" -Wait
        Write-Host "[OK] Proceso de desinstalacion finalizado." -ForegroundColor Green
    }
} else {
    Write-Host "[*] No se detectaron versiones previas. Procediendo con instalacion limpia..." -ForegroundColor Green
}

# 3. PREPARACIÓN DE INSTALACIÓN NUEVA
if (!(Test-Path $TempDir)) { New-Item $TempDir -ItemType Directory | Out-Null }
Set-Location $TempDir

Write-Host "[*] Descargando componentes de Office LTSC 2024..." -ForegroundColor Cyan
curl.exe -s -L -o "setup.exe" "$RepoUrl/setup.exe"

# Creamos un XML Dinámico en el momento para FORZAR la barra de progreso (Display Level Full)
$ConfigXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="PerpetualVL2024">
    <Product ID="ProPlus2024Volume" PIDKEY="2TDPW-NDQ7G-FBYDR-DQG6W-TV6DQ">
      <Language ID="es-es" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1" />
</Configuration>
"@
$ConfigXml | Out-File "$TempDir\config.xml" -Encoding ascii

# 4. EJECUCIÓN CON TELEMETRÍA VISUAL
Write-Host "[*] Iniciando Instalacion. VERAS UNA VENTANA CON EL PROGRESO REAL..." -ForegroundColor Yellow
$process = Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure config.xml" -Wait -PassThru

# 5. ACTIVACIÓN
if ($process.ExitCode -eq 0) {
    Write-Host "[OK] Office instalado. Iniciando activacion permanente..." -ForegroundColor Green
    iex "& { $(irm https://get.activated.win) } /ohook"
    Write-Host "¡TODO EL PROCESO HA FINALIZADO CON EXITO!" -ForegroundColor Green
} else {
    Write-Host "[X] Error en la instalacion. Codigo: $($process.ExitCode)" -ForegroundColor Red
}

Read-Host "Presiona Enter para cerrar el laboratorio..."
