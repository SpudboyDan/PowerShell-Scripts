$newComputerName = Read-Host "What would you like to name this computer?";
$cimComputerSys = Get-CimInstance -ClassName Win32_ComputerSystem;
$modelName = $cimComputerSys | Select-Object -ExpandProperty Model;
$productNumber = $cimComputerSys | Select-Object -ExpandProperty SystemSKUNumber;
$serialNumber = Get-CimInstance -ClassName Win32_ComputerSystemProduct | Select-Object -ExpandProperty IdentifyingNumber;
$cimComputerSys | Set-CimInstance -Property @{AutomaticManagedPageFile = $false};

Rename-Computer -NewName $newComputerName;
New-Item -ItemType Directory -Path "C:\Driver", "C:\Util.w", "C:\Temp";
New-Item -ItemType Directory -Path "C:\Driver\! $modelName";
New-Item -ItemType Directory -Path "C:\Driver\! PN $productNumber";
New-Item -ItemType Directory -Path "C:\Driver\! SN $serialNumber";

Get-CimInstance -ClassName Win32_PageFileSetting | Set-CimInstance -Property @{InitialSize = 16384; MaximumSize = 16384};

if ((Get-Volume -DriveLetter 'C' | Select-Object -ExpandProperty Size) -lt 549755813888) 
{
	vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=10GB
} 

else 
{
	vssadmin Resize ShadowStorage /For=C: /On=C: /MaxSize=20GB
}

if ((Get-BitLockerVolume -MountPoint 'C:' | Select-Object -ExpandProperty VolumeStatus) -NotMatch 'FullyDecrypted') 
{
	Disable-BitLocker -MountPoint 'C:'; Write-Host "Disabling BitLocker..."
} 

else 
{
	Write-Host "BitLocker is already disabled."
}

Set-Volume -DriveLetter 'C' -NewFileSystemLabel 'C-Drive';
Set-TimeZone 'Central Standard Time';
Start-Service W32Time;
w32tm /resync;
