$encryptedSecureString = "{[string]}";

$encryptionKey = {[key]};

$secureString = ConvertTo-SecureString -String $encryptedSecureString -Key $encryptionKey;

$secureCred = New-Object System.Management.Automation.PSCredential('metrotech', $secureString);

$screenLockReg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Splashtop Inc.\Splashtop Remote Server").ScreenLock;

$localUsers = (Get-LocalUser).Name | Select-String -Pattern "Administrator", "ASPNET", "DefaultAccount", "Guest", "HomeGroupUser$", "WDAGUtilityAccount" -NotMatch;

$PSEmailServer = 'mail.smtp2go.com';

switch ($screenLockReg)
{
0 {Send-MailMessage -To 'lane@metro-tech.net' -Subject 'Splashtop registry setting' -Body "WARNING: The Splashtop Streamer settings for $localUsers on computer $env:COMPUTERNAME are not configured to automatically lock the computer at the end of a session. Splashtop settings are now updating to correct this." -Cc 'craig@metro-tech.net' -From 'backups@metro-tech.net' -Credential $secureCred -Port 587}
0 {Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Splashtop Inc.\Splashtop Remote Server" -Name ScreenLock -Type Dword -Value 00000001}
0 {Restart-Service 'SplashtopRemoteService'}
}