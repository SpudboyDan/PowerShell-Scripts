$newComputerName = Read-Host "What would you like to name this computer?";
$secureString = (Read-Host -AsSecureString "Please enter a password for drive W");
$secureCredential = New-Object System.Management.Automation.PSCredential("$null", $secureString);
$cimComputerSys = Get-CimInstance -ClassName Win32_ComputerSystem;
$modelName = $cimComputerSys | Select-Object -ExpandProperty Model;
$productNumber = $cimComputerSys | Select-Object -ExpandProperty SystemSKUNumber;
$serialNumber = Get-CimInstance -ClassName Win32_ComputerSystemProduct | Select-Object -ExpandProperty IdentifyingNumber;
$cimComputerSys | Set-CimInstance -Property @{AutomaticManagedPageFile = $false };

Rename-Computer -NewName $newComputerName;
New-PSDrive -Name "W" -PSProvider FileSystem -Root "$null" -Scope Global -Persist -Credential $secureCredential;
New-Item -ItemType Directory -Path "C:\Driver", "C:\Util.w", "C:\Temp";
New-Item -ItemType Directory -Path "$env:USERPROFILE\AppData\Roaming\GHISLER";
New-Item -ItemType Directory -Path "C:\Driver\! $modelName";
New-Item -ItemType Directory -Path "C:\Driver\! PN $productNumber";
New-Item -ItemType Directory -Path "C:\Driver\! SN $serialNumber";

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

Set-Volume -DriveLetter 'C' -NewFileSystemLabel 'C-Drive';
Set-TimeZone 'Central Standard Time';
Start-Service W32Time;
w32tm /resync;
Copy-Item -Path "W:\01 Main\Util.w\Wincmd.INI" -Destination "$env:USERPROFILE\AppData\Roaming\GHISLER" -Force -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\wcx_ftp.ini" -Destination "$env:USERPROFILE\AppData\Roaming\GHISLER" -Force -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\WINCMD.INI" -Destination "C:\Windows" -Force -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\wcx_ftp.ini" -Destination "C:\Windows" -Force -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\Wincmd" -Destination "C:\Util.w" -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\Advanced IP Scanner 2.5" -Destination "C:\Util.w" -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\IrfanView" -Destination "C:\Util.w" -Recurse;
Copy-Item -Path "W:\00 Essentials\Cleanup" -Destination "C:\Temp" -Recurse;
Copy-Item -Path "W:\00 Essentials\Utilities" -Destination "C:\Temp" -Recurse;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "C:\Util.w\Wincmd\TOTALCMD64.EXE" -Type String -Value '~ RUNASADMIN';
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "C:\Util.w\Wincmd\TOTALCMD.EXE" -Type String -Value '~ RUNASADMIN';
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name fAllowToGetHelp -Type DWord -Value 00000000;
Set-NetFirewallRule -DisplayGroup "Remote Assistance" -Enabled False;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -Type DWord -Value 00000005;
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name PromptOnSecureDesktop -Type DWord -Value 00000000;
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

New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -PropertyType Dword -Value 00000000;
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
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name AutoGameModeEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name UseNexusForGameBarEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name AudioCaptureEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name CursorCaptureEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name HistoricalCaptureEnabled -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name HistoricalCaptureOnBatteryAllowed -Type DWord -Value 00000000;
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name HistoricalCaptureOnWirelessDisplayAllowed -Type DWord -Value 00000000;
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

[System.Collections.ArrayList]$whitelist = @("1527c705-839a-4832-9118-54d4Bd6a0c89", "c5e2524a-ea46-4f67-841f-6a9465d9d515", "E2A4F912-2574-4A75-9BB0-0D023378592B", "F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE", "AdobeAcrobatReaderCoreApp", "AppleInc.iCloud", "AppleInc.iTunes", "CortanaListenUIApp", "DellInc.DellUpdate", "DesktopLearning", "DesktopView", "ELANMicroelectronicsCorpo.ELANTouchpadSetting", "EnvironmentsApp", "EsetContextMenu", "HoloCamera", "HoloItemPlayerApp", "HoloShell", "Ink.Handwriting.", "Microsoft.AAD.BrokerPlugin", "Microsoft.AccountsControl", "Microsoft.AsyncTextService", "Microsoft.AV1VideoExtension", "Microsoft.BingWeather", "Microsoft.BioEnrollment", "Microsoft.CredDialogHost", "Microsoft.D3DMappingLayers", "Microsoft.DesktopAppInstaller", "Microsoft.ECApp", "Microsoft.HEIFImageExtension", "Microsoft.HEVCVideoExtension", "Microsoft.LockApp", "Microsoft.MicrosoftEdge", "Microsoft.MicrosoftEdge.Stable", "Microsoft.MicrosoftEdgeDevToolsClient", "Microsoft.MPEG2VideoExtension", "Microsoft.NET.Native.Framework.", "Microsoft.NET.Native.Runtime.", "Microsoft.OneDriveSync", "Microsoft.Paint", "Microsoft.RawImageExtension", "Microsoft.ScreenSketch", "Microsoft.SecHealthUI", "Microsoft.Services.Store.Engagement", "Microsoft.StorePurchaseApp", "Microsoft.UI.Xaml.", "Microsoft.VCLibs.", "Microsoft.VP9VideoExtensions", "Microsoft.WebMediaExtensions", "Microsoft.WebpImageExtension", "Microsoft.Win32WebViewHost", "Microsoft.WinAppRuntime.DDLM.", "Microsoft.Windows.Apprep.ChxApp", "Microsoft.Windows.AssignedAccessLockApp", "Microsoft.Windows.CallingShellApp", "Microsoft.Windows.CapturePicker", "Microsoft.Windows.CloudExperienceHost", "Microsoft.Windows.ContentDeliveryManager", "Microsoft.Windows.DevicesFlowHost", "Microsoft.Windows.ModalSharePickerHost", "Microsoft.Windows.NarratorQuickStart", "Microsoft.Windows.OOBENetworkCaptivePortal", "Microsoft.Windows.OOBENetworkConnectionFlow", "Microsoft.Windows.ParentalControls", "Microsoft.Windows.PeopleExperienceHost", "Microsoft.Windows.Photos", "Microsoft.Windows.PinningConfirmationDialog", "Microsoft.Windows.PrintQueueActionCenter", "Microsoft.Windows.Search", "Microsoft.Windows.SecHealthUI", "Microsoft.Windows.SecureAssessmentBrowser", "Microsoft.Windows.ShellExperienceHost", "Microsoft.Windows.StartMenuExperienceHost", "Microsoft.Windows.WindowPicker", "Microsoft.Windows.XGpuEjectDialog", "Microsoft.WindowsAlarms", "Microsoft.WindowsAppRuntime.", "Microsoft.WindowsCalculator", "Microsoft.WindowsCamera", "Microsoft.WindowsNotepad", "Microsoft.WindowsStore", "Microsoft.WindowsTerminal", "Microsoft.Winget.Source", "Microsoft.XboxGameCallableUI", "MicrosoftCorporationII.WinAppRuntime.", "MicrosoftCorporationII.QuickAssist", "MicrosoftWindows.Client.CBS", "MicrosoftWindows.Client.Core", "MicrosoftWindows.Client.FileExp", "MicrosoftWindows.Client.LKG", "MicrosoftWindows.Client.WebExperience", "MicrosoftWindows.UndockedDevKit", "MixedRealityLearning", "NcsiUwpApp", "NVIDIACorp.NVIDIAControlPanel", "Ookla.SpeedtestbyOokla", "Passthrough", "RealtekSemiconductorCorp.", "RoomAdjustment", "WavesAudio.MaxxAudioPro", "WebAuthBridgeInternet", "WebAuthBridgeInternetSso", "WebAuthBridgeIntranetSso", "WhatsNew", "Windows.CBSPreview", "windows.immersivecontrolpanel", "Windows.PrintDialog");

[System.Collections.ArrayList]$blacklist = @(Get-AppxPackage | Select-Object -ExpandProperty Name | Select-String -Pattern $whitelist -NotMatch | ForEach-Object -Process { "`n$_" });

while ((Read-Host -Prompt "`nThe following Metro Apps will be removed:`n$blacklist`n`nPlease confirm with 'y' to proceed") -ne 'y') {
    [System.Collections.ArrayList]$addToWhitelist = @(Read-Host -Prompt "Please name any apps you do not want removed, separated by a single space");
    
    if ($addToWhitelist -match " ") { $addToWhitelist = $addToWhitelist.Split(" ") }
    
    else { $addToWhitelist = $addToWhitelist }
    
    [System.Collections.ArrayList]$blacklist = @(Get-AppxPackage | Select-Object -ExpandProperty Name | Select-String -Pattern ($whitelist + $addToWhitelist) -NotMatch | ForEach-Object -Process { "`n$_" });
    $whitelist = $whitelist + $addToWhitelist;

}

[System.Collections.ArrayList]$blacklist = @(Get-AppxPackage | Select-Object -ExpandProperty Name | Select-String -Pattern $whitelist -NotMatch);

foreach ($metroApp in $blacklist) {
    Get-AppxPackage -Name $metroApp | Remove-AppxPackage
};
