$secureString = (Read-Host -AsSecureString "Please enter a password for drive W");
$secureCredential = New-Object System.Management.Automation.PSCredential('willb',$secureString);
New-PSDrive -Name "W" -PSProvider FileSystem -Root "\\192.168.77.253\work\data" -Credential $secureCredential;
New-Item -ItemType Directory -Path "C:\Driver", "C:\Util.w", "C:\Temp";

Copy-Item -Path "W:\01 Main\Util.w\wincmd.ini" -Destination "C:\Windows" -Force -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\wcx_ftp.ini" -Destination "C:\Windows" -Force -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\Wincmd" -Destination "C:\Util.w" -Recurse;
Copy-Item -Path "W:\01 Main\Util.w\IrfanView" -Destination "C:\Util.w" -Recurse;
Copy-Item -Path "W:\00 Essentials\Cleanup" -Destination "C:\Temp" -Recurse;
Copy-Item -Path "W:\00 Essentials\Utilities" -Destination "C:\Temp" -Recurse;
