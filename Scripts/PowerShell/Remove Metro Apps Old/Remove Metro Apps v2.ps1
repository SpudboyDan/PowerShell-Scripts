function Query-Removal
{
	param ([Parameter(Mandatory = $true, Position = 0)] 
		[ValidatePattern('^yes$|^no$|^y$|^n$')]
		[string]$PromptUser)
	$PromptUser
}

$AppxBlacklist = [System.Collections.Generic.List[string]]::new();
$AppxCombinedBlacklist = [System.Collections.Generic.List[string]]::new();
$AppxPackages = [System.Collections.Generic.List[string]]@((Get-AppxPackage -AllUsers | Where-Object -FilterScript {$_.IsFramework -eq $false -and $_.NonRemovable -eq $false}).Name);
$AppxProvisionedBlacklist = [System.Collections.Generic.List[string]]::new();
$AppxProvisionedPackages = [System.Collections.Generic.List[string]]@((Get-AppxProvisionedPackage -Online).DisplayName);
$AppxCombinedFullNames = [System.Collections.Generic.List[string]]::new();
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

[System.Console]::ResetColor();
[System.Console]::ForegroundColor = "Cyan";
Clear-Host;

switch ($AppxProvisionedPackages)
{
	{$AppxWhitelist -notcontains $_} {$AppxProvisionedBlacklist.Add($_);}
}

switch ($AppxPackages)
{
	{$AppxWhitelist -notcontains $_} {
	$AppxBlacklist.Add($_);
	$AppxCombinedBlacklist.Add($_);}
}

switch ($AppxProvisionedBlacklist)
{
	{$AppxCombinedBlacklist -notcontains $_} {$AppxCombinedBlacklist.Add($_);}
}

$AppxCombinedBlacklist.Sort();

try {
	while ((Query-Removal -PromptUser (Read-Host -Prompt "`nThe following apps will be removed:`n`n$($AppxCombinedBlacklist -join "`n")`n`nAre you sure? (Y/N)")) -match '^no$|^n$')
	{
		:NotMatchBlacklist switch ((Read-Host -Prompt "Please add any apps that you do not want removed (case sensitive):`n"))
		{
			{$AppxCombinedBlacklist -ccontains $_} {$AppxCombinedBlacklist.Remove($_);
			Clear-Host;
			Continue;}
	
			{$AppxCombinedBlacklist -cnotcontains $_} {
			Write-Host -ForegroundColor Yellow "'$_' does not match the name of any known application, or it might not be targeted for removal already. Press enter to continue...";
			[System.Console]::ReadLine();
			Clear-Host;
			Break NotMatchBlacklist;}
		}
	}
}

catch {
	throw "Invalid input! Acceptable values are 'yes', 'no', 'y', and 'n' (case insensitive)";
}

foreach ($App in $AppxCombinedBlacklist)
{
	$AppxCombinedFullNames.Add((Get-AppxPackage -AllUsers -Name $App).PackageFullname);
}

Clear-Host;
[System.Console]::ForegroundColor = "DarkYellow";
$Counter = 0;
$PercentCounter = 0;

foreach ($App in $AppxCombinedFullNames)
{
		$Status = "$App";
		Write-Progress -Activity "Removing Provisioned Apps $([System.Math]::Round(($PercentCounter++/$AppxCombinedFullNames.Count)*100))%" -Status $Status -PercentComplete (($Counter++/$AppxCombinedFullNames.Count)*100);
		Start-Sleep -Seconds 0.5;
}

$Counter = 0;
$PercentCounter = 0;

foreach ($App in $AppxCombinedFullNames)
{
		$Status = "$App";
		Write-Progress -Activity "Removing Apps $([System.Math]::Round(($PercentCounter++/$AppxCombinedFullNames.Count)*100))%" -Status $Status -PercentComplete (($Counter++/$AppxCombinedFullNames.Count)*100);
		Start-Sleep -Seconds 0.5;
}
