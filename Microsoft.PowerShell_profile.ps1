#*================================================================================
# Profile
# ================================================================================
# Functions
# 	Find-DuplicateFile
#	Get-AdultSwimVideo
#	Get-AteraAgent
#	Get-AteraCustomer
#	Get-KHInsiderMP3
# 	New-StartShortcut
# 	Set-Keybind
# 	Write-Version
#	
#	Retired:
# 	Invoke-LightSwitch
#
# Load Modules
# ================================================================================
Import-Module -Global -Name Microsoft.PowerShell.Utility;
Import-Module -Name AdultSwimVideo;
Import-Module -Name DuplicateFileFinder;
Import-Module -Name KHInsider;
Import-Module -Name PSAtera;
Import-Module -Name StartShortcut;
#*================================================================================
Write-Host -ForegroundColor Cyan -Message "Welcome back, Lane";

function Private:Set-Keybind {
	Set-PSReadLineKeyHandler -Chord Shift+F1 -Function ForwardChar;
	Set-PSReadLineKeyHandler -Chord Shift+F2 -Function ForwardWord;
}

Set-Keybind;

function Private:Invoke-LightSwitch {
    if ((Get-ItemProperty -Path HKCU:\SoftWare\Microsoft\Windows\CurrentVersion\Themes\Personalize).SystemUsesLightTheme -eq 1) {
        (Set-ItemProperty -Path HKCU:\SoftWare\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Type DWord -Value 0)
    }

    elseif ((Get-ItemProperty -Path HKCU:\SoftWare\Microsoft\Windows\CurrentVersion\Themes\Personalize).SystemUsesLightTheme -eq 0) {
        (Set-ItemProperty -Path HKCU:\SoftWare\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Type DWord -Value 1)
    }

    if ((Get-ItemProperty -Path HKCU:\SoftWare\Microsoft\Windows\CurrentVersion\Themes\Personalize).AppsUseLightTheme -eq 1) {
        (Set-ItemProperty -Path HKCU:\SoftWare\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Type DWord -Value 0) 
    }
		
    elseif ((Get-ItemProperty -Path HKCU:\SoftWare\Microsoft\Windows\CurrentVersion\Themes\Personalize).AppsUseLightTheme -eq 0) {
        (Set-ItemProperty -Path HKCU:\SoftWare\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Type DWord -Value 1) 
    }

    $SihostId = Get-Process -Name sihost;
    Stop-Process -Id $SihostId.Id;
    
    if ($TotalCommanderId = Get-Process -Name TOTALCMD64 -ErrorAction Ignore) {
	    Stop-Process -Id $TotalCommanderId.Id -ErrorAction Ignore; Start-Process -FilePath C:\Util.w\Wincmd\TOTALCMD64.EXE}

    Start-Sleep -Seconds 30;
    Write-Host -ForegroundColor Yellow "Successfully Changed Themes";
    Start-Sleep -Seconds 5;
}
