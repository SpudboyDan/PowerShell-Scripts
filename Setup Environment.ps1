#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Profile setup and utilities
# ================================================================================
# Functions
# 	Print-Version
# 	Set-Keybinds
# 	Get-Duplicates
# 	Get-DuplicatesFast
# 	Get-DuplicatesFaster
# 	Get-DuplicatesFastest
#*================================================================================
function Print-Version
	{
  		$hostversion="$($Host.Version.Major)`.$($Host.Version.Minor)";
		$Host.UI.RawUI.WindowTitle = "PowerShell $hostversion";
	}

function Set-Keybinds
	{
		Set-PSReadLineKeyHandler -Chord Shift+F1 -Function ForwardChar;
		Set-PSReadLineKeyHandler -Chord Shift+F2 -Function ForwardWord;
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
				foreach {$_.Group} | Select-Object -Skip 1}

			$false	{Get-ChildItem -File | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Get-FileHash | `
				Group-Object -Property Hash | Where-Object {$_.Count -gt 1} | `
				foreach {$_.Group} | Select-Object -Skip 1}
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
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Select-Object -Skip 1}

			$false	{Get-ChildItem -File | Group-Object -Property Length | `
				Where-Object {$_.Count -gt 1} | foreach {$_.Group} | Select-Object -Skip 1}
		}
	}
