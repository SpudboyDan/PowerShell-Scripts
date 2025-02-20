# This script turns off Auto Migration to New Outlook with Registry Keys.
# Calls DotNet method to create a static array of each local user account. Using a static array is more performant in most languages and PowerShell is no exception. 
[System.Collections.ArrayList]$localUsers = @((Get-LocalUser).Name | Select-String -NotMatch Administrator,DefaultAccount,Guest,WDAGUtilityAccount,~0000AEAdmin);

# Variable to check if Outlook is actually installed.
[string]$hkuPath = "Software\Microsoft\Office\16.0\Outlook\Options";

foreach ($user in $localUsers)
{
	try
	{
		$sid = (& Get-LocalUser -Name $user).SID.Value;
		Set-Location Registry::HKU\$sid -ErrorAction stop;
	}
	
	catch
	{
		Write-Host "Unable to set working location for $user`'s Registry.";
		continue
	}
	
	if ((Test-Path -Path "$hkuPath\General") -eq $True)
	{
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
