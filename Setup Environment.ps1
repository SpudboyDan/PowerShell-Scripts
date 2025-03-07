#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Profile setup and utilities
# ================================================================================
# Functions
#	Download-AdultSwim
# 	Get-Duplicates
# 	Get-DuplicatesFast
# 	Get-DuplicatesFaster
# 	Get-DuplicatesFastest
# 	Play-Song
# 	Print-Version
# 	Set-ConsoleColor
# 	Set-Keybinds
#*================================================================================
function Download-AdultSwim
	{
		param ([Parameter(Mandatory = $true, Position = 0)] [string]$Uri)

		try
		{
			$Links = (Invoke-WebRequest -Uri $Uri).Links.Href | Select-String -Pattern ("$($Uri.Replace('https://www.adultswim.com',''))" + "/[a-z0-9\-]+")
			foreach ($Link in $Links)
			{
				yt-dlp "https://www.adultswim.com$Link"
			}
		}

		catch
		{
			$PSCmdlet.ThrowTerminatingError($PSItem)
		}
	}

function Get-Duplicates 
	{
		param ([switch]$Recurse)

		switch ($Recurse)
		{
			$true	{Get-ChildItem -File -Recurse | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Get-FileHash | `
				Group-Object -Property Hash | Where-Object {$_.Count -gt 1} | `
				foreach {$_.Group} | Select-Object -Property Path,Hash | `
				Format-Table -GroupBy Hash -RepeatHeader | Out-Host -Paging}

			$false 	{Get-ChildItem -File | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Get-FileHash | `
				Group-Object -Property Hash | Where-Object {$_.Count -gt 1} | `
				foreach {$_.Group} | Select-Object -Property Path,Hash | `
				Format-Table -GroupBy Hash -RepeatHeader | Out-Host -Paging}
		}
	}

function Get-DuplicatesFast 
	{
		param ([switch]$Recurse)

		switch ($Recurse)
		{
			$true	{Get-ChildItem -File -Recurse | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Get-FileHash | `
				Group-Object -Property Hash | Where-Object {$_.Count -gt 1} | `
				foreach {$_.Group}}

			$false	{Get-ChildItem -File | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Get-FileHash | `
				Group-Object -Property Hash | Where-Object {$_.Count -gt 1} | `
				foreach {$_.Group}}
		}
	}

function Get-Duplicatesv2
{
	param ([switch]$Recurse)
	
	switch ($Recurse)
	{
		$true {$Properties = @{RecurseSubdirectories = [bool]1; IgnoreInaccessible = [bool]1;}
		$EnumerationOptions = New-Object -TypeName System.IO.EnumerationOptions -Property $Properties;
		$Directory = [System.Collections.Generic.List[System.IO.FileInfo]]@([System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*', $EnumerationOptions));
		[Func[System.IO.FileInfo,int64]]$InnerDelegate = {$args[0].Length}
		[Func[System.IO.FileInfo,string]]$OuterDelegate = {$args[0].FullName}
		[System.Linq.Enumerable]::GroupBy($Directory, $InnerDelegate, $OuterDelegate);}

		$false {$Properties = @{RecurseSubdirectories = [bool]0; IgnoreInaccessible = [bool]1;}
		$EnumerationOptions = New-Object -TypeName System.IO.EnumerationOptions -Property $Properties;
		$Directory = [System.Collections.Generic.List[System.IO.FileInfo]]@([System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*', $EnumerationOptions));
		[Func[System.IO.FileInfo,int64]]$InnerDelegate = {$args[0].Length}
		[Func[System.IO.FileInfo,string]]$OuterDelegate = {$args[0].FullName}
		[System.Linq.Enumerable]::GroupBy($Directory, $InnerDelegate, $OuterDelegate);}
	}
}

function Get-DuplicatesFaster 
	{
		param ([switch]$Recurse)

		switch ($Recurse)
		{
			$true	{Get-ChildItem -File -Recurse | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | `
				Select-Object -Property Directory,BaseName | `
				Format-Table -GroupBy Directory -RepeatHeader | Out-Host -Paging}

			$false	{Get-ChildItem -File | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | `
				Select-Object -Property Directory,BaseName | `
				Format-Table -GroupBy Directory -RepeatHeader | Out-Host -Paging}
		}
	}

function Get-DuplicatesFastest 
	{
		param ([switch]$Recurse)

		switch ($Recurse)
		{
			$true	{Get-ChildItem -File -Recurse | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group}}

			$false	{Get-ChildItem -File | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group}}
		}
	}

function Play-Song
	{
		[Console]::Beep(466.16,300);
		[Console]::Beep(311.13,450);
		[Console]::Beep(622.25,300);
		[Console]::Beep(523.25,150);
		[Console]::Beep(466.16,300);
		[Console]::Beep(311.13,450);

		<#
		[Console]::Beep(466.16,300);
		[Console]::Beep(415.30,150);
		[Console]::Beep(392,150);
		[Console]::Beep(392,150);
		[Console]::Beep(415.30,150);
		[Console]::Beep(466.16,150);
		[Console]::Beep(311.13,300);
		[Console]::Beep(349.23,300);
		[Console]::Beep(392,600);
		#>
	}

function Print-Version
	{
  		$HostVersion = "$($Host.Version.Major)`.$($Host.Version.Minor)";
		$Host.UI.RawUI.WindowTitle = "PowerShell $HostVersion";
	}

function Set-ConsoleColor
{
	param ([Parameter(Mandatory = $true, Position = 0)]
		[ValidateSet("Background", "Foreground", "Both")]
		[string]$Layer,
		[Parameter(Mandatory = $false, Position = 1)]
		[ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan",
		"DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
		"Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
		[string]$Color,
		[Parameter(Mandatory = $false, Position = 2)]
		[ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan",
		"DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
		"Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
		[string]$BgColor,
		[Parameter(Mandatory = $false, Position = 3)]
		[ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan",
		"DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
		"Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
		[string]$FgColor)

	switch ($Layer)
	{
		"Background" {[System.Console]::ResetColor();
				[System.Console]::Clear();
				[System.Console]::BackgroundColor = $Color;}

		"Foreground" {[System.Console]::ResetColor();
				[System.Console]::Clear();
				[System.Console]::ForegroundColor = $Color;}

		"Both" {[System.Console]::ResetColor();
			[System.Console]::Clear();
			[System.Console]::BackgroundColor = $BgColor;
			[System.Console]::ForegroundColor = $FgColor;}
	}
}

function Set-Keybinds
	{
		Set-PSReadLineKeyHandler -Chord Shift+F1 -Function ForwardChar;
		Set-PSReadLineKeyHandler -Chord Shift+F2 -Function ForwardWord;
	}
