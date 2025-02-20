#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Block New Outlook v3
# ================================================================================
# Functions
# 	Disable-NewOutlook
# 	Disable-NewOutlookOffline
#*================================================================================

# Declare variables. Array of non-system-created users and Registry path.
[System.Collections.ArrayList]$localUsers = @((Get-LocalUser).Name | Select-String -NotMatch Administrator,ASPNET,DefaultAccount,Guest,HomeGroupUser,QBDataServiceUser,WDAGUtilityAccount,~0000AEAdmin);
[string]$hkuPath = "Software\Microsoft\Office\16.0\Outlook\Options";

# Terminates script if no users are found.
if ($localUsers.Count -eq 0)
{
	throw "No usernames found.";
}

# Declare functions.
function Disable-NewOutlook
{
	foreach ($user in $localUsers)
	{
		try
		{
			# Expands username to its corresponding SID (Security ID) for explicit targeting of each Registry hive.
			$sid = (& Get-LocalUser -Name $user).SID.Value;
			Set-Location Registry::HKU\$sid -ErrorAction Stop;
		}
	
		catch
		{
			# Returns to top of loop if Registry cannot be accessed.
			Write-Host "Unable to set working location for $user`'s Registry.";
			Continue
		}
	
		if ((Test-Path -Path "$hkuPath\General") -eq $True)
		{
			# Null is to help with performance but also to suppress "noisy" output.
			# The "Out-Null" Cmdlet is suboptimal and should generally be avoided,
			# especially when performance matters.
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully for $user.";
		}
	
		elseif ((Test-Path -Path "$hkuPath") -eq $True)
		{
			$null = New-Item -Path "$hkuPath\General";
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully for $user.";
		}
	
		else
		{
			Write-Host "No changes were made to the Registry hive for $user. Office 16.0 is not installed, and/or no Outlook profile was found.";
		}
	}
}

# Does the same thing as Disable-NewOutlook, but only for logged out users by loading their NTUSER.DAT file.
function Disable-NewOutlookOffline
{
	foreach ($user in $localUsers)
	{
		# Once again $null is used to suppress noisy output and increase performance.
		# Output must be redirected this way (vs. how we prviously casted to $null)
		# due to how PowerShell handles output streams for Win32 applications.
		reg load HKU\$user "C:\Users\$user\NTUSER.DAT" *>$null;

		try
		{
			Set-Location -Path Registry::HKU\$user -ErrorAction Stop;
		}
		
		catch
		{
			# Garbage collection must be manually called due to the amount of time
			# it takes for reg.exe to properly unload an entry.
			Write-Host "Unable to set working location (offline) for $user`'s Registry.";
			[System.GC]::Collect();
			reg unload HKU\$user *>$null;
			Continue
		}
		
		if ((Test-Path -Path "$hkuPath\General") -eq $True)
		{
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully (offline) for $user.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$user *>$null;
		}
	
		elseif ((Test-Path -Path "$hkuPath") -eq $True)
		{
			$null = New-Item -Path "$hkuPath\General";
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully (offline) for $user.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$user *>$null;
		}
		
		else 
		{
			Write-Host "No changes were made to the Registry hive (offline) for $user. Office 16.0 is not installed, and/or no Outlook profile was found.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$user *>$null;
		}
	}
}

# The main section of this script. Running a switch statement against the explorer
# process helps determine if a user is currently logged in, thereby selecting the
# appropriate function to invoke.
switch ((Get-Process -Name explorer -ErrorAction Ignore).ProcessName -contains "explorer")
{
	$true {Disable-NewOutlook}
	$false {Disable-NewOutlookOffline}
}
