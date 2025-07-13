# This script should only be used during the months of September and October, when there is an actual chance that Dismember tickets will go on sale

$dismemberYear = 2025
$encryptionKey = (158,78,43,25,158,127,22,96,100,217,182,220,223,244,254,46,89,141,61,8,85,60,161,39);
$encryptedSecureString = "76492d1116743f0423413b16050a5345MgB8AEoAYwA5AHYAQQBjAGgAQQBaAE8AUQBIAHEANAB6AEgAUgB6AEwANwA2AEEAPQA9AHwAOQA3AGEAYgBmAGMAMgBiADIANwA5AGUAMQA3AGIAZgA1AGUANwBkADQAYQBjAGEAZQAzADEAZAA4AGIAMAA2ADYAZQA0AGIAMAA0AGIANQBhAGQAMwBhADcANwA5AGYANABiAGIAZgAxADcAZgA0AGQANwA2AGMAYQA1AGIAZgA="
$secureString = ConvertTo-SecureString -String $encryptedSecureString -Key $encryptionKey;
$mailCred = New-Object System.Management.Automation.PSCredential('metrotech', $secureString);
$PSEmailServer = 'mail.smtp2go.com';

try
{
	Invoke-WebRequest -Uri "https://drafthouse.com/s/mother/v2/schedule/presentation/dfw/dismember-the-alamo-$dismemberYear" && Send-MailMessage -To 'lanepitman@gmail.com' -Subject "DISMEMBER THE ALAMO $dismemberYear ALERT" -Body "Tickets for Dismember the Alamo $dismemberYear are live!" -From 'backups@metro-tech.net' -Credential $mailCred -Port 587
}

catch
{
	$null
}

# This alternative URL is for if/when AGFA sponsors Dismember the Alamo again

try
{
	Invoke-WebRequest -Uri "https://drafthouse.com/s/mother/v2/schedule/presentation/dfw/agfa-presents-dismember-the-alamo-$dismemberYear" && Send-MailMessage -To 'lanepitman@gmail.com' -Subject "DISMEMBER THE ALAMO $dismemberYear ALERT" -Body "Tickets for Dismember the Alamo $dismemberYear are live!" -From 'backups@metro-tech.net' -Credential $mailCred -Port 587
}

catch
{
	$null
}
