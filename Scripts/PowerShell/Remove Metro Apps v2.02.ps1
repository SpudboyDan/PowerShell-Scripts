function Verify-Input
{
	param ([Parameter(Mandatory = $true, Position = 0)] 
		[ValidatePattern('^yes$|^no$|^y$|^n$')]
		[string]$PromptUser)
	$PromptUser
}

function Set-ConsoleColor
{
	param ([Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("BackgroundColor", "ForegroundColor")]
		[string]$Layer,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan",
		"DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
		"Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
		[string]$Color)

	[System.Console]::Clear();
	[System.Console]::ResetColor();
	[System.Console]::$Layer = "$Color";
}

$AppxWhitelist = [System.Collections.Generic.List[string]]@(
	"1527c705-839a-4832-9118-54d4Bd6a0c89",
	"c5e2524a-ea46-4f67-841f-6a9465d9d515",
	"E2A4F912-2574-4A75-9BB0-0D023378592B",
	"F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE",
	"Microsoft.AAD.BrokerPlugin",
	"Microsoft.AccountsControl",
	"Microsoft.ApplicationCompatibilityEnhancements",
	"Microsoft.AsyncTextService",
	"Microsoft.AV1VideoExtension",
	"Microsoft.AVCEncoderVideoExtension",
	"Microsoft.BingSearch",
	"Microsoft.BingWeather",
	"Microsoft.BioEnrollment",
	"Microsoft.CredDialogHost",
	"Microsoft.DesktopAppInstaller",
	"Microsoft.ECApp",
	"Microsoft.HEIFImageExtension",
	"Microsoft.HEVCVideoExtension",
	"Microsoft.LockApp",
	"Microsoft.MicrosoftEdge.Stable",
	"Microsoft.MicrosoftEdgeDevToolsClient",
	"Microsoft.MicrosoftStickyNotes",
	"Microsoft.MPEG2VideoExtension",
	"Microsoft.OfficePushNotificationUtility",
	"Microsoft.OneDriveSync"
	"Microsoft.Paint",
	"Microsoft.RawImageExtension",
	"Microsoft.ScreenSketch",
	"Microsoft.SecHealthUI",
	"Microsoft.Services.Store.Engagement",
	"Microsoft.StorePurchaseApp",
	"Microsoft.VP9VideoExtensions",
	"Microsoft.WebMediaExtensions",
	"Microsoft.WebpImageExtension",
	"Microsoft.WidgetsPlatformRuntime",
	"Microsoft.Win32WebViewHost",
	"Microsoft.Windows.Apprep.ChxApp",
	"Microsoft.Windows.AssignedAccessLockApp",
	"Microsoft.Windows.AugLoop.CBS",
	"Microsoft.Windows.CapturePicker",
	"Microsoft.Windows.CloudExperienceHost",
	"Microsoft.Windows.ContentDeliveryManager",
	"Microsoft.Windows.NarratorQuickStart",
	"Microsoft.Windows.OOBENetworkCaptivePortal",
	"Microsoft.Windows.OOBENetworkConnectionFlow",
	"Microsoft.Windows.ParentalControls",
	"Microsoft.Windows.PeopleExperienceHost",
	"Microsoft.Windows.Photos",
	"Microsoft.Windows.PinningConfirmationDialog",
	"Microsoft.Windows.PrintQueueActionCenter",
	"Microsoft.Windows.SecureAssessmentBrowser",
	"Microsoft.Windows.ShellExperienceHost",
	"Microsoft.Windows.StartMenuExperienceHost",
	"Microsoft.Windows.XGpuEjectDialog",
	"Microsoft.Winget.Source",
	"Microsoft.WindowsAlarms",
	"Microsoft.WindowsCalculator",
	"Microsoft.WindowsCamera",
	"Microsoft.WindowsNotepad",
	"Microsoft.WindowsSoundRecorder",
	"Microsoft.WindowsStore",
	"Microsoft.WindowsTerminal",
	"Microsoft.XboxGameCallableUI",
	"MicrosoftCorporationII.QuickAssist",
	"MicrosoftWindows.Client.WebExperience",
	"MicrosoftWindows.CrossDevice",
	"MicrosoftWindows.UndockedDevKit",
	"NcsiUwpApp",
	"NVIDIACorp.NVIDIAControlPanel",
	"RealtekSemiconductorCorp.RealtekAudioControl",
	"Windows.CBSPreview",
	"windows.immersivecontrolpanel",
	"Windows.PrintDialog");

$AppxBlacklist = [System.Collections.Generic.List[object]]@((Get-AppxPackage -AllUsers).Where($_.Name -notin $AppxWhitelist -and $_.IsFramework -eq $false -and $_.NonRemovable -eq $false));
$AppxProvisionedBlacklist = [System.Collections.Generic.List[object]]@((Get-AppxProvisionedPackage -Online).Where($_.DisplayName -notin $AppxWhitelist);

try {
	Set-ConsoleColor -Layer ForegroundColor -Color Cyan;
	while ((Verify-Input -PromptUser (Read-Host -Prompt "`nThe following apps will be removed from provisioning:`n`n$($AppxProvisionedBlacklist.DisplayName -join "`n")`n`nAre you sure? (Y/N)")) -match '^no$|^n$')
	{
		:NotMatchBlacklist switch ($answer = (Read-Host -Prompt "Please add any apps that you do not want removed from provisioning (case sensitive):`n")) 
		{
			{$Answer -in ($AppxProvisionedBlacklist.DisplayName)} {$AppxProvisionedBlacklist.Remove($AppxProvisionedPackage[[array]::IndexOf($AppxProvisionedPackage.DisplayName,$Answer)]);
			Set-ConsoleColor -Layer ForegroundColor -Color Cyan;
			Continue;}

			{$Answer -notin ($AppxProvisionedBlacklist.DisplayName)} {
			Write-Host -ForegroundColor Yellow "'$Answer' does not match the name of any known application, or it might not be targeted for removal already. Press enter to continue..."
			[System.Console]::ReadLine();
			Set-ConsoleColor -Layer ForegroundColor -Color Cyan;
			Break NotMatchBlacklist;}
		}
	}
}

catch
{
	throw "Invalid input! Acceptable values are 'yes', 'no', 'y', or 'n'.";
}
