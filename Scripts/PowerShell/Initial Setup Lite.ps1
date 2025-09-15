$newComputerName = Read-Host "What would you like to name this computer?";
$cimComputerSys = Get-CimInstance -ClassName Win32_ComputerSystem;
$modelName = $cimComputerSys | Select-Object -ExpandProperty Model;
$productNumber = $cimComputerSys | Select-Object -ExpandProperty SystemSKUNumber;
$serialNumber = Get-CimInstance -ClassName Win32_ComputerSystemProduct | Select-Object -ExpandProperty IdentifyingNumber;
$cimComputerSys | Set-CimInstance -Property @{AutomaticManagedPageFile = $false};

Rename-Computer -NewName $newComputerName;
New-Item -ItemType Directory -Path "C:\Driver", "C:\Util.w", "C:\Temp";
New-Item -ItemType Directory -Path "C:\Driver\! $modelName";
New-Item -ItemType Directory -Path "C:\Driver\! PN $productNumber";
New-Item -ItemType Directory -Path "C:\Driver\! SN $serialNumber";

Get-CimInstance -ClassName Win32_PageFileSetting | Set-CimInstance -Property @{InitialSize = 16384; MaximumSize = 16384};

if ((Get-Volume -DriveLetter 'C' | Select-Object -ExpandProperty Size) -lt 549755813888) 
{
	vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=10GB
} 

else 
{
	vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=20GB
}

if ((Get-BitLockerVolume -MountPoint 'C:' | Select-Object -ExpandProperty VolumeStatus) -NotMatch 'FullyDecrypted') 
{
	Disable-BitLocker -MountPoint 'C:'; Write-Host "Disabling BitLocker..."
} 

else 
{
	Write-Host "BitLocker is already disabled."
}

Set-Volume -DriveLetter 'C' -NewFileSystemLabel 'C-Drive';
Set-TimeZone 'Central Standard Time';
Start-Service W32Time;
w32tm /resync;

[System.Collections.ArrayList]$whitelist = @("1527c705-839a-4832-9118-54d4Bd6a0c89", "c5e2524a-ea46-4f67-841f-6a9465d9d515", "E2A4F912-2574-4A75-9BB0-0D023378592B", "F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE", "AdobeAcrobatReaderCoreApp", "AppleInc.iCloud", "AppleInc.iTunes", "CortanaListenUIApp", "DellInc.DellUpdate", "DesktopLearning", "DesktopView", "ELANMicroelectronicsCorpo.ELANTouchpadSetting", "EnvironmentsApp", "EsetContextMenu", "HoloCamera", "HoloItemPlayerApp", "HoloShell", "Ink.Handwriting.", "Microsoft.AAD.BrokerPlugin", "Microsoft.AccountsControl", "Microsoft.AsyncTextService", "Microsoft.AV1VideoExtension", "Microsoft.BingWeather", "Microsoft.BioEnrollment", "Microsoft.CredDialogHost", "Microsoft.D3DMappingLayers", "Microsoft.DesktopAppInstaller", "Microsoft.ECApp", "Microsoft.HEIFImageExtension", "Microsoft.HEVCVideoExtension", "Microsoft.LockApp", "Microsoft.MicrosoftEdge", "Microsoft.MicrosoftEdge.Stable", "Microsoft.MicrosoftEdgeDevToolsClient", "Microsoft.MPEG2VideoExtension", "Microsoft.NET.Native.Framework.", "Microsoft.NET.Native.Runtime.", "Microsoft.OneDriveSync", "Microsoft.Paint", "Microsoft.RawImageExtension", "Microsoft.ScreenSketch", "Microsoft.SecHealthUI", "Microsoft.Services.Store.Engagement", "Microsoft.StorePurchaseApp", "Microsoft.UI.Xaml.", "Microsoft.VCLibs.", "Microsoft.VP9VideoExtensions", "Microsoft.WebMediaExtensions", "Microsoft.WebpImageExtension", "Microsoft.Win32WebViewHost", "Microsoft.WinAppRuntime.DDLM.", "Microsoft.Windows.Apprep.ChxApp", "Microsoft.Windows.AssignedAccessLockApp", "Microsoft.Windows.CallingShellApp", "Microsoft.Windows.CapturePicker", "Microsoft.Windows.CloudExperienceHost", "Microsoft.Windows.ContentDeliveryManager", "Microsoft.Windows.DevicesFlowHost", "Microsoft.Windows.ModalSharePickerHost", "Microsoft.Windows.NarratorQuickStart", "Microsoft.Windows.OOBENetworkCaptivePortal", "Microsoft.Windows.OOBENetworkConnectionFlow", "Microsoft.Windows.ParentalControls", "Microsoft.Windows.PeopleExperienceHost", "Microsoft.Windows.Photos", "Microsoft.Windows.PinningConfirmationDialog", "Microsoft.Windows.PrintQueueActionCenter", "Microsoft.Windows.Search", "Microsoft.Windows.SecHealthUI", "Microsoft.Windows.SecureAssessmentBrowser", "Microsoft.Windows.ShellExperienceHost", "Microsoft.Windows.StartMenuExperienceHost", "Microsoft.Windows.WindowPicker", "Microsoft.Windows.XGpuEjectDialog", "Microsoft.WindowsAlarms", "Microsoft.WindowsAppRuntime.", "Microsoft.WindowsCalculator", "Microsoft.WindowsCamera", "Microsoft.WindowsNotepad", "Microsoft.WindowsStore", "Microsoft.WindowsTerminal", "Microsoft.Winget.Source", "Microsoft.XboxGameCallableUI", "MicrosoftCorporationII.WinAppRuntime.", "MicrosoftCorporationII.QuickAssist", "MicrosoftWindows.Client.CBS", "MicrosoftWindows.Client.Core", "MicrosoftWindows.Client.FileExp", "MicrosoftWindows.Client.LKG", "MicrosoftWindows.Client.WebExperience", "MicrosoftWindows.UndockedDevKit", "MixedRealityLearning", "NcsiUwpApp", "NVIDIACorp.NVIDIAControlPanel", "Ookla.SpeedtestbyOokla", "Passthrough", "RealtekSemiconductorCorp.", "RoomAdjustment", "WavesAudio.MaxxAudioPro", "WebAuthBridgeInternet", "WebAuthBridgeInternetSso", "WebAuthBridgeIntranetSso", "WhatsNew", "Windows.CBSPreview", "windows.immersivecontrolpanel", "Windows.PrintDialog");
[System.Collections.ArrayList]$blacklist = @(Get-AppxPackage | Select-Object -ExpandProperty Name | Select-String -Pattern $whitelist -NotMatch | ForEach-Object -Process {"`n$_"});

while ((Read-Host -Prompt "`nThe following Metro Apps will be removed:`n$blacklist`n`nPlease confirm with 'y' to proceed") -ne 'y')
{
    [System.Collections.ArrayList]$addToWhitelist = @(Read-Host -Prompt "Please name any apps you do not want removed, separated by a single space");
    
    if ($addToWhitelist -match " ") {$addToWhitelist = $addToWhitelist.Split(" ")}
    
    else {$addToWhitelist = $addToWhitelist}
    
    [System.Collections.ArrayList]$blacklist = @(Get-AppxPackage | Select-Object -ExpandProperty Name | Select-String -Pattern ($whitelist + $addToWhitelist) -NotMatch | ForEach-Object -Process {"`n$_"});
    $whitelist = $whitelist + $addToWhitelist;

}

[System.Collections.ArrayList]$blacklist = @(Get-AppxPackage | Select-Object -ExpandProperty Name | Select-String -Pattern $whitelist -NotMatch);

foreach ($metroApp in $blacklist) 
{
	Get-AppxPackage -Name $metroApp | Remove-AppxPackage
}
