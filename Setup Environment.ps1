#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Profile setup and utilities
# ================================================================================
# Functions
#	Download-AdultSwim
#	Get-AteraAgents
# 	Get-Duplicates
# 	Get-DuplicatesFast
# 	Get-DuplicatesV2
# 	Invoke-AteraApi
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

function Get-AteraAgents
{
	param ([parameter(Mandatory = $true, Position = 0)]
		[string]$Key,
		[parameter(Mandatory = $false, Position = 1)]
		[int]$PageNumber = 1,
		[parameter(Mandatory = $false, Position = 2)]
		[int]$ItemAmount = 20,
		[parameter(Mandatory = $false, Position = 3)]
		[switch]$All)

	switch ($All) {
		$true	{[int]$Pages = (Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents?page=1&itemsInPage=50" -Headers @{
						"method"="GET"
						"scheme"="https"
  						"accept"="application/json;charset=utf-8,*/*"
  						"accept-encoding"="gzip, deflate, br, zstd"
  						"accept-language"="en-US,en;q=0.9"
  						"x-api-key"="$Key"}).totalPages;
				for ($i = 1; $i -le $Pages; $i++) {
					(Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents?page=$i&itemsInPage=50" -Headers @{
						"method"="GET"
						"scheme"="https"
  						"accept"="application/json;charset=utf-8,*/*"
  						"accept-encoding"="gzip, deflate, br, zstd"
  						"accept-language"="en-US,en;q=0.9"
  						"x-api-key"="$Key"}).items}}

		$false	{(Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
				"method"="GET"
				"scheme"="https"
  				"accept"="application/json;charset=utf-8,*/*"
  				"accept-encoding"="gzip, deflate, br, zstd"
  				"accept-language"="en-US,en;q=0.9"
  				"x-api-key"="$Key"}).items}
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

function Get-DuplicatesV2
{
	param ([switch]$Recurse)
	
	switch ($Recurse)
	{
		$true {$Properties = @{RecurseSubdirectories = [bool]1; IgnoreInaccessible = [bool]1;}
		$EnumerationOptions = New-Object -TypeName System.IO.EnumerationOptions -Property $Properties;
		$Directory = [System.Collections.Generic.List[System.IO.FileInfo]]@([System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*', $EnumerationOptions));
		$ByteArray = [System.Collections.Generic.List[byte]]::new();
		[Func[System.IO.FileInfo,int64]]$InnerDelegate = {$args[0].Length}
		[Func[System.IO.FileInfo,string]]$OuterDelegate = {$args[0].FullName}
		[System.Linq.Enumerable]::GroupBy($Directory, $InnerDelegate, $OuterDelegate);
		[System.Linq.Enumerable]::Where([System.Linq.Enumerable]::GroupBy($Directory, $InnerDelegate, $OuterDelegate), [System.Func[object, bool]] {$args[0].Count -gt 1});
		$ByteArray.Add([System.BitConverter]::ToString(([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.IO.File]::OpenRead("File.ext")))).Replace("-", "").ToLower())}
		
		$false {$Properties = @{RecurseSubdirectories = [bool]0; IgnoreInaccessible = [bool]1;}
		$EnumerationOptions = New-Object -TypeName System.IO.EnumerationOptions -Property $Properties;
		$Directory = [System.Collections.Generic.List[System.IO.FileInfo]]@([System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*', $EnumerationOptions));
		[Func[System.IO.FileInfo,int64]]$InnerDelegate = {$args[0].Length}
		[Func[System.IO.FileInfo,string]]$OuterDelegate = {$args[0].FullName}
		[System.Linq.Enumerable]::GroupBy($Directory, $InnerDelegate, $OuterDelegate);
		[System.Linq.Enumerable]::Where([System.Linq.Enumerable]::GroupBy($Directory, $InnerDelegate, $OuterDelegate), [System.Func[object, bool]] {$args[0].Count -gt 1});}
	}
}

function Invoke-AteraApi
{
	param ([parameter(Mandatory = $true, Position = 0)]
		[string]$Key,
		[parameter(Mandatory = $true, Position = 1)]
		[ValidateSet("Agents", "Customers", "CustomerAgents", "CustomerById", "MachineByName")]
		[string]$Query,
		[parameter(Mandatory = $false, Position = 2)]
		[long]$CustomerId,
		[parameter(Mandatory = $false, Position = 3)]
		[string]$MachineName,
		[parameter(Mandatory = $false, Position = 4)]
		[int]$PageNumber = 1,
		[parameter(Mandatory = $false, Position = 5)]
		[int]$ItemAmount = 20)

	switch ($Query) {
		"Agents" 	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}}

		"Customers"	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/customers?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}}

		"CustomerAgents"	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents/customer/$CustomerId`?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
						"method"="GET"
						"scheme"="https"
  						"accept"="application/json;charset=utf-8,*/*"
  						"accept-encoding"="gzip, deflate, br, zstd"
  						"accept-language"="en-US,en;q=0.9"
  						"x-api-key"="$Key"}}

		"CustomerById"	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/customers/$CustomerId" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}}

		"MachineByName"	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents/machine/$MachineName`?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}}
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
		[ValidateSet("BackgroundColor", "ForegroundColor")]
		[string]$Layer,
		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan",
		"DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
		"Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
		[string]$Color)

	[System.Console]::$Layer = "$Color";
}

function Set-Keybinds
	{
		Set-PSReadLineKeyHandler -Chord Shift+F1 -Function ForwardChar;
		Set-PSReadLineKeyHandler -Chord Shift+F2 -Function ForwardWord;
	}
