# Screengrab 

$Date = Get-Date; $DateTimeVid = $Date.ToString("vTrack_HH-mm-ss-ffff");

Set-Alias -Name ffmpeg -Value C:\Util.w\YT-DLP\bin\ffmpeg.exe;

ffmpeg -y -filter_complex ddagrab=1 -c:v h264_nvenc -preset p7 -tune ll -b:v 15M -bufsize 7.5M -maxrate 15M -to 02:20:00 C:\Users\Lane\Videos\$DateTimeVid.mkv