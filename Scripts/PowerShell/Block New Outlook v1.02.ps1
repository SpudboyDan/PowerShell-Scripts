# This script turns off Auto Migration to New Outlook by modifying Registry Keys. Only works for signed out users.
# Calls DotNet method to create a static array of each local user account. Using a static array is more performant in most languages and PowerShell is no exception. 
[System.Collections.ArrayList]$localUsers = @((Get-LocalUser).Name | Select-String -NotMatch Administrator,DefaultAccount,Guest,WDAGUtilityAccount,~0000AEAdmin);

# Variable to check if Outlook is actually installed.
[string]$hkuPath = "Software\Microsoft\Office\16.0\Outlook\Options";

# Loops over each user to load and enter the corresponding Registry, then adds new DWord keys to prevent New Outlook from migrating PST files.
foreach ($user in $localUsers)
{
	try
	{
		reg load HKU\$user "C:\Users\$user\NTUSER.DAT" *>$null;
		Set-Location -Path Registry::HKU\$user -ErrorAction stop;
	}
	
	catch
	{
		Write-Host "Unable to set working location for $user`'s Registry.";
		[System.GC]::Collect();
		reg unload HKU\$user *>$null;
		continue
	}
	
	finally
	{
		if ((Test-Path -Path "$hkuPath\General") -eq $True)
		{
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully for $user.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$user *>$null;
		}

		elseif ((Test-Path -Path "$hkuPath") -eq $True)
		{
			$null = New-Item -Path "$hkuPath\General";
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
			$null = New-ItemProperty -Path "$hkuPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
			Write-Host "Registry updates completed successfully for $user.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$user *>$null;
		}
	
		else 
		{
			Write-Host "No changes were made to the Registry hive for $user. Office 16.0 is not installed, and/or no Outlook profile was found.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$user *>$null;
		}
	}
}
