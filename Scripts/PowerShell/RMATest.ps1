using namespace System.Collections;
using namespace System.Collections.Generic;
using namespace System.Management.Automation;

#*================================================================================
# Copyright © 2025, Metro-Tech. All rights reserved.
# Remove Metro Apps v2.02
# ================================================================================
# Functions
# 	Prompt-Host
# 	Set-ConsoleColor
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

		$private:Choices = [ObjectModel.Collection[Host.ChoiceDescription]]@(
				[Host.ChoiceDescription]::new([string]"&$LabelA", [string]"$HelpA")
				[Host.ChoiceDescription]::new([string]"&$LabelB", [string]"$HelpB"));

	$Host.UI.PromptForChoice($Caption, $Message, $Choices, $DefaultChoice);
}

function private:Set-ConsoleColor
{
	param ([Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("BackgroundColor", "ForegroundColor")]
		[string]$Layer,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan",
		"DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
		"Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
		[string]$Color)

	[Console]::$Layer = "$Color";
}

$Host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Name;

if ($PSStyle -ne $null)
{
	$PSStyle.Progress.View = 'Classic';
}

$AppxWhitelist = [List[string]]@(
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

$AppxBlacklist = [List[object]]@((Get-AppxPackage -AllUsers).Where({$_.Name -notin $AppxWhitelist -and $_.IsFramework -eq $false -and $_.NonRemovable -eq $false}));
$AppxProvisionedBlacklist = [List[object]]@((Get-AppxProvisionedPackage -Online).Where({$_.DisplayName -notin $AppxWhitelist}));
