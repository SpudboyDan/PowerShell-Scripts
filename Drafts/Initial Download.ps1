Set-Alias -Name "yt-dlp" -Value "C:\Util.w\yt-dlp\bin\yt-dlp.exe";
[string[]]$links = (Invoke-WebRequest -Uri "https://archive.org/details/initial-d-third-stage-720p-dark-dream").Links.Href | Select-String -Pattern "/download/initial-d-third-stage-720p-dark-dream/Initial%20D%20Complete/Initial%20D%20[-/%a-zA-Z0-9]+.mkv";

foreach ($link in $links)
{
	yt-dlp -I 1 "https://archive.org/details/initial-d-third-stage-720p-dark-dream$link"
}
