# instalaAD_DNS.ps1

$domainName = "DominioA.local"
$netbiosName = "DominioA"
$adminPass = "Naxvan1993"  # Usa una contraseña fuerte o pásala como parámetro seguro

# Instala los roles
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools

# Promueve el servidor como controlador de dominio raíz en un nuevo bosque
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -SafeModeAdministratorPassword (ConvertTo-SecureString $adminPass -AsPlainText -Force) `
    -Force `
    -NoRebootOnCompletion $false
