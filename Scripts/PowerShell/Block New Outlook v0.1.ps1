# This is a simpler version of previous scripts that avoids anything too fancy (i.e. nested loops or creating dotnet objects).
# This script turns off Auto Migration to New Outlook with Registry Keys.

# Attempts to set working location to the Current User's Registry Hive.
try
{
	$sid = (Get-ChildItem -Path registry::HKEY_USERS | Select-String -Pattern "S-1-5-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+$").Matches.Value;
	Set-Location -Path registry::HKEY_USERS\$sid;
}
catch
{
	throw "Cannot access Registry Hive. Exiting Script."
}

# Verifies Office and Outlook are installed, then updates the Registry accordingly.
# Tests for General Registry Key, then adds new properties/values to it.
if ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options\General") -eq $True)
	{
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -PropertyType DWord -Value 1 -Force;
		Write-Host "Registry updates completed successfully";
	}
# Creates General Registry Key if it was not found, but Outlook is installed, then adds new properties/values to it.
elseif ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options") -eq $True)
	{
		New-Item -Path "Software\Microsoft\Office\16.0\Outlook\Options\General";
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -PropertyType DWord -Value 1 -Force;
		Write-Host "Registry updates completed successfully";
	}
else 
	{
		Write-Host ("Office 16.0 is not installed, and/or no Outlook profile was found. No changes were made.");
	}
