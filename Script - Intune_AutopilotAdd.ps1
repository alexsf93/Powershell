<#
=====================================================================================================
    REGISTRO DE DISPOSITIVO EN AUTOPILOT Y APAGADO CONDICIONAL
-----------------------------------------------------------------------------------------------------
Este script ejecuta el módulo `Get-WindowsAutopilotInfo` para registrar el dispositivo 
en Microsoft Autopilot con los parámetros proporcionados (TenantID, AppId, AppSecret). 
Si la ejecución es correcta, el equipo se apaga automáticamente; en caso de error, se muestra un 
mensaje en rojo y no se apaga.

-----------------------------------------------------------------------------------------------------
REQUISITOS
-----------------------------------------------------------------------------------------------------
- Ejecutar en PowerShell 5.1 o superior.
- Requiere privilegios de administrador.
- El script `Get-WindowsAutopilotInfo.ps1` debe estar en el mismo directorio o accesible por PATH.
- Credenciales válidas de Azure AD (AppId y AppSecret).
- TLS 1.2 habilitado en el sistema.

-----------------------------------------------------------------------------------------------------
¿CÓMO FUNCIONA?
-----------------------------------------------------------------------------------------------------
1. Establece TLS 1.2.
2. Ajusta ExecutionPolicy en el ámbito del proceso.
3. Guarda modelo y número de serie en `Informacion_dispositivos.txt` (si no existe ya).
4. Ejecuta `Get-WindowsAutopilotInfo.ps1` con parámetros.
5. Apaga si la ejecución es exitosa; si no, muestra error.
6. Registra acciones en un archivo de log.

-----------------------------------------------------------------------------------------------------
AUTOR: Alejandro Suárez (@alexsf93)
=====================================================================================================
#>

$TenantID   = "TENANT-ID"
$AppId      = "APP-ID"
$AppSecret  = "APP-SECRET"
$ScriptName = "Get-WindowsAutopilotInfo.ps1"
$LogFile    = "$env:ProgramData\AutopilotRegister\AutopilotRun_$(Get-Date -Format yyyyMMdd_HHmmss).log"

New-Item -Path (Split-Path $LogFile) -ItemType Directory -Force | Out-Null

function Log { param([string]$m); "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`t$m" | Out-File -FilePath $LogFile -Append -Encoding UTF8 }
function Write-ErrorRed { param([string]$m); Write-Host $m -ForegroundColor Red; Log "ERROR: $m" }
function Write-Info { param([string]$m); Write-Host $m -ForegroundColor Cyan; Log "INFO : $m" }

Write-Info "Inicio del proceso de registro Autopilot."
Log "Parámetros: TenantID=$TenantID, AppId=$AppId, Script=$ScriptName"

try {
    # Guardar modelo y número de serie si no existe
    $deviceFile = Join-Path (Get-Location) "Informacion_dispositivos.txt"
    $sysInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    $biosInfo = Get-CimInstance -ClassName Win32_BIOS
    $model = $sysInfo.Model
    $serial = $biosInfo.SerialNumber

    $exists = $false
    if (Test-Path $deviceFile) {
        $exists = Select-String -Path $deviceFile -Pattern ([regex]::Escape($serial)) -Quiet
    }

    if (-not $exists) {
        "-----------------" | Out-File -FilePath $deviceFile -Append -Encoding UTF8
        $model            | Out-File -FilePath $deviceFile -Append -Encoding UTF8
        $serial           | Out-File -FilePath $deviceFile -Append -Encoding UTF8
        "-----------------" | Out-File -FilePath $deviceFile -Append -Encoding UTF8
        Write-Info "Información de dispositivo guardada en $deviceFile"
        Log "Guardado modelo=$model, serial=$serial en $deviceFile"
    } else {
        Write-Info "El número de serie $serial ya existe en $deviceFile. No se añadirá."
        Log "Serial $serial ya presente en $deviceFile"
    }

    # TLS y ExecutionPolicy
    Write-Info "Estableciendo TLS 1.2..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Info "ExecutionPolicy (Process=RemoteSigned)..."
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

    # Ejecutar script Autopilot local
    Write-Info "Ejecutando $ScriptName con parámetros..."
    $t0 = Get-Date
    $output = & $ScriptName -Online -TenantID $TenantID -appid $AppId -appsecret $AppSecret *>&1

    if ($null -ne $output) {
        $output | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }

    $exitOk = $true
    if ($output -match "(?i)\b(error|exception|fail(ed)?)\b") {
        $exitOk = $false
        Log "Texto de error detectado en la salida del script."
    }

    $dur = (Get-Date) - $t0
    Write-Info ("Ejecución completada en {0:N1} segundos." -f $dur.TotalSeconds)

    if ($exitOk) {
        Write-Host "Autopilot ejecutado correctamente. Apagando en 5 segundos..." -ForegroundColor Green
        Log "Resultado OK: apagando equipo"
        Start-Sleep -Seconds 5
        shutdown.exe /s /f /t 0
    } else {
        Write-ErrorRed "Se detectaron errores durante la ejecución. No se apagará el equipo."
        Write-ErrorRed "Revisa el log: $LogFile"
        throw "ExecutionHeuristicDetectedError"
    }
}
catch {
    $err = $_.Exception.Message
    Write-ErrorRed "ERROR FATAL: $err"
    Write-ErrorRed "Detalles: $($_ | Out-String)"
    Log "EXCEPTION: $($_ | Out-String)"
    Write-ErrorRed "No se apagará el equipo. Log: $LogFile"
}
finally {
    Write-Info "Fin del script. Log en: $LogFile"
}
