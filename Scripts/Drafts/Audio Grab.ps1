# Audiograb

$Date = Get-Date; $DateTimeAudio = $Date.ToString("aTrack_HH-mm-ss-ffff"); 

Set-Alias -Name ffmpeg -Value C:\Util.w\YT-DLP\bin\ffmpeg.exe;

ffmpeg -y -f dshow -i audio="Stereo Mix (Realtek(R) Audio)" -rtbufsize 2147M -b:a 128k -c:a aac C:\Users\Lane\Videos\$DateTimeAudio.mkv