# $secureString = (Read-Host -AsSecureString "Please enter a password for drive V");
# $secureCredential = New-Object System.Management.Automation.PSCredential('lanep',$secureString);
# New-PSDrive -Name "V" -PSProvider FileSystem -Root "\\192.168.77.253\personal\data" -Scope Global -Persist -Credential $secureCredential;
$spotlightCache = Get-ChildItem -Path "$env:LOCALAPPDATA\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalCache\Microsoft\IrisService\*\*.jpg";
$wallpaperBin = Get-ChildItem -Path "V:\Pictures\LaneWallpaper\*.jpg";

foreach ($jpg in $spotlightCache)
{
	if (((Get-FileHash -Path $jpg).Hash) -ne ((Get-FileHash -Path $wallpaperBin).Hash))
	{
		Copy-Item -Path $jpg -Destination "V:\Pictures\LaneWallpaper";
	}
}
