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
# 	Print-Version
# 	Set-Keybinds
#*================================================================================
function Download-AdultSwim
	{
		param ($Uri = $(throw "Download-Videos: Invalid URI: The hostname could not be parsed."))
		$links = (Invoke-WebRequest -Uri $Uri).Links.Href | Select-String -Pattern ("$($Uri.Replace('https://www.adultswim.com',''))" + "/[a-z0-9\-]+")
		foreach ($link in $links)
		{
			yt-dlp "https://www.adultswim.com$link"
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
				foreach {$_.Group} | Select-Object}

			$false	{Get-ChildItem -File | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Get-FileHash | `
				Group-Object -Property Hash | Where-Object {$_.Count -gt 1} | `
				foreach {$_.Group} | Select-Object}
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
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Select-Object}

			$false	{Get-ChildItem -File | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Select-Object}
		}
	}

function Print-Version
	{
  		$hostversion = "$($Host.Version.Major)`.$($Host.Version.Minor)";
		$Host.UI.RawUI.WindowTitle = "PowerShell $hostversion";
	}

function Set-Keybinds
	{
		Set-PSReadLineKeyHandler -Chord Shift+F1 -Function ForwardChar;
		Set-PSReadLineKeyHandler -Chord Shift+F2 -Function ForwardWord;
	}
