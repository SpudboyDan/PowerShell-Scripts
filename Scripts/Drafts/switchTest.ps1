[System.Collections.ArrayList]$whitelist = @("1527c705-839a-4832-9118-54d4Bd6a0c89", "c5e2524a-ea46-4f67-841f-6a9465d9d515", "E2A4F912-2574-4A75-9BB0-0D023378592B", "F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE", "AppleInc.iCloud", "AppleInc.iTunes", "DellInc.DellUpdate", "DesktopView", "EnvironmentsApp", "EsetContextMenu", "HoloCamera", "HoloItemPlayerApp", "HoloShell", "Microsoft.AAD.BrokerPlugin", "Microsoft.AccountsControl", "Microsoft.AsyncTextService", "Microsoft.AV1VideoExtension", "Microsoft.BingWeather", "Microsoft.BioEnrollment", "Microsoft.CredDialogHost", "Microsoft.D3DMappingLayers", "Microsoft.DesktopAppInstaller", "Microsoft.ECApp", "Microsoft.HEIFImageExtension", "Microsoft.HEVCVideoExtension", "Microsoft.LockApp", "Microsoft.MicrosoftEdge.Stable", "Microsoft.MicrosoftEdgeDevToolsClient", "Microsoft.MPEG2VideoExtension", "Microsoft.NET.Native.Framework.", "Microsoft.NET.Native.Runtime.", "Microsoft.OneDriveSync", "Microsoft.Paint", "Microsoft.RawImageExtension", "Microsoft.ScreenSketch", "Microsoft.SecHealthUI", "Microsoft.Services.Store.Engagement", "Microsoft.StorePurchaseApp", "Microsoft.UI.Xaml.", "Microsoft.VCLibs.", "Microsoft.VP9VideoExtensions", "Microsoft.WebMediaExtensions", "Microsoft.WebpImageExtension", "Microsoft.Win32WebViewHost", "Microsoft.Windows.Apprep.ChxApp", "Microsoft.Windows.AssignedAccessLockApp", "Microsoft.Windows.CallingShellApp", "Microsoft.Windows.CapturePicker", "Microsoft.Windows.CloudExperienceHost", "Microsoft.Windows.ContentDeliveryManager", "Microsoft.Windows.DevicesFlowHosts", "Microsoft.Windows.ModalSharePickerHost", "Microsoft.Windows.NarratorQuickStart", "Microsoft.Windows.OOBENetworkCaptivePortal", "Microsoft.Windows.OOBENetworkConnectionFlow", "Microsoft.Windows.ParentalControls", "Microsoft.Windows.PeopleExperienceHost", "Microsoft.Windows.Photos", "Microsoft.Windows.PinningConfirmationDialog", "Microsoft.Windows.PrintQueueActionCenter", "Microsoft.Windows.SecureAssessmentBrowser", "Microsoft.Windows.ShellExperienceHost", "Microsoft.Windows.StartMenuExperienceHost", "Microsoft.Windows.XGpuEjectDialog", "Microsoft.WindowsAlarms", "Microsoft.WindowsAppRuntime.", "Microsoft.WindowsCalculator", "Microsoft.WindowsCamera", "Microsoft.WindowsNotepad", "Microsoft.WindowsStore", "Microsoft.WindowsTerminal", "Microsoft.Winget.Source", "Microsoft.XboxGameCallableUI", "MicrosoftCorporationII.QuickAssist", "MicrosoftWindows.Client.CBS", "MicrosoftWindows.Client.Core", "MicrosoftWindows.Client.FileExp", "MicrosoftWindows.Client.WebExperience", "MicrosoftWindows.UndockedDevKit", "MixedRealityLearning", "NcsiUwpApp", "NVIDIACorp.NVIDIAControlPanel", "Ookla.SpeedtestbyOokla", "Passthrough", "RealtekSemiconductorCorp.RealtekAudioControl", "RoomAdjustment", "WavesAudio.MaxxAudioPro", "WebAuthBridgeInternet", "WebAuthBridgeInternetSso", "WebAuthBridgeIntranetSso", "WhatsNew", "Windows.CBSPreview", "windows.immersivecontrolpanel", "Windows.PrintDialog"); 

[System.Collections.ArrayList]$blacklist = @(Get-AppxPackage | Select-Object -ExpandProperty Name | Select-String -Pattern $whitelist -NotMatch | ForEach-Object -Process {"`n$_"});

Switch ($whitelist)

{
    {(Get-AppxPackage).Name | Select-String -Pattern $whitelist -NotMatch} {Write-Host "$_"}
}





























