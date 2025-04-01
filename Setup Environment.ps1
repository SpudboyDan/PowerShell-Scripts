#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Profile setup and utilities
# ================================================================================
# Functions
#	Get-ASVideo
#	Get-AteraAgent
#	Find-DuplicateFile
# 	Invoke-AteraApi
# 	Write-Version
# 	Set-ConsoleColor
# 	Set-Keybind
#
# Load dependencies
# ================================================================================
Import-Module -Global -Name Microsoft.PowerShell.Utility;
. "$PSScriptRoot\Modules\Find-DuplicateFile.ps1";
. "$PSScriptRoot\Modules\Invoke-AteraApi.ps1";
#*================================================================================
function Get-ASVideo {
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

function Get-AteraAgent {
	param ([parameter(Mandatory = $true, Position = 0)]
		[string]$Key,
		[parameter(Mandatory = $false, Position = 1)]
		[int]$PageNumber = 1,
		[parameter(Mandatory = $false, Position = 2)]
		[int]$ItemAmount = 20,
		[parameter(Mandatory = $false, Position = 3)]
		[switch]$All)

	switch ($All) {
		$true	{[int]$Pages = (Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents?page=1&itemsInPage=50"`
		-Headers @{
						"method"="GET"
						"scheme"="https"
  						"accept"="application/json;charset=utf-8,*/*"
  						"accept-encoding"="gzip, deflate, br, zstd"
  						"accept-language"="en-US,en;q=0.9"
  						"x-api-key"="$Key"}).totalPages;
				for ($i = 1; $i -le $Pages; $i++) {
					(Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents?page=$i&itemsInPage=50"`
					-Headers @{
						"method"="GET"
						"scheme"="https"
  						"accept"="application/json;charset=utf-8,*/*"
  						"accept-encoding"="gzip, deflate, br, zstd"
  						"accept-language"="en-US,en;q=0.9"
  						"x-api-key"="$Key"}).items}
			}

		$false	{(Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents?page=$PageNumber&itemsInPage=$ItemAmount"`
		-Headers @{
				"method"="GET"
				"scheme"="https"
  				"accept"="application/json;charset=utf-8,*/*"
  				"accept-encoding"="gzip, deflate, br, zstd"
  				"accept-language"="en-US,en;q=0.9"
  				"x-api-key"="$Key"}).items
			}
	}
}

function Write-Version {
  	$HostVersion = "$($Host.Version.Major)`.$($Host.Version.Minor)";
	$Host.UI.RawUI.WindowTitle = "PowerShell $HostVersion";
}

function Set-Keybind {
	Set-PSReadLineKeyHandler -Chord Shift+F1 -Function ForwardChar;
	Set-PSReadLineKeyHandler -Chord Shift+F2 -Function ForwardWord;
}

