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

$server = "localhost"
$port = 8866
$udpclient = New-Object System.Net.Sockets.UdpClient
$msg = "PRUEBA_UDP_8866 desde CLIENTE " + (hostname)
$bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
$udpclient.Send($bytes, $bytes.Length, $server, $port) | Out-Null
$udpclient.Close()
Write-Host "Mensaje enviado"
