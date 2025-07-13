function Get-KHInsiderMP3 {
    [CmdletBinding()]
    param ([Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [string]$Uri)

    try {
        $links = [System.Collections.Generic.HashSet[string]]@((Invoke-WebRequest -Uri $Uri).Links.Href.Where({ $_ -match "/game-soundtracks/album/[a-z0-9\%\-\.]+/[a-z0-9\%\-\.]+" }));
        [string]$linkPattern = $links.ForEach({ $_ })[1];
        [string]$subPattern = $linkPattern.Split("/")[3];

        $mp3Files = [System.Collections.Generic.List[string]]@(foreach ($link in $links) {
                (Invoke-WebRequest -Uri "https://downloads.khinsider.com$link").Links.Href.Where({ $_ -match "https://[a-z0-9\%\-\./]+$subPattern[a-z0-9\%\-\./]+mp3" }) 
            });

        $flacFiles = [System.Collections.Generic.List[string]]@(foreach ($link in $links) {
                (Invoke-WebRequest -Uri "https://downloads.khinsider.com$link").Links.Href.Where({ $_ -match "https://[a-z0-9\%\-\./]+$subPattern[a-z0-9\%\-\./]+flac" })
            });
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem);
    }

    try {
        if ($flacFiles.Count -ne 0) {
            $flacDir = "$($subPattern.Replace('-', ' ')) FLAC";
            New-Item -ItemType Directory -Path "$env:USERPROFILE/Downloads" -Name $flacDir;
            foreach ($file in $flacFiles) {
		[int]$urlSplitCount = $file.Split('/').Count;
		$sanitizedFileName = [System.Web.HttpUtility]::UrlDecode($file).Split('/')[($urlSplitCount - 1)].Replace('?', '？').Replace('"', '“');
                Invoke-WebRequest -Uri $file -OutFile "$env:USERPROFILE/Downloads/$flacDir/$sanitizedFileName";
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem);
    }

    try {
        if ($mp3Files.Count -ne 0) {
            $mp3Dir = "$($subPattern.Replace('-', ' ')) MP3";
            New-Item -ItemType Directory -Path "$env:USERPROFILE/Downloads" -Name $mp3Dir;
            foreach ($file in $mp3Files) {
		[int]$urlSplitCount = $file.Split('/').Count;
		$sanitizedFileName = [System.Web.HttpUtility]::UrlDecode($file).Split('/')[($urlSplitCount - 1)].Replace('?', '？').Replace('"', '“');
                Invoke-WebRequest -Uri $file -OutFile "$env:USERPROFILE/Downloads/$mp3Dir/$sanitizedFileName";
            }
        }
    }

    catch {
        $PSCmdlet.ThrowTerminatingError($PSItem);
    }
}
