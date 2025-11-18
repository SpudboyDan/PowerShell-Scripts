#*================================================================================
# Remove Metro Apps v2.02
# ================================================================================
# Functions
# 	Write-Prompt
#*================================================================================
function private:Write-Prompt {
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

    $private:Choices = [Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]]@(
        [Management.Automation.Host.ChoiceDescription]::new([string]"&$LabelA", [string]"$HelpA")
        [Management.Automation.Host.ChoiceDescription]::new([string]"&$LabelB", [string]"$HelpB"));

    $Host.UI.PromptForChoice($Caption, $Message, $Choices, $DefaultChoice);
}

$Host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Name;

if ($null -ne $PSStyle) {
    $PSStyle.Progress.View = 'Classic';
}

$AppxWhitelist = [Collections.Generic.List[string]]@(
    "Microsoft.ApplicationCompatibilityEnhancements",
    "Microsoft.AV1VideoExtension",
    "Microsoft.AVCEncoderVideoExtension",
    "Microsoft.BingSearch",
    "Microsoft.BingWeather",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.HEIFImageExtension",
    "Microsoft.HEVCVideoExtension",
    "Microsoft.Ink.Handwriting.Main.en-US.1.0.1",
    "Microsoft.MicrosoftEdge.Stable",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MPEG2VideoExtension",
    "Microsoft.MSPaint",
    "Microsoft.OfficePushNotificationUtility",
    "Microsoft.OneDriveSync",
    "Microsoft.Paint",
    "Microsoft.RawImageExtension",
    "Microsoft.ScreenSketch",
    "Microsoft.SecHealthUI",
    "Microsoft.StorePurchaseApp",
    "Microsoft.VCLibs.140.00",
    "Microsoft.VP9VideoExtensions",
    "Microsoft.WebMediaExtensions",
    "Microsoft.WebpImageExtension",
    "Microsoft.WidgetsPlatformRuntime",
    "Microsoft.WinAppRuntime.DDLM.5001.311.2039.0-x6",
    "Microsoft.WinAppRuntime.DDLM.5001.311.2039.0-x8",
    "Microsoft.WinAppRuntime.DDLM.8000.642.119.0-x6"
    "Microsoft.WinAppRuntime.DDLM.8000.642.119.0-x8"
    "Microsoft.Windows.Photos",
    "Microsoft.Winget.Source",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsNotepad",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.WindowsStore",
    "Microsoft.WindowsTerminal",
    "MicrosoftCorporationII.QuickAssist",
    "MicrosoftCorporationII.WinAppRuntime.Main.1.5",
    "MicrosoftCorporationII.WinAppRuntime.Main.1.8"
    "MicrosoftCorporationII.WinAppRuntime.Singleton",
    "MicrosoftWindows.Client.WebExperience",
    "MicrosoftWindows.CrossDevice",
    "NcsiUwpApp",
    "NVIDIACorp.NVIDIAControlPanel",
    "RealtekSemiconductorCorp.RealtekAudioControl");

$AppxBlacklist = [Collections.Generic.List[object]]@((Get-AppxPackage -AllUsers).Where({`
                $_.Name -notin $AppxWhitelist -and $_.IsFramework -eq $false -and $_.NonRemovable -eq $false }));

$AppxProvisionedBlacklist = [Collections.Generic.List[object]]@((Get-AppxProvisionedPackage -Online).Where({`
                $_.DisplayName -notin $AppxWhitelist }));

# Splatting for Write-Prompt function options
$WritePromptParams = @{
    Message = "`nAre you sure?";
    LabelA  = "Yes";
    HelpA   = "Remove apps";
    LabelB  = "No";
    HelpB   = "Do not remove apps";
}

<# Writes a prompt to show all provisioned apps and then finds and removes any apps that the user specifies 
until the Write-Prompt function produces an output not equal to 1 (1 is assigned to "No") #>
try {
    [System.Console]::Clear();
    [System.Console]::ForegroundColor = 'Cyan';
    while ((Write-Prompt -Caption "The following provisioned apps will be removed:`n`n$(([string[]]$AppxProvisionedBlacklist.DisplayName) -join "`n")" @WritePromptParams) -eq 1) {
        :NotMatchBlacklist switch ($Answer = Read-Host -Prompt "`nPlease add any provisioned apps you do not want removed") {
            { $Answer -in ($AppxProvisionedBlacklist.DisplayName) -and $Answer -in ($AppxBlacklist.Name) } {
                $null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, ($AppxProvisionedBlacklist.DisplayName -match $Answer)[0]));
                $null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, ($AppxBlacklist.Name -match $Answer)[0]));
                [System.Console]::Clear();
                continue;
            }

            { $Answer -in ($AppxProvisionedBlacklist.DisplayName) } {
                $null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, ($AppxProvisionedBlacklist.DisplayName -match $Answer)[0]));
                [System.Console]::Clear();
                continue;
            }

            { $Answer -notin ($AppxProvisionedBlacklist.DisplayName) } {
                Write-Host -ForegroundColor Yellow "'$Answer' does not match the name of any apps. It might not be targeted for removal already. Press enter to continue...";
                [Console]::ReadLine();
                [Console]::Clear();
                break NotMatchBlacklist;
            }
        }
    }
}

catch {
    throw $Error;
}

try {
    [Console]::Clear();
    [Console]::ForegroundColor = 'Cyan';
    while ((Write-Prompt -Caption "The following apps will be removed:`n`n$(([Collections.Generic.SortedSet[string]]$AppxBlacklist.Name) -join "`n")" @WritePromptParams) -eq 1) {
        :NotMatchBlacklist switch ($Answer = Read-Host -Prompt "`nPlease add any apps you do not want removed") {
            { $Answer -in ($AppxBlacklist.Name) -and $Answer -in ($AppxProvisionedBlacklist.DisplayName) } {
                $null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, ($AppxBlacklist.Name -match $Answer)[0]));
                $null = $AppxProvisionedBlacklist.RemoveAt([array]::IndexOf($AppxProvisionedBlacklist.DisplayName, ($AppxProvisionedBlacklist.DisplayName -match $Answer)[0]));
                [Console]::Clear();
                continue;
            }

            { $Answer -in ($AppxBlacklist.Name) } {
                $null = $AppxBlacklist.RemoveAt([array]::IndexOf($AppxBlacklist.Name, ($AppxBlacklist.Name -match $Answer)[0]));
                [Console]::Clear();
                continue;
            }

            { $Answer -notin ($AppxBlacklist.Name) } {
                Write-Host -ForegroundColor Yellow "'$Answer' does not match the name of any apps. It might not be targeted for removal already. Press enter to continue...";
                [Console]::ReadLine();
                [Console]::Clear();
                break NotMatchBlacklist;
            }
        }
    }
}

catch {
    throw $Error;
}

[Console]::Clear();
$Counter = 0;
$PercentCounter = 0;

foreach ($App in $AppxProvisionedBlacklist) {
    $PaddingLength = [Math]::Floor(([Console]::BufferWidth - $App.DisplayName.Length) / 2);
    $RemovalStatus = "Removing Provisioned Apps $([Math]::Floor(($PercentCounter++/$AppxProvisionedBlacklist.Count)*100))%";
    $AppNameActivity = "$($App.DisplayName.PadLeft($PaddingLength + $App.DisplayName.Length, 0x0020))";
    Write-Progress -Activity $AppNameActivity -Status $RemovalStatus -PercentComplete (($Counter++ / $AppxProvisionedBlacklist.Count) * 100);
    Start-Sleep -Seconds 1;
    $null = Remove-AppxProvisionedPackage -PackageName $App.PackageName -AllUsers -Online;
}

$Counter = 0;
$PercentCounter = 0;

foreach ($App in $AppxBlacklist) {
    $PaddingLength = [Math]::Floor(([Console]::BufferWidth - $App.Name.Length) / 2);
    $RemovalStatus = "Removing Apps $([Math]::Floor(($PercentCounter++/$AppxBlacklist.Count)*100))%";
    $AppNameActivity = "$($App.Name.PadLeft($PaddingLength + $App.Name.Length, 0x0020))";
    Write-Progress -Activity $AppNameActivity -Status $RemovalStatus -PercentComplete (($Counter++ / $AppxBlacklist.Count) * 100);
    Start-Sleep -Seconds 1;
    $null = Remove-AppxPackage -Package $App.PackageFullName -AllUsers;
}
