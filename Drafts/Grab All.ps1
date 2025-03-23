$Date = Get-Date;

$DateTimeAudio = $Date.ToString("aTrack_HH-mm-ss-ffff");

$DateTimeVid = $Date.ToString("vTrack_HH-mm-ss-ffff");

Set-Alias -Name ffmpeg -Value C:\Util.w\YT-DLP\bin\ffmpeg.exe;

Start-Job -FilePath C:\Temp\screengrab.ps1; Start-Job -FilePath C:\Temp\audiograb.ps1