# Instalar el paquete de idioma español (España)
Add-WindowsCapability -Online -Name Language.Basic~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.Handwriting~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.OCR~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.Speech~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.TextToSpeech~~~es-ES~0.0.1.0

# Esperar unos segundos para asegurar que los paquetes se han instalado
Start-Sleep -Seconds 10

# Configura español como idioma principal y de sistema
Set-WinSystemLocale es-ES
Set-WinUserLanguageList es-ES -Force
Set-Culture es-ES
Set-WinUILanguageOverride es-ES
Set-WinHomeLocation -GeoId 195 # España

# Cambia la zona horaria a Madrid
Set-TimeZone -Id "Romance Standard Time"

# Añade el layout de teclado español (España) y lo deja como predeterminado
$LangList = Get-WinUserLanguageList
$LangList[0].InputMethodTips.Clear()
$LangList[0].InputMethodTips.Add("040a:0000040a")
Set-WinUserLanguageList $LangList -Force

# Opcional: Quita otros teclados (como en-US) si existieran
$LangList = Get-WinUserLanguageList
$LangList = $LangList | Where-Object { $_.LanguageTag -eq "es-ES" }
Set-WinUserLanguageList $LangList -Force

# Hacer que el idioma sea predeterminado para la pantalla de bienvenida y nuevos usuarios
Set-WinUILanguageOverride -Language es-ES
Set-WinSystemLocale -SystemLocale es-ES
Set-WinDefaultInputMethodOverride -InputTip "040a:0000040a"

# --- Opciones AVANZADAS de Windows Update ---

# Activar "Get the latest updates as soon as they’re available"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "IsContinuousInnovationOptedIn" -Value 1 -Type DWord

# Activar “Receive updates for other Microsoft products”
try {
    $ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
    $ServiceManager.ClientApplicationID = "My App"
    $ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
} catch {
    Write-Output "Microsoft Update ya estaba registrado o no es necesario registrar."
}

# Activar “Get me up to date” (permite reinicio automático si es necesario)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "RestartForFeatureUpdatesEnabled" -Value 1 -Type DWord

# Reinicia para aplicar todos los cambios (muy recomendable)
Restart-Computer -Force
