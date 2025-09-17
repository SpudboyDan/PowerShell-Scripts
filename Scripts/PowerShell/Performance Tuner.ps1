$cimComputerSys | Set-CimInstance -Property @{AutomaticManagedPageFile = $false };

Get-CimInstance -ClassName Win32_PageFileSetting | Set-CimInstance -Property @{InitialSize = 16384; MaximumSize = 16384 };

if ((Get-Volume -DriveLetter 'C' | Select-Object -ExpandProperty Size) -lt 549755813888) {
    vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=10GB
} 

else {
    vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=20GB
}

if ((Get-BitLockerVolume -MountPoint 'C:' | Select-Object -ExpandProperty VolumeStatus) -notmatch 'FullyDecrypted') {
    Disable-BitLocker -MountPoint 'C:'; Write-Host "Disabling BitLocker..."
} 

else {
    Write-Host "BitLocker is already disabled."
}

Set-TimeZone 'Central Standard Time';
Start-Service W32Time;
w32tm /resync;
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name fAllowToGetHelp -Type DWord -Value 00000000;
Set-NetFirewallRule -DisplayGroup "Remote Assistance" -Enabled False;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes" -Name ThemeChangesMousePointers -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes" -Name ThemeChangesDesktopIcons -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name EnableTransparency -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name KeyboardDelay -Type String -Value 0;
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name KeyboardSpeed -Type String -Value 31;

if ((Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu") -eq $False) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons" -Name ClassicStartMenu;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name '{59031a47-3f72-44a7-89c5-5595fe6b30ee}' -PropertyType DWord -Value 00000000;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' -PropertyType DWord -Value 00000000;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name '{645FF040-5081-101B-9F08-00AA002F954E}' -PropertyType DWord -Value 00000000;
}

else {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Force -Name '{59031a47-3f72-44a7-89c5-5595fe6b30ee}' -PropertyType DWord -Value 00000000;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Force -Name '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' -PropertyType DWord -Value 00000000;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Force -Name '{645FF040-5081-101B-9F08-00AA002F954E}' -PropertyType DWord -Value 00000000;
}

if ((Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel") -eq $False) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons" -Name NewStartPanel;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name '{59031a47-3f72-44a7-89c5-5595fe6b30ee}' -PropertyType DWord -Value 00000000;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' -PropertyType DWord -Value 00000000;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name '{645FF040-5081-101B-9F08-00AA002F954E}' -PropertyType DWord -Value 00000000;
}

else {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Force -Name '{59031a47-3f72-44a7-89c5-5595fe6b30ee}' -PropertyType DWord -Value 00000000;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Force -Name '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' -PropertyType DWord -Value 00000000;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Force -Name '{645FF040-5081-101B-9F08-00AA002F954E}' -PropertyType DWord -Value 00000000;
}

if ((Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement") -eq $False) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name UserProfileEngagement;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name ScoobeSystemSettingEnabled -PropertyType DWord -Value 00000000;
}

else {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Force -Name ScoobeSystemSettingEnabled -PropertyType DWord -Value 0000000;
}

if ((Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings") -eq $False) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight" -Name Settings;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings" -Name EnabledState -PropertyType DWord -Value 00000000;
}

else {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DesktopSpotlight\Settings" -Force -Name EnabledState -PropertyType DWord -Value 00000000;
}

if ((Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start") -eq $False) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name Start;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name ShowRecentList -PropertyType DWord -Value 00000001;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name ShowFrequentList -PropertyType DWord -Value 00000000;
}

else {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Force -Name ShowRecentList -PropertyType DWord -Value 00000001;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Force -Name ShowFrequentList -PropertyType DWord -Value 00000000;
}

if ((Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard") -eq $False) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name SmartActionPlatform;
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform" -Name SmartClipboard;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard" -Name Disabled -PropertyType DWord -Value 00000001;
}

else {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SmartActionPlatform\SmartClipboard" -Force -Name Disabled -PropertyType DWord -Value 00000001;
}

if ((Test-Path -Path "HKCU:\Software\Microsoft\Siuf") -eq $False) {
    New-Item -Path "HKCU:\Software\Microsoft" -Name Siuf;
    New-Item -Path "HKCU:\Software\Microsoft\Siuf" -Name Rules;
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name NumberOfSIUFInPeriod -PropertyType DWord -Value 00000000;
}

else {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Force -Name NumberOfSIUFInPeriod -PropertyType DWord -Value 00000000;
}

if ((Test-Path -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync") -eq $False) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync";
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" -Name Value -PropertyType String -Value Deny;
}

else {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" -Force -Name Value -PropertyType String -Value Deny;
}

New-ItemProperty -Path "HKCU:\Control Panel\International\User Profile" -Name HttpAcceptLanguageOptOut -PropertyType DWord -Value 00000001;
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Start_AccountNotifications -PropertyType DWord -Value 00000000; 
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name RotatingLockScreenEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name RotatingLockScreenOverlayEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SubscribedContent-310093Enabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SubscribedContent-338389Enabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SubscribedContent-338393Enabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SubscribedContent-353694Enabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name SubscribedContent-353696Enabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name EnableClipboardHistory -Type DWord -Value 00000001;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" -Name BackgroundType -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowCopilotButton -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Start_IrisRecommendations -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Start_TrackDocs -Type DWord -Value 00000001;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAl -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarDa -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowSecondsInSystemClock -Type DWord -Value 00000001;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchboxTaskbarMode -Type DWord -Value 00000001;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" -Name EnableAccountNotifications -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name AcceptedPrivacyPolicy -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name AllowTelemetry -Type DWord -Value 00000001;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name MaxTelemetryAllowed -Type DWord -Value 00000001;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name TailoredExperiencesWithDiagnosticDataEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack\EventTranscriptKey" -Name EnableEventTranscript -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name IsAADCloudSearchEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name IsDeviceSearchHistoryEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name IsDynamicSearchBoxEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name IsMSACloudSearchEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name IsContinuousInnovationOptedIn -Type DWord -Value 00000001;
