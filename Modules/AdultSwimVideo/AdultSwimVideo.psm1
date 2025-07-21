function Get-AdultSwimVideo {
	param ([Parameter(Mandatory = $true, Position = 0)] [string]$Uri)
	try {
		$Links = (Invoke-WebRequest -Uri $Uri).Links.Href |
		Select-String -Pattern ("$($Uri.Replace('https://www.adultswim.com',''))" + "/[a-z0-9\-]+")
		foreach ($Link in $Links) {
			yt-dlp "https://www.adultswim.com$Link"
		}
	}
	catch {
		$PSCmdlet.ThrowTerminatingError($PSItem);
	}
}
