# This script turns off Auto Migration to New Outlook with Registry Keys.
# Creates a variable containing any found local user Registry hives.
$sid = (Get-ChildItem -Path Registry::HKEY_USERS | Select-String -Pattern "S-1-5-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+$").Matches.Value;

# Immediately terminates script if no Registry hives are found.
if ($sid -eq $null)
{
	throw "Unable to locate Registry hive(s).";
}

# Sets working directory to the appropriate hive, verifies Office and Outlook are installed, then updates the Registry accordingly.
foreach ($hive in $sid)
{
        $userName = & Get-LocalUser -SID $hive -ErrorAction Ignore | Select-Object -ExpandProperty Name -ErrorAction Ignore;    

	try
	{
		Set-Location -Path Registry::HKEY_USERS\$hive -ErrorAction Stop;
	}

	catch
	{
		Write-Host "Could not set working directory.";
		continue
	}

	# Tests for General Registry Key, then adds new properties/values to it.
	if ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options\General") -eq $True)
	{
		$null = New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
		$null = New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
		$null = New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -PropertyType DWord -Value 1 -Force;
		Write-Host "Registry updates completed successfully for $userName.";
	}

	# Creates General Registry Key if it was not found, but Outlook is installed, then adds new properties/values to it.
	elseif ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options") -eq $True)
	{
		$null = New-Item -Path "Software\Microsoft\Office\16.0\Outlook\Options\General";
		$null = New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
		$null = New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
		$null = New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -PropertyType DWord -Value 1 -Force;
		Write-Host "Registry updates completed successfully for $userName.";
	}

	else 
	{
		Write-Host "No changes were made to the Registry hive for $userName. Office 16.0 is not installed, and/or no Outlook profile was found.";
	}
}
