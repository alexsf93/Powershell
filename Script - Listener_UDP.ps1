
<#
=====================================================================================================
    SCRIPT DE PRUEBA: ENVÍO DE MENSAJE UDP AL PUERTO 8866 EN LOCALHOST
-----------------------------------------------------------------------------------------------------
Este script envía un mensaje UDP al puerto 8866 del servidor local (`localhost`) para validar la 
comunicación mediante el protocolo UDP. Es útil para pruebas de conectividad, diagnóstico de servicios 
escuchando en ese puerto, o verificación de firewalls y reglas de red.

-----------------------------------------------------------------------------------------------------
REQUISITOS
-----------------------------------------------------------------------------------------------------
- Compatible con PowerShell 5.1 y 7.x.
- El puerto 8866 debe estar abierto y escuchando en `localhost`.
- No requiere privilegios elevados.
- El mensaje se codifica en UTF-8.

-----------------------------------------------------------------------------------------------------
¿CÓMO FUNCIONA?
-----------------------------------------------------------------------------------------------------
- Define el servidor de destino (`localhost`) y el puerto (`8866`).
- Crea un cliente UDP.
- Construye un mensaje con el nombre del host local.
- Codifica el mensaje en UTF-8.
- Envía el mensaje al puerto especificado.
- Cierra el cliente UDP.
- Muestra confirmación en consola.

-----------------------------------------------------------------------------------------------------
RESULTADOS
-----------------------------------------------------------------------------------------------------
- Si el puerto está escuchando, el mensaje será recibido por el servicio correspondiente.
- Si no hay servicio escuchando, el mensaje se descarta sin error.
- Útil para pruebas de conectividad sin necesidad de respuesta.

-----------------------------------------------------------------------------------------------------
INSTRUCCIONES DE USO
-----------------------------------------------------------------------------------------------------
- Ejecutar en PowerShell como script local.
- Verificar que el puerto 8866 esté habilitado en el firewall.

-----------------------------------------------------------------------------------------------------
AUTOR: Alejandro Suárez (@alexsf93)
=====================================================================================================
#>

param(
    [int]$Port = 8866
)
$script:udp = $null
$script:keepRunning = $true
$script:endPoint = $null
$eventRegistration = $null

try {
    Write-Host "Iniciando listener UDP en puerto $Port..."
    $script:udp = New-Object System.Net.Sockets.UdpClient($Port)
    $script:endPoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any,0)

    $eventRegistration = Register-EngineEvent -SourceIdentifier ConsoleCancelEvent -Action {
        Write-Host "`n[Evento] Ctrl+C detectado. Cerrando listener..."
        $script:keepRunning = $false
        try {
            if ($null -ne $script:udp) {
                $script:udp.Close()
            }
        } catch {
        }
    }

    Write-Host "Escuchando... pulsa Ctrl+C para detener y cerrar el puerto."
    while ($script:keepRunning) {
        try {
            $bytes = $script:udp.Receive([ref]$script:endPoint)
            if ($bytes -ne $null -and $bytes.Length -gt 0) {
                $msg = [System.Text.Encoding]::UTF8.GetString($bytes)
                $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Host ("{0} <- {1}:{2}  |  {3}" -f $now, $script:endPoint.Address, $script:endPoint.Port, $msg)
            }
        } catch [System.ObjectDisposedException] {
            break
        } catch [System.Net.Sockets.SocketException] {
            Write-Host "[SocketException] $_"
            break
        } catch {
            Write-Host "[Error] $_"
            break
        }
    }

} finally {
    try {
        if ($null -ne $script:udp) {
            $script:udp.Close()
            $script:udp = $null
        }
    } catch { }

    if ($null -ne $eventRegistration) {
        try { Unregister-Event -SourceIdentifier ConsoleCancelEvent -ErrorAction SilentlyContinue } catch {}
        try { Remove-Event -SourceIdentifier ConsoleCancelEvent -ErrorAction SilentlyContinue } catch {}
    }

    Write-Host "Listener detenido y socket cerrado."
}
