#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Secret Screening Alert
# ================================================================================
# Functions
# 	Send-ScreeningAlert
#*================================================================================

# Sends mail to my personal email via smtp2go email server.
function Send-ScreeningAlert
{
	Send-MailMessage -To 'lanepitman@gmail.com' -Subject "SECRET SCREENING $screeningNumber ALERT" -Body "Tickets for Secret Screening $screeningNumber are live!" -From 'backups@metro-tech.net' -Credential $mailCred -Port 587;
}

# Declare variables.
[int32]$screeningNumber = 121;
[string]$encryptedSecureString = "76492d1116743f0423413b16050a5345MgB8AEoAYwA5AHYAQQBjAGgAQQBaAE8AUQBIAHEANAB6AEgAUgB6AEwANwA2AEEAPQA9AHwAOQA3AGEAYgBmAGMAMgBiADIANwA5AGUAMQA3AGIAZgA1AGUANwBkADQAYQBjAGEAZQAzADEAZAA4AGIAMAA2ADYAZQA0AGIAMAA0AGIANQBhAGQAMwBhADcANwA5AGYANABiAGIAZgAxADcAZgA0AGQANwA2AGMAYQA1AGIAZgA=";
[string]$matchExpressionRichardson = '\"cinemaId\"\:\"0701\"\,\"sessionId\"\:\"[0-9]+\"\,\"presentationSlug\"\:\"special-event-secret-screening-[0-9]+\"\,\"legacySlug\"\:\"secret-screening-[0-9]+\"\,\"status\"\:\"ONSALE\"';
[string]$matchExpressionCedars = '\"cinemaId\"\:\"0702\"\,\"sessionId\"\:\"[0-9]+\"\,\"presentationSlug\"\:\"special-event-secret-screening-[0-9]+\"\,\"legacySlug\"\:\"secret-screening-[0-9]+\"\,\"status\"\:\"ONSALE\"';
[string]$PSEmailServer = 'mail.smtp2go.com';
$encryptionKey = (158,78,43,25,158,127,22,96,100,217,182,220,223,244,254,46,89,141,61,8,85,60,161,39);
$secureString = ConvertTo-SecureString -String $encryptedSecureString -Key $encryptionKey;
$mailCred = New-Object System.Management.Automation.PSCredential('metrotech', $secureString);

# Main statement. Checks Alamo's server and sends an email if tickets are live.
switch ((Invoke-WebRequest -Uri "https://drafthouse.com/s/mother/v2/schedule/presentation/dfw/special-event-secret-screening-$screeningNumber" -ErrorAction Stop).Content) 
{
	{$_ -notmatch $matchExpressionRichardson} {Continue}
	{$_ -notmatch $matchExpressionCedars} {Continue}
	{$_ -imatch $matchExpressionRichardson} {Send-ScreeningAlert;}
	{$_ -imatch $matchExpressionCedars} {Send-ScreeningAlert;}
}

switch ((Invoke-WebRequest -Uri "https://drafthouse.com/s/mother/v2/schedule/presentation/dfw/special-event-secret-screening-120" -ErrorAction Stop).Content) 
{
	{$_ -notmatch $matchExpressionCedars} {Stop}
	{$_ -imatch $matchExpressionCedars} {Send-ScreeningAlert;}
}
