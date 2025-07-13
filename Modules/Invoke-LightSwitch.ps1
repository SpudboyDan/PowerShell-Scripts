function Invoke-LightSwitch {
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
    TASKKILL /F /IM explorer.exe;
    TASKKILL /F /IM sihost.exe;
    
    if ($TotalCommanderId = Get-Process -Name TOTALCMD64 -ErrorAction Ignore) {
	    Stop-Process -Id $TotalCommanderId.Id -ErrorAction Ignore; Start-Process -FilePath C:\Util.w\Wincmd\TOTALCMD64.EXE}

    Start-Sleep -Seconds 10;
    Write-Host -ForegroundColor Cyan "Successfully Changed Themes";
    Start-Sleep -Seconds 5
}
