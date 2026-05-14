# --- Motor de Despliegue ProTech Solutions v7.0 (Universal Edition) ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$RepoUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main"
$TempDir = "C:\ProTechDeploy"

# 1. Elevación y Seguridad
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "[X] Error: Ejecuta PowerShell como Administrador."
    return
}
Set-MpPreference -DisableRealtimeMonitoring $true

# 2. SELECCIÓN DE VERSIÓN
Clear-Host
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "     PROTECH SOLUTIONS - MOTOR DE OFFICE       " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "1. Instalar Office LTSC 2024 (Recomendado)"
Write-Host "2. Instalar Office LTSC 2021 (Equipos Antiguos)"
$Opcion = Read-Host "Selecciona una opcion (1-2)"

if ($Opcion -eq "2") {
    $ProdID = "ProPlus2021Volume"; $Channel = "PerpetualVL2021"; $VerName = "2021"
} else {
    $ProdID = "ProPlus2024Volume"; $Channel = "PerpetualVL2024"; $VerName = "2024"
}

# 3. VERIFICACIÓN DE INSTALACIONES PREVIAS
Write-Host "[*] Verificando rastro de Office en el sistema..." -ForegroundColor Cyan
$ExistingOffice = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*Microsoft Office*" }

if ($ExistingOffice) {
    Write-Host "[!] Se detecto: $($ExistingOffice.DisplayName)" -ForegroundColor Yellow
    $Confirm = Read-Host "¿Deseas DESINSTALAR antes de proceder? (S/N)"
    if ($Confirm -eq 'S' -or $Confirm -eq 's') {
        if (!(Test-Path $TempDir)) { New-Item $TempDir -ItemType Directory | Out-Null }
        curl.exe -s -L -o "$TempDir\setup.exe" "$RepoUrl/setup.exe"
        $UninstallXml = "<Configuration><Remove All='TRUE'></Remove><Display Level='Full' AcceptEULA='TRUE' /></Configuration>"
        $UninstallXml | Out-File "$TempDir\uninstall.xml" -Encoding ascii
        Start-Process -FilePath "$TempDir\setup.exe" -ArgumentList "/configure uninstall.xml" -Wait
    }
}

# 4. INSTALACIÓN NUEVA
if (!(Test-Path $TempDir)) { New-Item $TempDir -ItemType Directory | Out-Null }
Set-Location $TempDir
curl.exe -s -L -o "setup.exe" "$RepoUrl/setup.exe"

# Generación dinámica de XML según la versión elegida
$ConfigXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="$Channel">
    <Product ID="$ProdID">
      <Language ID="es-es" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@
$ConfigXml | Out-File "$TempDir\config.xml" -Encoding ascii

Write-Host "[*] Iniciando Instalacion de Office $VerName..." -ForegroundColor Yellow
$process = Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure config.xml" -Wait -PassThru

# 5. ACTIVACIÓN
if ($process.ExitCode -eq 0) {
    Write-Host "[OK] Office $VerName instalado. Activando..." -ForegroundColor Green
    iex "& { $(irm https://get.activated.win) } /ohook"
}

Read-Host "Proceso terminado. Presiona Enter para cerrar."
