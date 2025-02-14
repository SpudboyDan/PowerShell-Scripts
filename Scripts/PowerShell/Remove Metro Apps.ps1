[System.Collections.ArrayList]$whitelist = @("1527c705-839a-4832-9118-54d4Bd6a0c89", "c5e2524a-ea46-4f67-841f-6a9465d9d515", "E2A4F912-2574-4A75-9BB0-0D023378592B", "F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE", "AcrobatNotificationClient", "AdobeAcrobatDCCoreApp", "AdobeAcrobatReaderCoreApp", "AppleInc.iCloud", "AppleInc.iTunes", "AppUp.IntelGraphicsExperience", "AppUp.ThunderboltControlCenter", "CortanaListenUIApp", "DellInc.DellUpdate", "DesktopLearning", "DesktopView", "DTSInc.DTSAudioProcessing", "EnvironmentsApp", "EsetContextMenu", "HoloCamera", "HoloItemPlayerApp", "HoloShell", "Ink.Handwriting.", "Microsoft.549981C3F5F10", "Microsoft.AAD.BrokerPlugin", "Microsoft.AccountsControl", "Microsoft.AsyncTextService", "Microsoft.AV1VideoExtension", "Microsoft.BingWeather", "Microsoft.BioEnrollment", "Microsoft.CredDialogHost", "Microsoft.D3DMappingLayers", "Microsoft.DesktopAppInstaller", "Microsoft.ECApp", "Microsoft.HEIFImageExtension", "Microsoft.HEVCVideoExtension", "Microsoft.LockApp", "Microsoft.MicrosoftEdge", "Microsoft.MicrosoftEdge.Stable", "Microsoft.MicrosoftEdgeDevToolsClient", "Microsoft.MPEG2VideoExtension", "Microsoft.NET.Native.Framework.", "Microsoft.NET.Native.Runtime.", "Microsoft.OneDriveSync", "Microsoft.Paint", "Microsoft.RawImageExtension", "Microsoft.ScreenSketch", "Microsoft.SecHealthUI", "Microsoft.Services.Store.Engagement", "Microsoft.StorePurchaseApp", "Microsoft.UI.Xaml.", "Microsoft.VCLibs.", "Microsoft.VP9VideoExtensions", "Microsoft.WebMediaExtensions", "Microsoft.WebpImageExtension", "Microsoft.WidgetsPlatformRuntime", "Microsoft.Win32WebViewHost", "Microsoft.WinAppRuntime.DDLM.", "Microsoft.Windows.Apprep.ChxApp", "Microsoft.Windows.AssignedAccessLockApp", "Microsoft.Windows.AugLoop.CBS", "Microsoft.Windows.CallingShellApp", "Microsoft.Windows.CapturePicker", "Microsoft.Windows.CloudExperienceHost", "Microsoft.Windows.ContentDeliveryManager", "Microsoft.Windows.DevicesFlowHosts", "Microsoft.Windows.ModalSharePickerHost", "Microsoft.Windows.NarratorQuickStart", "Microsoft.Windows.OOBENetworkCaptivePortal", "Microsoft.Windows.OOBENetworkConnectionFlow", "Microsoft.Windows.ParentalControls", "Microsoft.Windows.PeopleExperienceHost", "Microsoft.Windows.Photos", "Microsoft.Windows.PinningConfirmationDialog", "Microsoft.Windows.PrintQueueActionCenter", "Microsoft.Windows.Search", "Microsoft.Windows.SecHealthUI", "Microsoft.Windows.SecureAssessmentBrowser", "Microsoft.Windows.ShellExperienceHost", "Microsoft.Windows.StartMenuExperienceHost", "Microsoft.Windows.WindowPicker", "Microsoft.Windows.XGpuEjectDialog", "Microsoft.WindowsAlarms", "Microsoft.WindowsAppRuntime.", "Microsoft.WindowsCalculator", "Microsoft.WindowsCamera", "Microsoft.WindowsNotepad", "Microsoft.WindowsSoundRecorder", "Microsoft.WindowsStore", "Microsoft.WindowsTerminal", "Microsoft.Winget.Source", "Microsoft.Xbox.TCUI", "Microsoft.XboxGameCallableUI", "Microsoft.XboxGameOverlay", "Microsoft.XboxGamingOverlay", "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay", "MicrosoftCorporationII.WinAppRuntime.", "MicrosoftCorporationII.QuickAssist", "MicrosoftWindows.Client.CBS", "MicrosoftWindows.Client.Core", "MicrosoftWindows.Client.FileExp", "MicrosoftWindows.Client.LKG", "MicrosoftWindows.Client.OOBE", "MicrosoftWindows.Client.Photon", "MicrosoftWindows.Client.WebExperience", "MicrosoftWindows.CrossDevice", "MicrosoftWindows.LKG.AccountsService", "MicrosoftWindows.LKG.DesktopSpotlight", "MicrosoftWindows.LKG.IrisService", "MicrosoftWindows.LKG.RulesEngine", "MicrosoftWindows.LKG.SpeechRuntime", "MicrosoftWindows.LKG.TwinSxS", "MicrosoftWindows.UndockedDevKit", "MixedRealityLearning", "MSTeams", "NcsiUwpApp", "NVIDIACorp.NVIDIAControlPanel", "Ookla.SpeedtestbyOokla", "Passthrough", "RealtekSemiconductorCorp.RealtekAudioControl", "RoomAdjustment", "WavesAudio.MaxxAudioPro", "WebAuthBridgeInternet", "WebAuthBridgeInternetSso", "WebAuthBridgeIntranetSso", "WhatsNew", "Windows.CBSPreview", "windows.immersivecontrolpanel", "Windows.PrintDialog");

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

$appxprovisionedpackage = Get-AppxProvisionedPackage -Online

foreach ($metroApp in $blacklist) {
	Write-Output "Trying to remove $metroApp"
	
	Get-AppxPackage -Name $metroApp -AllUsers | Remove-AppxPackage -AllUsers

	($appxprovisionedpackage).Where( {$_.DisplayName -EQ $metroApp}) |
		Remove-AppxProvisionedPackage -Online
}
