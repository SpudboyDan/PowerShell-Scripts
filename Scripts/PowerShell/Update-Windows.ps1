# Force update to Windows 11
Import-Module $env:SyncroModule
$jvh = Test-Path -Path C:\temp\jvhconsulting
if ($jvh -eq $false) { New-Item -Path c:\temp\jvhconsulitng }
$DebugLog = 'C:\temp\jvhconsulting\Win11Upgrade.log'

#function to get timestamp
function Get-TimeStamp {
    return "[{0:yyyy/MM/dd} {0:HH:mm:ss}]" -f (Get-Date)
}
#Function LogMessages
function LogMessage ($msg) {
    Add-Content $DebugLog "$(Get-TimeStamp) $msg"
    Write-Host "$(Get-TimeStamp) $msg"
}

LogMessage "Setting registry keys to bypass Upgrade Checks"

New-Item -Path "HKCU:\SOFTWARE\Microsoft" -Name "PCHC" -Force
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\PCHC" -Name UpgradeEligibility -Value 1 -PropertyType DWORD -Force

New-Item -Path "HKLM:\SYSTEM\Setup" -Name "LabConfig" -Force
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name BypassTPMCheck -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name BypassSecureBootCheck -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name BypassCPUCheck -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name BypassDiskCheck -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name BypassRAMCheck -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name BypassStorageCheck -Value 1 -PropertyType DWORD -Force

New-Item -Path "HKLM:\SYSTEM\Setup" -Name "MoSetup" -Force
New-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name AllowUpgradesWithUnsupportedTPMOrCPU -Value 1 -PropertyType DWORD -Force


<#[HKEY_CURRENT_USER\SOFTWARE\Microsoft\PCHC]
"UpgradeEligibility"=dword:00000001

[HKEY_LOCAL_MACHINE\SYSTEM\Setup\MoSetup]
"AllowUpgradesWithUnsupportedTPMOrCPU"=dword:00000001

[HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig]
"BypassCPUCheck"=dword:00000001
"BypassDiskCheck"=dword:00000001
"BypassRAMCheck"=dword:00000001
"BypassSecureBootCheck"=dword:00000001
"BypassStorageCheck"=dword:00000001
"BypassTPMCheck"=dword:00000001
#>

LogMessage "Setting Windows 11 TargetVersion to 23H2"
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name TargetReleaseVersion -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name TargetReleaseVersionInfo -Value '23H2' -PropertyType String -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name ProductVersion -Value "Windows 11" -PropertyType String -Force
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' | Select-Object TargetReleaseVersion, TargetReleaseVersionInfo, ProductVersion | Format-List

reg query hklm\software\policies\microsoft\windows\windowsupdate
Restart-Service wuauserv -Force

<#$HKCU_Desktop = "HKCU:\Control Panel\Desktop"
New-Item -Path $HKCU_Desktop -Name NewKey
#>

$workingdir = "c:\temp\jvhconsulting"
$url = "https://go.microsoft.com/fwlink/?linkid=2171764"
$file = "$($workingdir)\Win11Upgrade.exe"
LogMessage "Downloading Win11Upgrade to $Workingdir"

<#If(!(test-path -path $workingdir))
{
New-Item -ItemType Directory -Force -Path $workingdir
}#>

Invoke-WebRequest -Uri $url -OutFile $file
LogMessage "Starting Windows 11 upgrade forcefully"
Start-Process -FilePath $file -ArgumentList "/Install  /MinimizeToTaskBar /QuietInstall /SkipEULA /copylogs $workingdir"
