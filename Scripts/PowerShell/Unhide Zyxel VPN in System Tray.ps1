if ((Test-Path HKCU:\Software\Zyxel\ZyWALL IPSec VPN Client) -eq $True) 
{
	Remove-ItemProperty "HKCU:\Software\Zyxel\ZyWALL IPSec VPN Client" -Name "xywh" -Force;
	Remove-ItemProperty "HKCU:\Software\Zyxel\ZyWALL IPSec VPN Client" -Name "xywh_cnx" -Force;
}
