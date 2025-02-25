$properties = @{ RecurseSubdirectories = [bool]1; IgnoreInaccessible = [bool]1; BufferSize = [int]0; AttributesToSkip = [System.IO.FileAttributes]::None; MatchCasing = [System.IO.MatchCasing]::PlatformDefault; MatchType = [System.IO.MatchType]::Simple; MaxRecursionDepth = [int]2147483647; ReturnSpecialDirectories = [bool]1 };
$enumerationOptions = New-Object -TypeName System.IO.EnumerationOptions -Property $properties;
[System.Collections.Generic.List[object]]$directory = [System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*',$enumerationOptions);
$results = [System.Collections.Generic.Dictionary[string,string]]::new();

for ($i = 0; $i -le $directory.Count; $i++)
{
	foreach ($file in $directory)
	{
		if ($file.Name -eq $directory[$i].Name)
		{
			continue
		}
		else
		{
			if ($file.Length -eq $directory[$i].Length)
			{
				if ((Get-FileHash -Path $file.Name -Algorithm SHA256).Hash -eq (Get-FileHash -Path $directory[$i].Name -Algorithm SHA256).Hash)
				{
					try
					{
						$null = $results.Add($file.Name,((Get-FileHash -Path $file.Name -Algorithm SHA256).Hash));
						$null = $results.Add($directory[$i].Name,((Get-FileHash -Path $directory[$i].Name -Algorithm SHA256).Hash));
					}
					catch
					{
						continue
					}
				}
				else {continue}
			}
			else {continue}
		}
	}
}

$results
