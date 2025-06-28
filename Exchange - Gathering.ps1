<#
===========================================================
        Exchange Online - Informe Detallado de Buzones
-----------------------------------------------------------
Autor: Alejandro Suárez (@alexsf93)
===========================================================

.DESCRIPCIÓN
    Este script se conecta a Exchange Online y obtiene información detallada de todos los buzones de usuario, excluyendo buzones de sistema.
    Permite buscar un buzón concreto con -User o mostrar todos los buzones.
    Presenta los datos en una tabla interactiva (Out-GridView) para buscar, ordenar y filtrar fácilmente.

.DATOS MOSTRADOS
    - Nombre y usuario principal (UPN)
    - Tipo de buzón
    - Alias secundarios (sin el principal)
    - Capacidad consumida y total asignada
    - Porcentaje de uso
    - Elementos almacenados y eliminados
    - Archivado habilitado
    - Política de retención
    - Litigation Hold
    - Último inicio de sesión

.REQUISITOS
    - PowerShell 7.x o Windows PowerShell 5.1
    - Módulo ExchangeOnlineManagement instalado (el script lo instala si falta)
    - Permisos para consultar buzones en Exchange Online

.EJEMPLOS DE USO
    # Mostrar todos los buzones en tabla interactiva:
    .\Exchange-Gathering.ps1

    # Mostrar sólo el buzón de un usuario concreto:
    .\Exchange-Gathering.ps1 -User usuario@dominio.com

.NOTAS
    - Excluye buzones de sistema, ajusta el filtro si lo necesitas.
    - Compatible con Out-GridView (requiere entorno gráfico).
    - Puedes copiar/exportar desde la tabla con Shift+clic o menú contextual.

===========================================================
#>

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$User
)

# Forzar consola a UTF-8
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force
}

Import-Module ExchangeOnlineManagement 6>$null

Connect-ExchangeOnline -UserPrincipalName "usuario@dominio.tld" 6>$null

Write-Host "Obteniendo buzones de Exchange (excluyendo buzones de sistema)..." -ForegroundColor Cyan

if ($null -ne $User -and $User.Trim() -ne "") {
    $mailboxes = Get-Mailbox -Identity $User -ErrorAction SilentlyContinue | Where-Object {
        $_.UserPrincipalName -notmatch '(?i)^(DiscoverySearchMailbox|SystemMailbox|FederatedEmail|HealthMailbox|Migration|O365Services|SPO_Admin|SpfAutoDiscover|sipfed|exclaimer|sharepoint|admin|system|microsoft)'
    }
    if (-not $mailboxes) {
        Write-Warning "No se encontro ningun buzon para el usuario '$User'."
        Disconnect-ExchangeOnline -Confirm:$false
        exit
    }
} else {
    $mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {
        $_.UserPrincipalName -notmatch '(?i)^(DiscoverySearchMailbox|SystemMailbox|FederatedEmail|HealthMailbox|Migration|O365Services|SPO_Admin|SpfAutoDiscover|sipfed|exclaimer|sharepoint|admin|system|microsoft)'
    }
}

function Convert-ToMB {
    param($value)
    if ($value -match "(\d+[\.,]?\d*)\s*GB") {
        return [math]::Round(([double]$matches[1]) * 1024,2)
    } elseif ($value -match "(\d+[\.,]?\d*)\s*MB") {
        return [math]::Round([double]$matches[1],2)
    } else {
        return $null
    }
}

$resultados = foreach ($mb in $mailboxes) {
    try {
        $stats = Get-MailboxStatistics -Identity $mb.UserPrincipalName

        # Alias, eliminando smtp:, ignorando el principal
        $primary = $mb.PrimarySmtpAddress.ToString().ToLower()
        $aliases = $mb.EmailAddresses | Where-Object {
            ($_ -like "smtp:*") -and ($_.ToString().Substring(5).ToLower() -ne $primary)
        } | ForEach-Object {
            $_.ToString().Substring(5)
        }

        # Quitar la parte " (xxxx bytes)" de consumido y limite
        $consumidoStr = $stats.TotalItemSize.ToString() -replace '\s*\(.*\)', ''
        $limiteStr = if ($null -ne $mb.ProhibitSendQuota) { $mb.ProhibitSendQuota.ToString() -replace '\s*\(.*\)', '' } else { "No definido" }

        # Calculo porcentaje de uso (comparacion $null -ne X)
        $consumidoMB = Convert-ToMB $consumidoStr
        $limiteMB = Convert-ToMB $limiteStr
        if (($null -ne $consumidoMB) -and ($null -ne $limiteMB) -and ($limiteMB -gt 0)) {
            $porcentaje = [math]::Round(($consumidoMB / $limiteMB) * 100, 2)
            $porcentajeTxt = "$porcentaje`%"
        } else {
            $porcentajeTxt = "No disponible"
        }

        [PSCustomObject]@{
            Nombre                = $mb.DisplayName
            Usuario               = $mb.UserPrincipalName
            TipoBuzon             = $mb.RecipientTypeDetails
            Alias                 = if ($aliases) { $aliases -join ", " } else { "No" }
            Consumido             = $consumidoStr
            Total                 = $limiteStr
            PorcentajeUso         = $porcentajeTxt
            ElementosAlmacenados  = $stats.ItemCount
            ElementosEliminados   = $stats.DeletedItemCount
            LitigationHold        = if ($mb.LitigationHoldEnabled) { "Si" } else { "No" }
            LastSignIn            = $stats.LastLogonTime
            Archivado             = if ($mb.ArchiveStatus -eq 'Active') { 'Habilitado' } else { 'No habilitado' }
            PoliticaRetencion     = if ($mb.RetentionPolicy) { $mb.RetentionPolicy } else { 'No asignada' }
        }
    } catch {
        Write-Warning "No se pudo obtener estadisticas para $($mb.UserPrincipalName)"
    }
}

# Mostrar resultados en una tabla interactiva (Out-GridView)
if ($resultados.Count -gt 0) {
    $resultados | Out-GridView -Title "Resumen de buzones Exchange Online"
} else {
    Write-Host "No hay datos para mostrar." -ForegroundColor Yellow
}

Disconnect-ExchangeOnline -Confirm:$false
Write-Host "Desconectado de Exchange Online." -ForegroundColor Green
