Set-Alias -Name yt-dlp -Value C:\Util.w\yt-dlp\bin\yt-dlp.exe;
$links = (Invoke-WebRequest -Uri "https://tubitv.com/category/recently_added").Links.Href | Select-String -Pattern "/movies/[0-9]+/[a-z0-9\-]+";

foreach($movie in $links)
{
yt-dlp "https://tubitv.com$movie"
}
