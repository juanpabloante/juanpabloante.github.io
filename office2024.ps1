# ==============================================================================
# PROTECH SOLUTIONS S.A.S - ENTERPRISE DEPLOYMENT ENGINE v10.2
# Desarrollado por: Ing. Juan Pablo Ante
# Novedad v10.2: Módulo de Barrido Preventivo y Asesino de Procesos (Ghost Scrubber)
# ==============================================================================

$LogPath = "$env:TEMP\ProTech_Office_Deploy.log"
Start-Transcript -Path $LogPath -Append

$RepoUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main"
$TempDir = "C:\ProTechDeploy"
$ModoDesatendido = $false

# --- MÓDULOS ---
function Set-SecurityShields ($State) {
    try {
        if ($State -eq "OFF") {
            Write-Host "[!] Optimizando entorno: Desactivando escudos de seguridad..." -ForegroundColor Yellow
            Set-MpPreference -DisableRealtimeMonitoring $true
        } else {
            Write-Host "[*] Restaurando proteccion del sistema..." -ForegroundColor Cyan
            Set-MpPreference -DisableRealtimeMonitoring $false
        }
    } catch { Write-Warning "No se pudo cambiar el estado de Defender." }
}

function Get-RemoteFile {
    param ([string]$Url, [string]$Dest, [int]$MaxRetries = 3)
    $Attempt = 0; $Success = $false
    do {
        $Attempt++
        Write-Host "[*] Descargando componentes ProTech (Intento $Attempt de $MaxRetries)..." -ForegroundColor Cyan
        curl.exe -s -L -A "Mozilla/5.0" --ssl-no-revoke -o $Dest $Url
        if (Test-Path $Dest) {
            if ((Get-Item $Dest).Length -gt 1MB) { $Success = $true }
        }
        if (-not $Success -and $Attempt -lt $MaxRetries) {
            Write-Host "[!] Error de integridad. Reintentando en 5s..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    } while (-not $Success -and $Attempt -lt $MaxRetries)
    if (-not $Success) { throw "Fallo critico de red tras $MaxRetries intentos." }
}

# --- PROCESO MAESTRO ---
try {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Se requieren privilegios de Administrador para este despliegue."
    }

    Set-SecurityShields -State "OFF"

    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "       PROTECH SOLUTIONS S.A.S - ENGINE v10.2             " -ForegroundColor Cyan
    Write-Host "       LOG: $LogPath" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "1. Instalar Office LTSC 2024 (Recomendado)"
    Write-Host "2. Instalar Office LTSC 2021 (Legacy)"
    Write-Host "==========================================================" -ForegroundColor Cyan
    $Opcion = Read-Host "Seleccion"
    
    $VerName = if ($Opcion -eq "2") { "2021" } else { "2024" }
    $ProdID = if ($Opcion -eq "2") { "ProPlus2021Volume" } else { "ProPlus2024Volume" }
    $Channel = if ($Opcion -eq "2") { "PerpetualVL2021" } else { "PerpetualVL2024" }

    # Preparación de Directorio
    if (!(Test-Path $TempDir)) { New-Item $TempDir -ItemType Directory -Force | Out-Null }
    Set-Location $TempDir
    Get-RemoteFile -Url "$RepoUrl/setup.exe" -Dest "setup.exe"

    # --- NUEVO: BARRIDO PREVENTIVO DE FANTASMAS ---
    Write-Host "[*] Ejecutando barrido preventivo de procesos atascados..." -ForegroundColor Magenta
    Get-Process "OfficeClickToRun", "setup" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    Write-Host "[*] Esterilizando rastros de instalaciones previas..." -ForegroundColor Magenta
    $PreScrubPath = "$TempDir\prescrub.xml"
    $PreScrubXml = "<Configuration><RemoveMSI /><Remove All='TRUE' /><Display Level='None' AcceptEULA='TRUE' /></Configuration>"
    $PreScrubXml | Out-File -FilePath $PreScrubPath -Encoding ascii -Force
    
    # Se ejecuta de forma 100% silenciosa (Level='None'). No importa si da error interno porque no hay nada.
    Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure `"$PreScrubPath`"" -Wait
    
    # Aseguramos que el servicio haya muerto tras la limpieza
    Start-Sleep -Seconds 3
    Get-Process "OfficeClickToRun", "setup" -ErrorAction SilentlyContinue | Stop-Process -Force
    # ----------------------------------------------

    # Generar XML de Instalación
    $DisplayLvl = if ($ModoDesatendido) { "None" } else { "Full" }
    $ConfigXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="$Channel">
    <Product ID="$ProdID"><Language ID="es-es" /></Product>
  </Add>
  <Display Level="$DisplayLvl" AcceptEULA="TRUE" />
</Configuration>
"@
    $ConfigXml | Out-File "config.xml" -Encoding ascii

    Write-Host "[*] Lanzando motor de instalacion Office $VerName limpia..." -ForegroundColor Yellow
    $process = Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure config.xml" -Wait -PassThru

    if ($process.ExitCode -ne 0) { throw "Error en instalador de Office. Codigo: $($process.ExitCode)" }

    Write-Host "[*] Aplicando activacion permanente (Ohook)..." -ForegroundColor Cyan
    iex "& { $(irm https://get.activated.win) } /ohook"

} catch {
    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Set-SecurityShields -State "ON"
    Write-Host "`n[*] Limpiando entorno..." -ForegroundColor Gray
    Set-Location C:\
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Stop-Transcript

    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "      PROTECH SOLUTIONS S.A.S - DESPLIEGUE EXITOSO        " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "             Ing. Juan Pablo Ante                          " -ForegroundColor White
    Write-Host "             Consultoria en Tecnologia y Seguridad         " -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
    Read-Host "Presiona Enter para finalizar el proceso"
}
