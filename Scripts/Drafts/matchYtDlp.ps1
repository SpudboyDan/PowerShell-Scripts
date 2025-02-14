Set-Alias -Name "yt-dlp" -Value "C:\Util.w\yt-dlp\bin\yt-dlp.exe";
[string[]]$files = (Invoke-WebRequest -Uri "https://archive.org/download/ikaos-som-dragon-ball-z-complete-001-291-dragon-box-merge-multi-audio-v-3").Links.Href | Select-String -Pattern "Dragon%20Ball%20Z.\d\d\d.DBOX.480p.x264-iKaos[a-zA-Z0-9%]+.mkv";

foreach ($file in $files)
{
	yt-dlp --sleep-interval 30 "https://archive.org/download/ikaos-som-dragon-ball-z-complete-001-291-dragon-box-merge-multi-audio-v-3/$file"
}
