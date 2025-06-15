# Instalar el paquete de idioma español (España)
Add-WindowsCapability -Online -Name Language.Basic~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.Handwriting~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.OCR~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.Speech~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.TextToSpeech~~~es-ES~0.0.1.0

# Establecer español como idioma predeterminado del sistema y usuario
Set-WinSystemLocale es-ES
Set-WinUserLanguageList es-ES -Force
Set-Culture es-ES
Set-WinUILanguageOverride es-ES
Set-WinHomeLocation -GeoId 195 # España

# Reinicia solo si quieres forzar la aplicación del idioma
# Restart-Computer -Force
