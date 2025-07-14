function Invoke-LightSwitch {

    # Series of If Elseif statements to flip Windows between light and dark modes
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

    # Kill Windows Shell
    TASKKILL /F /IM sihost.exe;
    TASKKILL /F /IM explorer.exe;

    # Force Kill Total Commander if it is running and relaunch with new theme
    if ($TotalCommanderId = Get-Process -Name TOTALCMD64 -ErrorAction Ignore) {
	    Stop-Process -Id $TotalCommanderId.Id -ErrorAction Ignore;
    	    Start-Process -FilePath "C:\Util.w\Wincmd\TOTALCMD64.EXE";}

    # Sleep routine for cleaning up resources
    Start-Sleep -Seconds 30;
    
    # Confirmation Message
    Write-Host -ForegroundColor Cyan "Successfully Changed Themes";
    Start-Sleep -Seconds 5
}
