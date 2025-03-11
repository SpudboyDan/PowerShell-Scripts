#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Block New Outlook v3
# ================================================================================
# Functions
# 	Disable-NewOutlook
# 	Disable-NewOutlookOffline
#*================================================================================

# Declare variables. Array of system-created users to match against.
$SystemUsers = [System.Collections.Generic.List[string]]@(
	"Administrator",
	"ASPNET",
	"DefaultAccount",
	"Guest",
	"HomeGroupUser",
	"QBDataServiceUser",
	"WDAGUtilityAccount",
	"~0000AEAdmin");

$LocalUsers = [System.Collections.Generic.List[string]]@((Get-LocalUser).Name.Where({$_ -notin $SystemUsers});
[string]$HKeyUsersPath = "Software\Microsoft\Office\16.0\Outlook\Options";

# Terminates script if no users are found.
if ($LocalUsers.Count -eq 0)
{
	throw "No usernames found.";
}

# Declare functions.
function Disable-NewOutlook
{
	foreach ($User in $LocalUsers)
	{
		try
		{
			# Expands username to its corresponding SID (Security ID) for explicit targeting of each Registry hive.
			$SID = (& Get-LocalUser -Name $User).SID.Value;
			Set-Location Registry::HKU\$SID -ErrorAction Stop;
		}
	
		catch
		{
			# Returns to top of loop if Registry cannot be accessed.
			Write-Host "Unable to set working location for $User`'s Registry.";
			Continue
		}
	
		if ((Test-Path -Path "$HKeyUsersPath\General") -eq $true)
		{
			# Null is to help with performance but also to suppress "noisy" output.
			# The "Out-Null" Cmdlet is suboptimal and should generally be avoided,
			# especially when performance matters.
			$null = New-ItemProperty -Path "$HKeyUsersPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$HKeyUsersPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully for $User.";
		}
	
		elseif ((Test-Path -Path "$HKeyUsersPath") -eq $true)
		{
			$null = New-Item -Path "$HKeyUsersPath\General";
			$null = New-ItemProperty -Path "$HKeyUsersPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$HKeyUsersPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully for $User.";
		}
	
		else
		{
			Write-Host "No changes were made to the Registry hive for $User. Office 16.0 is not installed, and/or no Outlook profile was found.";
		}
	}
}

# Does the same thing as Disable-NewOutlook, but only for logged out users by loading their NTUSER.DAT file.
function Disable-NewOutlookOffline
{
	foreach ($User in $LocalUsers)
	{
		# Once again $null is used to suppress noisy output and increase performance.
		# Output must be redirected this way (vs. how we prviously casted to $null)
		# due to how PowerShell handles output streams for Win32 applications.
		reg load HKU\$User "C:\Users\$User\NTUSER.DAT" *>$null;

		try
		{
			Set-Location -Path Registry::HKU\$User -ErrorAction Stop;
		}
		
		catch
		{
			# Garbage collection must be manually called due to the amount of time
			# it takes for reg.exe to properly unload an entry.
			Write-Host "Unable to set working location (offline) for $User`'s Registry.";
			[System.GC]::Collect();
			reg unload HKU\$User *>$null;
			Continue
		}
		
		if ((Test-Path -Path "$HKeyUsersPath\General") -eq $True)
		{
			$null = New-ItemProperty -Path "$HKeyUsersPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$HKeyUsersPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully (offline) for $User.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$User *>$null;
		}
	
		elseif ((Test-Path -Path "$HKeyUsersPath") -eq $True)
		{
			$null = New-Item -Path "$HKeyUsersPath\General";
			$null = New-ItemProperty -Path "$HKeyUsersPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$HKeyUsersPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully (offline) for $User.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$User *>$null;
		}
		
		else 
		{
			Write-Host "No changes were made to the Registry hive (offline) for $User. Office 16.0 is not installed, and/or no Outlook profile was found.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$User *>$null;
		}
	}
}

# Main section of this script. If statement determines the correct function to call.
if ((Get-Process -Name explorer -ErrorAction Ignore).ProcessName -eq "explorer")
{
	Disable-NewOutlook
}
	
else {
	Disable-NewOutlookOffline
}
