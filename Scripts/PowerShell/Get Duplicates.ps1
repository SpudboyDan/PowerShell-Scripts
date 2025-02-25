$fileHashTable = [System.Collections.HashTable]::new();
$fileHashTableDuplicates = [System.Collections.ArrayList]::new();
$enumeratedFiles = [System.IO.DirectoryInfo]::new($PWD).EnumerateFiles();
$falseDuplicates = [System.Collections.HashTable]::new();
$trueDuplicates = [System.Collections.ArrayList]::new();

foreach ($file in $enumeratedFiles)
{
	try
	{
		$null = $fileHashTable.Add($file.Length,$file.Name);
	}
	
	catch
	{
		$null = $fileHashTableDuplicates.Add($file.Name);
	}
}
$files = [System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*',[System.IO.SearchOption]::AllDirectories)
$files.EnumerateFiles('*.*',[System.IO.SearchOption]::AllDirectories)
$objectList = [System.Collections.Generic.Dictionary[string,object]]::new()
$grouper = [Microsoft.PowerShell.Commands.GroupObjectCommand]::new()
$grouper.AsHashTable = [bool]1
$grouper.InputObject = [System.Management.Automation.PSObject]::new($collection)
$grouper.Property = [string]$collection.Length
$collection = [System.Collections.ObjectModel.Collection[PSObject]]::new()
$collection = [System.Collections.Generic.SortedList[string,long]]::new()
$recursionOptions = [System.IO.EnumerationOptions]::new()
$directory = [System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*',$recursionOptions)

$properties = @{ RecurseSubdirectories = [bool]1; IgnoreInaccessible = [bool]1; BufferSize = [int]0; AttributesToSkip = [System.IO.FileAttributes]::None; MatchCasing = [System.IO.MatchCasing]::PlatformDefault; MatchType = [System.IO.MatchType]::Simple; MaxRecursionDepth = [int]2147483647; ReturnSpecialDirectories = [bool]1 };
$enumerationOptions = New-Object -TypeName System.IO.EnumerationOptions -Property $properties;
$directory = [System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*',$enumerationOptions);
