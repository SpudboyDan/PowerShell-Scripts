#*================================================================================
# Copyright © 2025, spudboydan. All rights reserved.
# Secret Screening Alert
# ================================================================================
# Functions
# 	Send-ScreeningAlert
#*================================================================================
https://drafthouse.com/dfw/event/secret-screening-125
# Sends mail to my personal email via smtp2go email server.
function Send-ScreeningAlert {
    # Parameters for Send-MailMessage
    $MailParams = @{
        To         = "lanepitman@gmail.com";
        Subject    = "DISMEMBER THE ALAMO ALERT";
        Body       = "Tickets for Dismember the Alamo are live!";
        From       = "backups@metro-tech.net";
        Credential = $MailCred;
        Port       = 587
    };
    Send-MailMessage @MailParams;
}

# Declare variables.
$RestParams = @{
    Uri         = "https://drafthouse.com/s/mother/v2/schedule/presentation/dfw/agfa-presents-dismember-the-alamo-2025";
    ErrorAction = "Stop"
};

[string]$PSEmailServer = "mail.smtp2go.com";
[string]$EncryptedSecureString = "76492d1116743f0423413b16050a5345MgB8AEoAYwA5AHYAQQBjAGgAQQBaAE8AUQBIAHEANAB6AEgAUgB6AEwANwA2AEEAPQA9AHwAOQA3AGEAYgBmAGMAMgBiADIANwA5AGUAMQA3AGIAZgA1AGUANwBkADQAYQBjAGEAZQAzADEAZAA4AGIAMAA2ADYAZQA0AGIAMAA0AGIANQBhAGQAMwBhADcANwA5AGYANABiAGIAZgAxADcAZgA0AGQANwA2AGMAYQA1AGIAZgA=";
$EncryptionKey = [byte[]]@(158, 78, 43, 25, 158, 127, 22, 96, 100, 217, 182, 220, 223, 244, 254, 46, 89, 141, 61, 8, 85, 60, 161, 39);
$SecureString = ConvertTo-SecureString -String $EncryptedSecureString -Key $EncryptionKey;
$MailCred = [Management.Automation.PSCredential]::new("metrotech", $SecureString);

# Main statements. Queries Alamo's API and then sends an email if tickets are live.
$ScreeningRequest = (Invoke-RestMethod @RestParams).data.sessions.status;
if ($ScreeningRequest -contains "ONSALE") {
    Send-ScreeningAlert;
};
