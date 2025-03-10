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

	[System.Console]::$Layer = "$Color";
}

$Host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Name;
$Error.Clear();

if ($PSStyle -ne $null)
{
	$PSStyle.Progress.View = 'Classic';
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

$AppxBlacklist = [System.Collections.Generic.List[object]]@((Get-AppxPackage -AllUsers).Where({$_.Name -notin $AppxWhitelist -and $_.IsFramework -eq $false -and $_.NonRemovable -eq $false}));
$AppxProvisionedBlacklist = [System.Collections.Generic.List[object]]@((Get-AppxProvisionedPackage -Online).Where({$_.DisplayName -notin $AppxWhitelist}));

try {
	[System.Console]::Clear();
	Set-ConsoleColor -Layer ForegroundColor -Color Cyan;
	while ((Verify-Input -PromptUser (Read-Host -Prompt "The following apps will be removed from provisioning:`n`n$(($AppxProvisionedBlacklist.DisplayName) -join "`n")`n`nAre you sure?`n[Y] Yes [N] No")) -match '^no$|^n$')
	{
		:NotMatchBlacklist switch ($Answer = Read-Host -Prompt "Please add any apps that you do not want removed from provisioning (case sensitive):`n") 
		{
			{$Answer -in ($AppxProvisionedBlacklist.DisplayName) -and $Answer -in ($AppxBlacklist.Name)} {
			$null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, $Answer));
			$null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, $Answer));
			[System.Console]::Clear();
			Continue;}

			{$Answer -in ($AppxProvisionedBlacklist.DisplayName)} {$null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, $Answer));
			[System.Console]::Clear();
			Continue;}

			{$Answer -notin ($AppxProvisionedBlacklist.DisplayName)} {
			Write-Host -ForegroundColor Yellow "'$Answer' does not match the name of any known applications, or it might not be targeted for removal already. Press enter to continue...";
			[System.Console]::ReadLine();
			[System.Console]::Clear();
			Break NotMatchBlacklist;}
		}
	}
}

catch
{
	throw $Error;
}

try {
	[System.Console]::Clear();
	Set-ConsoleColor -Layer ForegroundColor -Color Cyan;
	while ((Verify-Input -PromptUser (Read-Host -Prompt "The following apps will be removed:`n`n$(($AppxBlacklist.Name) -join "`n")`n`nAre you sure?`n[Y] Yes [N] No")) -match '^no$|^n$')
	{
		:NotMatchBlacklist switch ($Answer = Read-Host -Prompt "Please add any apps that you do not want removed (case sensitive):`n")
		{
			{$Answer -in ($AppxBlacklist.Name) -and $Answer -in ($AppxProvisionedBlacklist.DisplayName)} {
			$null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, $Answer));
			$null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, $Answer));
			[System.Console]::Clear();
			Continue;}

			{$Answer -in ($AppxBlacklist.Name)} {$null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, $Answer));
			[System.Console]::Clear();
			Continue;}

			{$Answer -notin ($AppxBlacklist.Name)} {
			Write-Host -ForegroundColor Yellow "'$Answer' does not match the name of any known applications, or it might not be targeted for removal already. Press enter to continue...";
			[System.Console]::ReadLine();
			[System.Console]::Clear();
			Break NotMatchBlacklist;}
		}
	}
}

catch
{
	throw $Error;
}

[System.Console]::Clear();
$Counter = 0;
$PercentCounter = 0;

foreach ($App in $AppxProvisionedBlacklist)
{
	$PaddingLength = [System.Math]::Round(([System.Console]::BufferWidth - $App.DisplayName.Length)/2, [System.MidpointRounding]::ToZero);
	$RemovalStatus = "Removing Provisioned Apps $([System.Math]::Round(($PercentCounter++/$AppxProvisionedBlacklist.Count)*100))%";
	$AppNameActivity = "$($App.DisplayName.PadLeft($PaddingLength + $App.DisplayName.Length, 0x0020))";
	Write-Progress -Activity $AppNameActivity -Status $RemovalStatus -PercentComplete (($Counter++/$AppxProvisionedBlacklist.Count)*100);
	Start-Sleep -Seconds 1;
	<#
	$null = Remove-AppxProvisionedPackage -PackageName $App.PackageName -AllUsers -Online;
	#>
}

$Counter = 0;
$PercentCounter = 0;

foreach ($App in $AppxBlacklist)
{
	$PaddingLength = [System.Math]::Round(([System.Console]::BufferWidth - $App.Name.Length)/2, [System.MidpointRounding]::ToZero);
	$RemovalStatus = "Removing Apps $([System.Math]::Round(($PercentCounter++/$AppxBlacklist.Count)*100))%";
	$AppNameActivity = "$($App.Name.PadLeft($PaddingLength + $App.Name.Length, 0x0020))";
	Write-Progress -Activity $AppNameActivity -Status $RemovalStatus -PercentComplete (($Counter++/$AppxBlacklist.Count)*100);
	Start-Sleep -Seconds 1;
	<#
	$null = Remove-AppxPackage -Package $App.PackageFullName -AllUsers;
	#>
}
