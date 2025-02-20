[System.Collections.ArrayList]$localUsers = @((Get-LocalUser).Name | Select-String -NotMatch Administrator,DefaultAccount,Guest,WDAGUtilityAccount,~0000AEAdmin);
[string]$hkuPath = "Software\Microsoft\Office\16.0\Outlook\Options";
$sid = (Get-ChildItem -Path registry::HKEY_USERS | Select-String -Pattern "S-1-5-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+$").Matches.Value;

if ((Get-Process -Name explorer -ErrorAction Ignore).ProcessName -eq "explorer")
{
	foreach ($hive in $sid)
	{
		$userName = & Get-LocalUser -SID $hive | Select-Object -ExpandProperty Name;

		try
		{
			Set-Location -Path Registry::HKEY_USERS\$hive;
		}

		catch
		{
			return "Could not set working directory.";
		}

		finally
		{
			if ((Test-Path -Path "$hkuPath\General") -eq $True)
			{
				$null = New-ItemProperty -Path "$hkuPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
				$null = New-ItemProperty -Path "$hkuPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
				Write-Host "Registry updates completed successfully for $userName.";
			}

			elseif ((Test-Path -Path "$hkuPath") -eq $True)
			{
				$null = New-Item -Path "$hkuPath\General";
				$null = New-ItemProperty -Path "$hkuPath\General" -Name "NewOutlookAutoMigrationRetryIntervals" -PropertyType DWord -Value 0 -Force;
				$null = New-ItemProperty -Path "$hkuPath\General" -Name "DoNewOutlookAutoMigration" -PropertyType DWord -Value 0 -Force;
				Write-Host "Registry updates completed successfully for $userName.";
			}

			else
			{
				Write-Host "No changes were made to the Registry hive for $userName. Office 16.0 is not installed, and/or no Outlook profile was found.";
			}
		}
	}
}

# Attempts to load any logged out users' Registry with their NTUSER.DAT file
else
{
	foreach ($user in $localUsers)
	{
		reg load HKU\$user "C:\Users\$user\NTUSER.DAT" *>$null;

		try
		{
			Set-Location -Path Registry::HKU\$user;
		}

		catch
		{
			Write-Host "Unable to set working location for $user`'s Registry.";
			Set-Location -Path C:;
			[System.GC]::Collect();
			reg unload HKU\$user *>$null;
			continue
		}

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
