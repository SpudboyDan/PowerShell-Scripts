# This script turns off Auto Migration to New Outlook with Registry Keys.
# Creates a variable for user Registry hive(s).
$sid = (Get-ChildItem -Path registry::HKEY_USERS | Select-String -Pattern "S-1-5-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+$").Matches.Value;

# Immediately terminates script if no Registry hives are found.
if ($sid -eq $null)
{
	throw "Unable to locate Registry hive(s).";
}

# Sets working directory to the appropriate hive, verifies Office and Outlook are installed, then updates the Registry accordingly.
foreach ($hive in $sid)
{
	try
	{
		Set-Location -Path registry::HKEY_USERS\$hive;
	}
	catch
	{
		Write-Host "Could not set working directory";
	}

	# Tests for General Registry Key, then adds new properties/values to it.
	if ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options\General") -eq $True)
	{
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force | Out-Null;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force | Out-Null;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -PropertyType DWord -Value 1 -Force | Out-Null;
		Write-Host "Registry updates completed successfully for Registry hive with SID $hive.";
	}
	# Creates General Registry Key if it was not found, but Outlook is installed, then adds new properties/values to it.
	elseif ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options") -eq $True)
	{
		New-Item -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" | Out-Null;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force | Out-Null;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force | Out-Null;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -PropertyType DWord -Value 1 -Force | Out-Null;
		Write-Host "Registry updates completed successfully for Registry hive with SID $hive.";
	}
	else 
	{
		Write-Host "No changes were made to Registry hive with SID $hive. Office 16.0 is not installed, and/or no Outlook profile was found.";
	}
}
