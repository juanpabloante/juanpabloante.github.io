# ==============================================================================
# PROTECH SOLUTIONS S.A.S - ENTERPRISE DEPLOYMENT ENGINE v10.1 (GOLD EDITION)
# Desarrollado por: Ing. Juan Pablo Ante
# Estándar: Resiliencia Senior, Logging Estructurado y Seguridad Fall-Safe
# ==============================================================================

# --- 1. CONFIGURACIÓN DE LOGGING (Caja Negra) ---
$LogPath = "$env:TEMP\ProTech_Office_Deploy.log"
Start-Transcript -Path $LogPath -Append

# --- 2. VARIABLES DE INFRAESTRUCTURA ---
$RepoUrl = "https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main"
$TempDir = "C:\ProTechDeploy"
$ModoDesatendido = $false # Cambiar a $true si deseas que el cliente NO vea nada

# --- 3. MÓDULOS DE INGENIERÍA ---

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

function Test-OfficeConflict {
    Write-Host "[*] Escaneando registros por conflictos de coexistencia..." -ForegroundColor Cyan
    $C2R = Test-Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    $Legacy = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*Microsoft Office*" }
    if ($C2R -or $Legacy) { return $true } else { return $false }
}

# --- 4. PROCESO MAESTRO (TRY-CATCH-FINALLY) ---
try {
    # Validaciones de Inicio
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Se requieren privilegios de Administrador para este despliegue."
    }

    Set-SecurityShields -State "OFF"

    # UI de Selección
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "       PROTECH SOLUTIONS S.A.S - ENGINE v10.1             " -ForegroundColor Cyan
    Write-Host "       LOG: $LogPath" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "1. Instalar Office LTSC 2024 (Recomendado)"
    Write-Host "2. Instalar Office LTSC 2021 (Legacy)"
    Write-Host "==========================================================" -ForegroundColor Cyan
    $Opcion = Read-Host "Seleccion"
    
    $VerName = if ($Opcion -eq "2") { "2021" } else { "2024" }
    $ProdID = if ($Opcion -eq "2") { "ProPlus2021Volume" } else { "ProPlus2024Volume" }
    $Channel = if ($Opcion -eq "2") { "PerpetualVL2021" } else { "PerpetualVL2024" }

    # 3. Verificación y Purga de Conflictos (REVISADO PARA EVITAR ERROR 0-2048)
    if (Test-OfficeConflict) {
        Write-Host "[!] ALERTA: Se detecto una instalacion previa de Office." -ForegroundColor Yellow
        $Confirm = Read-Host "¿Deseas ejecutar desinstalacion forzada antes de continuar? (S/N)"
        if ($Confirm -eq 'S' -or $Confirm -eq 's') {
            if (!(Test-Path $TempDir)) { New-Item $TempDir -ItemType Directory -Force | Out-Null }
            
            Write-Host "[*] Descargando motor para desinstalacion..." -ForegroundColor Cyan
            Get-RemoteFile -Url "$RepoUrl/setup.exe" -Dest "$TempDir\setup.exe"
            
            $UnXmlPath = "$TempDir\uninstall.xml"
            $UnXmlContent = "<Configuration><Remove All='TRUE'></Remove><Display Level='Full' AcceptEULA='TRUE' /></Configuration>"
            $UnXmlContent | Out-File -FilePath $UnXmlPath -Encoding ascii -Force

            Write-Host "[*] Ejecutando purga completa. Por favor espera..." -ForegroundColor Yellow
            # Se usa ruta absoluta entre comillas para corregir el error 0-2048
            $procUn = Start-Process -FilePath "$TempDir\setup.exe" -ArgumentList "/configure `"$UnXmlPath`"" -Wait -PassThru
            
            if ($procUn.ExitCode -eq 0) {
                Write-Host "[OK] Purga completada exitosamente." -ForegroundColor Green
            }
        }
    }

    # Preparación de Instalación
    if (!(Test-Path $TempDir)) { New-Item $TempDir -ItemType Directory | Out-Null }
    Set-Location $TempDir
    Get-RemoteFile -Url "$RepoUrl/setup.exe" -Dest "setup.exe"

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

    Write-Host "[*] Lanzando motor de instalacion Office $VerName..." -ForegroundColor Yellow
    Write-Host "Veras la ventana de progreso oficial de Microsoft." -ForegroundColor White
    $process = Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure config.xml" -Wait -PassThru

    if ($process.ExitCode -ne 0) { throw "Error en instalador de Office. Codigo: $($process.ExitCode)" }

    # Activación
    Write-Host "[*] Aplicando activacion permanente (Ohook)..." -ForegroundColor Cyan
    iex "& { $(irm https://get.activated.win) } /ohook"

} catch {
    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # BLOQUE DE CIERRE GARANTIZADO (Siempre reactiva seguridad y limpia)
    Set-SecurityShields -State "ON"
    Write-Host "`n[*] Limpiando entorno..." -ForegroundColor Gray
    Set-Location C:\
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Stop-Transcript

    # FIRMA E IDENTIDAD CORPORATIVA
    Write-Host "`n==========================================================" -ForegroundColor Cyan
    Write-Host "      PROTECH SOLUTIONS S.A.S - DESPLIEGUE EXITOSO        " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "             Ing. Juan Pablo Ante                          " -ForegroundColor White
    Write-Host "             Consultoria en Tecnologia y Seguridad         " -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
    Read-Host "Presiona Enter para finalizar el proceso"
}
