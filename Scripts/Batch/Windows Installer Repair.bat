@echo off
net stop bits 
net stop appidsvc 
net stop cryptsvc
Del "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\*.*" /f /Q 
rmdir %systemroot%\SoftwareDistribution /f /S /Q 
rmdir %systemroot%\system32\catroot2 /f /S /Q 
regsvr32.exe /s atl.dll 
regsvr32.exe /s urlmon.dll 
regsvr32.exe /s mshtml.dll 
netsh winsock reset 
netsh winsock reset proxy 
net start bits 
net start wuauserv 
net start appidsvc 
net start cryptsvc
schtasks /create /tn "Run Windows Update After Restart" /tr "cmd.exe /c wuauclt /detectnow && wuauclt /updatenow" /sc onstart /ru SYSTEM /f
timeout 5
shutdown /r /t 30
