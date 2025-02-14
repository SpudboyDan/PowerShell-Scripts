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
