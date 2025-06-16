<#
================================================================================
 Script:        Script - Automatizaciones - Server - Roles ADDS+DNS(DominioA).ps1
 Descripción:   Instalación 100% desatendida de los roles ADDS y DNS,
                y creación automática del dominio DominioA.local.
================================================================================

 Funcionalidad:
   - Instala los roles de Active Directory Domain Services (ADDS) y DNS.
   - Crea un nuevo dominio (DominioA.local) con nombre NetBIOS (DOMINIOA).
   - Configura la contraseña de modo restauración (DSRM).
   - Proceso totalmente automático, sin intervención manual.
   - El servidor se reiniciará automáticamente tras la promoción a DC.

 Parámetros personalizables:
   - $domainName     : Nombre FQDN del dominio a crear (por defecto: DominioA.local)
   - $netbiosName    : Nombre NetBIOS del dominio (por defecto: DOMINIOA)
   - $dsrmPassword   : Contraseña para el modo de restauración de servicios de directorio
                      (¡Cámbiala por seguridad antes de usar en producción!)

 Uso:
   1. Modifica los valores de $dsrmPassword, $domainName y $netbiosName si es necesario.
   2. Ejecuta el script como Administrador en el servidor Windows.
   3. El servidor se reiniciará automáticamente al finalizar la configuración.

 Notas:
   - La ejecución requiere privilegios de administrador.
   - Cambia la contraseña de $dsrmPassword antes de usar el script en entornos productivos.

================================================================================
#>


$domainName = "DominioA.local"
$netbiosName = "DOMINIOA"
$dsrmPassword = ConvertTo-SecureString "Naxvan1993" -AsPlainText -Force  # Cambia la contraseña por seguridad

# Instala los roles
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools

# Instala el dominio de manera desatendida
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -SafeModeAdministratorPassword $dsrmPassword `
    -InstallDns `
    -Force `
    -NoRebootOnCompletion:$false  # Reinicia automáticamente después

# El servidor se reiniciará solo tras la promoción como DC.
