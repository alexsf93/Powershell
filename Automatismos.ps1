# ============================
# Automatismos.ps1
# Configuración automática VM Windows 11 en español (Azure)
# ============================

# --------- IDIOMA, TECLADO, ZONA HORARIA ---------
Add-WindowsCapability -Online -Name Language.Basic~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.Handwriting~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.OCR~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.Speech~~~es-ES~0.0.1.0
Add-WindowsCapability -Online -Name Language.TextToSpeech~~~es-ES~0.0.1.0

Start-Sleep -Seconds 10

Set-WinSystemLocale es-ES
Set-WinUserLanguageList es-ES -Force
Set-Culture es-ES
Set-WinUILanguageOverride es-ES
Set-WinHomeLocation -GeoId 195 # España
Set-TimeZone -Id "Romance Standard Time"

# Configuración de teclado español (España)
$LangList = Get-WinUserLanguageList
$LangList[0].InputMethodTips.Clear()
$LangList[0].InputMethodTips.Add("040a:0000040a")
Set-WinUserLanguageList $LangList -Force

# Deja sólo es-ES como idioma
$LangList = Get-WinUserLanguageList | Where-Object { $_.LanguageTag -eq "es-ES" }
Set-WinUserLanguageList $LangList -Force

Set-WinUILanguageOverride -Language es-ES
Set-WinSystemLocale -SystemLocale es-ES
Set-WinDefaultInputMethodOverride -InputTip "040a:0000040a"

# --------- COPIAR CONFIGURACIÓN REGIONAL (TRUCO PARA FORZAR DISPLAY LANGUAGE) ---------
$xml = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
  <gs:UserList>
    <gs:User UserID="Current"/>
  </gs:UserList>
  <gs:UserLocale>
    <gs:Locale Name="es-ES" SetAsCurrent="true"/>
  </gs:UserLocale>
  <gs:UILanguage>
    <gs:UILanguageID>es-ES</gs:UILanguageID>
  </gs:UILanguage>
  <gs:InputPreferences>
    <gs:InputLanguageID Action="add" ID="040a:0000040a"/>
  </gs:InputPreferences>
  <gs:SystemLocale Name="es-ES"/>
  <gs:GeoID Value="195"/>
  <gs:LocationPreferences>
    <gs:GeoID Value="195"/>
  </gs:LocationPreferences>
</gs:GlobalizationServices>
"@
Set-Content -Path "$env:TEMP\es-ES.xml" -Value $xml -Encoding UTF8
& "$env:SystemRoot\System32\control.exe" "intl.cpl,,/f:`"$env:TEMP\es-ES.xml`""

# --------- WINDOWS UPDATE OPCIONES AVANZADAS ---------
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "IsContinuousInnovationOptedIn" -Value 1 -Type DWord

try {
    $ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
    $ServiceManager.ClientApplicationID = "My App"
    $ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
} catch {
    Write-Output "Microsoft Update ya estaba registrado o no es necesario registrar."
}

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "RestartForFeatureUpdatesEnabled" -Value 1 -Type DWord

# --------- INSTALACIÓN DE SOFTWARE BÁSICO (winget) ---------
winget install --id=7zip.7zip -e --accept-package-agreements --accept-source-agreements
winget install --id=Notepad++.Notepad++ -e --accept-package-agreements --accept-source-agreements
winget install --id=Microsoft.Teams -e --accept-package-agreements --accept-source-agreements

# --------- MODO OSCURO PARA TODOS LOS USUARIOS ---------
# Usuario actual
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -PropertyType DWord -Value 0 -Force
# Todos los usuarios existentes
$users = Get-ChildItem 'HKU:' | Where-Object { $_.Name -match '^HKEY_USERS\\S-' }
foreach ($user in $users) {
    try {
        $regPath = "$($user.PSPath)\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        New-ItemProperty -Path $regPath -Name "AppsUseLightTheme" -PropertyType DWord -Value 0 -Force
        New-ItemProperty -Path $regPath -Name "SystemUsesLightTheme" -PropertyType DWord -Value 0 -Force
    } catch { }
}
# Para nuevos usuarios (Default User)
$defaultUserKey = "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (-not (Test-Path $defaultUserKey)) { New-Item -Path $defaultUserKey -Force | Out-Null }
New-ItemProperty -Path $defaultUserKey -Name "AppsUseLightTheme" -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path $defaultUserKey -Name "SystemUsesLightTheme" -PropertyType DWord -Value 0 -Force

# --------- REINICIO FINAL ---------
Restart-Computer -Force
