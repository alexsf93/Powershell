# ============================
# Automatismos.ps1
# Configuración automática VM Windows 11 en español (Azure)
# ============================

# --------- IDIOMA, TECLADO, ZONA HORARIA (con DISM) ---------
dism.exe /Online /Add-Capability /CapabilityName:Language.Basic~~~es-ES~0.0.1.0
dism.exe /Online /Add-Capability /CapabilityName:Language.Handwriting~~~es-ES~0.0.1.0
dism.exe /Online /Add-Capability /CapabilityName:Language.OCR~~~es-ES~0.0.1.0
dism.exe /Online /Add-Capability /CapabilityName:Language.Speech~~~es-ES~0.0.1.0
dism.exe /Online /Add-Capability /CapabilityName:Language.TextToSpeech~~~es-ES~0.0.1.0

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

# Copiar configuración regional (pantalla bienvenida y nuevos usuarios)
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

# --------- INSTALACIÓN DE SOFTWARE BÁSICO (usando MSI/EXE, sin Teams) ---------
# Instala 7-Zip
Invoke-WebRequest -Uri "https://www.7-zip.org/a/7z2301-x64.exe" -OutFile "$env:TEMP\7z.exe"
Start-Process "$env:TEMP\7z.exe" -ArgumentList "/S" -Wait

# Instala Notepad++
Invoke-WebRequest -Uri "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.8/npp.8.6.8.Installer.x64.exe" -OutFile "$env:TEMP\npp.exe"
Start-Process "$env:TEMP\npp.exe" -ArgumentList "/S" -Wait

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

# --------- LIMPIEZA DE TEMPORALES Y LOGS ---------
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
wevtutil el | Foreach-Object {wevtutil cl "$_"} 2>$null

# --------- HABILITAR STORAGE SENSE (Limpiador automático) ---------
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "08" -Value 30 -Type DWord
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "32" -Value 30 -Type DWord

# --------- ELIMINAR BLOATWARE ---------
$unwantedApps = @(
    "king.com.CandyCrushSaga",
    "king.com.CandyCrushSodaSaga",
    "Microsoft.SkypeApp",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.Xbox.TCUI",
    "SpotifyAB.SpotifyMusic",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.OneConnect",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.YourPhone",
    "Microsoft.Office.OneNote"
)
foreach ($app in $unwantedApps) {
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# --------- DESACTIVAR SERVICIOS INNECESARIOS (Ejemplo: Xbox Game Bar) ---------
Stop-Service -Name "XboxNetApiSvc" -ErrorAction SilentlyContinue
Set-Service -Name "XboxNetApiSvc" -StartupType Disabled -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord

# --------- REINICIO FINAL ---------
Restart-Computer -Force
