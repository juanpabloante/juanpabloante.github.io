# --- Motor de Despliegue Universal ProTech Solutions v7.3 ---
# Identidad: ProTech Solutions S.A.S | Autor: Ing. Juan Pablo Ante

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$RepoUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main"
$TempDir = "C:\ProTechDeploy"

# 1. Seguridad Inicial
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "[X] ERROR: Ejecuta PowerShell como Administrador."
    exit
}
Set-MpPreference -DisableRealtimeMonitoring $true

# 2. Selección de Versión
Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       PROTECH SOLUTIONS - MOTOR DE DESPLIEGUE            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "1. Instalar Office LTSC 2024 (Recomendado)"
Write-Host "2. Instalar Office LTSC 2021 (Equipos Antiguos)"
Write-Host "==========================================================" -ForegroundColor Cyan
$Opcion = Read-Host "Selecciona la version (1 o 2)"

if ($Opcion -eq "2") {
    $ProdID = "ProPlus2021Volume"; $Channel = "PerpetualVL2021"; $VerName = "2021"
} else {
    $ProdID = "ProPlus2024Volume"; $Channel = "PerpetualVL2024"; $VerName = "2024"
}

# 3. Limpieza y Preparación
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item $TempDir -ItemType Directory | Out-Null
Set-Location $TempDir

Write-Host "[*] Obteniendo motor de instalacion..." -ForegroundColor Cyan
curl.exe -s -L -o "setup.exe" "$RepoUrl/setup.exe"

$ConfigXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="$Channel">
    <Product ID="$ProdID"><Language ID="es-es" /></Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@
$ConfigXml | Out-File "$TempDir\config.xml" -Encoding ascii

# 4. Instalación
Write-Host "[*] Instalando Office $VerName..." -ForegroundColor Yellow
$process = Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure config.xml" -Wait -PassThru

# 5. Activación e IDENTIDAD FINAL
if ($process.ExitCode -eq 0) {
    Write-Host "[OK] Office instalado exitosamente." -ForegroundColor Green
    iex "& { $(irm https://get.activated.win) } /ohook"
    
    Set-MpPreference -DisableRealtimeMonitoring $false
    
    # --- FIRMA DE AUTOR ---
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "      PROTECH SOLUTIONS S.A.S - DESPLIEGUE EXITOSO        " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "             Ing. Juan Pablo Ante                          " -ForegroundColor White
    Write-Host "             Sistemas y Seguridad Electronica              " -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
} else {
    Write-Host "[X] Error en instalacion. Codigo: $($process.ExitCode)" -ForegroundColor Red
    Set-MpPreference -DisableRealtimeMonitoring $false
}

Set-Location C:\
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "`nProceso terminado."
Read-Host "Presiona Enter para salir"
