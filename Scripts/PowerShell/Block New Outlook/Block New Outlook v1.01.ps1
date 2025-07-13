# This script turns off Auto Migration to New Outlook by modifying Registry Keys. Only works for signed out users.
# Calls DotNet method to create a static array of each local user account. Using a static array is more performant in most languages and PowerShell is no exception. 
[System.Collections.ArrayList]$localUsers = @((Get-LocalUser).Name | Select-String -NotMatch Administrator,DefaultAccount,Guest,WDAGUtilityAccount,~0000AEAdmin);

# Loops over each local user to load and enter the corresponding Registry, then adds new DWord keys to prevent New Outlook from migrating PST files.
foreach ($user in $localUsers)
{
	reg load HKU\$user "C:\Users\$user\NTUSER.DAT";

	try
	{
		Set-Location -Path Registry::HKU\$user -ErrorAction Stop;
	}
	
	catch
	{
		Write-Host "Unable to set working location for $user`'s Registry.";
		Set-Location -Path C:;
		[System.GC]::Collect();
		reg unload HKU\$user;
		continue
	}

	if ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options\General") -eq $True)
	{
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force | Out-Null;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force | Out-Null;
		Write-Host "Registry updates completed successfully for $user.";
		Set-Location -Path C:;
		[System.GC]::Collect();
		reg unload HKU\$user;
	}

	elseif ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options") -eq $True)
	{
		New-Item -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" | Out-Null;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force | Out-Null;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force | Out-Null;
		Write-Host "Registry updates completed successfully for $user.";
		Set-Location -Path C:;
		[System.GC]::Collect();
		reg unload HKU\$user;
	}

	else 
	{
		Write-Host "No changes were made to the Registry hive for $user. Office 16.0 is not installed, and/or no Outlook profile was found.";
		Set-Location -Path C:;
		[System.GC]::Collect();
		reg unload HKU\$user;
	}
}
