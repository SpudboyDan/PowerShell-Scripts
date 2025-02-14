# Generates Current User as a new dotnet object and then transmutes the variable to its corresponding SID.
# Next, it sets the working directory to the corresponding Registry Hive.
try
{
	$user = New-Object System.Security.Principal.NTAccount($env:UserName);
	$sid = $user.Translate([System.Security.Principal.SecurityIdentifier]).Value;
	Set-Location registry::HKEY_USERS\$sid;
}
catch
{
	throw "Cannot generate user account object and/or user SID. Cannot access Registry Hive. Exiting Script."
}
# Verify Office and Outlook are installed, then add registry entries accordingly.
# Tests for General Registry entry first.
if ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options\General") -eq $True)
	{
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -PropertyType DWord -Value 0 -Force;
		Write-Host "Registry updates completed successfully";
	}
# Creates General Registry entry if it is not found.
elseif ((Test-Path -Path "Software\Microsoft\Office\16.0\Outlook\Options") -eq $True)
	{
		New-Item -Path "Software\Microsoft\Office\16.0\Outlook\Options\General";
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
		New-ItemProperty -Path "Software\Microsoft\Office\16.0\Outlook\Options\General" -Name "HideNewOutlookToggle" -PropertyType DWord -Value 0 -Force;
		Write-Host "Registry updates completed successfully";
	}
else 
	{
		Write-Host ("Office and/or Outlook are not installed");
	}
