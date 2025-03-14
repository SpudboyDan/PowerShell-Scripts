#*================================================================================
# Copyright © 2025, Metro-Tech. All rights reserved.
# Remove Metro Apps v2.02
# ================================================================================
# Functions
# 	Prompt-Host
#*================================================================================
function private:Prompt-Host
{
	param([Parameter(Mandatory = $true, Position = 0)]
		[string]$Caption,
		[Parameter(Mandatory = $true, Position = 1)]
		[string]$Message,
		[Parameter(Mandatory = $true, Position = 2)]
		[string]$LabelA,
		[Parameter(Mandatory = $false, Position = 3)]
		[string]$HelpA,
		[Parameter(Mandatory = $true, Position = 4)]
		[string]$LabelB,
		[Parameter(Mandatory = $false, Position = 5)]
		[string]$HelpB,
		[Parameter(Mandatory = $false, Position = 6)]
		[int]$DefaultChoice = (-1))

		$private:Choices = [System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]]@(
				[System.Management.Automation.Host.ChoiceDescription]::new([string]"&$LabelA", [string]"$HelpA")
				[System.Management.Automation.Host.ChoiceDescription]::new([string]"&$LabelB", [string]"$HelpB"));

	$Host.UI.PromptForChoice($Caption, $Message, $Choices, $DefaultChoice);
}

$Host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Name;

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
	"Microsoft.Ink.Handwriting.Main.en-US.1.0.1",
	"Microsoft.LockApp",
	"Microsoft.MicrosoftEdge.Stable",
	"Microsoft.MicrosoftEdgeDevToolsClient",
	"Microsoft.MicrosoftStickyNotes",
	"Microsoft.MPEG2VideoExtension",
	"Microsoft.OfficePushNotificationUtility",
	"Microsoft.OneDriveSync",
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
$PromptHostParams = @{
	Message = "`nAre you sure?";
	LabelA = "Yes";
	HelpA = "Remove apps";
	LabelB = "No";
	HelpB = "Do not remove apps";}

try {
	[System.Console]::Clear();
	[System.Console]::ForegroundColor = 'Cyan';
	while ((Prompt-Host -Caption "The following provisioned apps will be removed:`n`n$(([string[]]$AppxProvisionedBlacklist.DisplayName) -join "`n")" @PromptHostParams) -eq 1)
	
	{
		:NotMatchBlacklist switch ($Answer = Read-Host -Prompt "`nPlease add any provisioned apps you do not want removed") 
		{
			{$Answer -in ($AppxProvisionedBlacklist.DisplayName) -and $Answer -in ($AppxBlacklist.Name)} {
			$null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, ($AppxProvisionedBlacklist.DisplayName -match $Answer)[0]));
			$null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, ($AppxBlacklist.Name -match $Answer)[0]));
			[System.Console]::Clear();
			continue;}

			{$Answer -in ($AppxProvisionedBlacklist.DisplayName)} {
			$null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, ($AppxProvisionedBlacklist.DisplayName -match $Answer)[0]));
			[System.Console]::Clear();
			continue;}

			{$Answer -notin ($AppxProvisionedBlacklist.DisplayName)} {
			Write-Host -ForegroundColor Yellow "'$Answer' does not match the name of any apps. It might not be targeted for removal already. Press enter to continue...";
			[System.Console]::ReadLine();
			[System.Console]::Clear();
			break NotMatchBlacklist;}
		}
	}
}

catch {
	throw $Error;
}

try {
	[System.Console]::Clear();
	[System.Console]::ForegroundColor = 'Cyan';
	while ((Prompt-Host -Caption "The following apps will be removed:`n`n$(([System.Collections.Generic.SortedSet[string]]$AppxBlacklist.Name) -join "`n")" @PromptHostParams) -eq 1)
	{
		:NotMatchBlacklist switch ($Answer = Read-Host -Prompt "`nPlease add any apps you do not want removed")
		{
			{$Answer -in ($AppxBlacklist.Name) -and $Answer -in ($AppxProvisionedBlacklist.DisplayName)} {
			$null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, ($AppxBlacklist.Name -match $Answer)[0]));
			$null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, ($AppxProvisionedBlacklist.DisplayName -match $Answer)[0]));
			[System.Console]::Clear();
			continue;}

			{$Answer -in ($AppxBlacklist.Name)} {
			$null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, ($AppxBlacklist.Name -match $Answer)[0]));
			[System.Console]::Clear();
			continue;}

			{$Answer -notin ($AppxBlacklist.Name)} {
			Write-Host -ForegroundColor Yellow "'$Answer' does not match the name of any apps. It might not be targeted for removal already. Press enter to continue...";
			[System.Console]::ReadLine();
			[System.Console]::Clear();
			break NotMatchBlacklist;}
		}
	}
}

catch {
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
