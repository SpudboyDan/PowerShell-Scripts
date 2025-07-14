#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Profile setup and utilities
# ================================================================================
# Functions
#	Find-DuplicateFile
#	Get-AdultSwimVideo
#	Get-AteraAgent
#	Get-AteraCustomer
#	Get-KHInsiderMP3
#	New-StartShortcut
# 	Set-Keybind
# 	Write-Version
#
# Load dependencies
# ================================================================================
Import-Module -Global -Name Microsoft.PowerShell.Utility;
. "$PSScriptRoot\Modules\Find-DuplicateFile.ps1";
. "$PSScriptRoot\Modules\Get-AteraAgent.ps1";
. "$PSScriptRoot\Modules\Get-AteraCustomer.ps1";
. "$PSScriptRoot\Modules\Get-KHInsiderMP3.ps1";
. "$PSScriptRoot\Modules\New-StartShortcut.ps1";
#*================================================================================
function Get-AdultSwimVideo {
	param ([Parameter(Mandatory = $true, Position = 0)] [string]$Uri)
	try {
		$Links = (Invoke-WebRequest -Uri $Uri).Links.Href |
		Select-String -Pattern ("$($Uri.Replace('https://www.adultswim.com',''))" + "/[a-z0-9\-]+")
		foreach ($Link in $Links) {
			yt-dlp "https://www.adultswim.com$Link"
		}
	}
	catch {
		$PSCmdlet.ThrowTerminatingError($PSItem);
	}
}

function Set-Keybind {
	Set-PSReadLineKeyHandler -Chord Shift+F1 -Function ForwardChar;
	Set-PSReadLineKeyHandler -Chord Shift+F2 -Function ForwardWord;
}

function Write-Version {
  	$HostVersion = "$($Host.Version.Major)`.$($Host.Version.Minor)";
	$Host.UI.RawUI.WindowTitle = "PowerShell $HostVersion";
}
