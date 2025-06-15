# RolesAD-DNS.ps1
# Instalación 100% desatendida de ADDS y DNS, creación de dominio DominioA.local

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
