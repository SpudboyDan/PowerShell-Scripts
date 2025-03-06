<#
$Properties = @{ RecurseSubdirectories = [bool]1; IgnoreInaccessible = [bool]1; BufferSize = [int]0; AttributesToSkip = [System.IO.FileAttributes]::None; MatchCasing = [System.IO.MatchCasing]::PlatformDefault; MatchType = [System.IO.MatchType]::Simple; MaxRecursionDepth = [int]2147483647; ReturnSpecialDirectories = [bool]1 };
$EnumerationOptions = New-Object -TypeName System.IO.EnumerationOptions -Property $Properties;
[System.Collections.Generic.List[object]]$Directory = [System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*',$EnumerationOptions);
#>

<#
class Comparer : System.Collections.Generic.IComparer[System.IO.FileInfo] {
	[int] Compare([System.IO.FileInfo] $a, [System.IO.FileInfo] $b) {
		return $b.Length.CompareTo($a.Length)
	}
}

class Folder {
	[System.IO.DirectoryInfo] $Root;
	[System.Collections.Generic.List[System.IO.FileInfo]] $Files;
	[int] $Length;
	[string] $Name;
	[int] $Hash;
	[string[]] $EnumOptions;

	Folder([string] $Path) {
		$this.Root = [System.IO.DirectoryInfo]::new($Path)
	}

	Folder([string] $Path, [comparer] $Comparer) {
		$this.Root = [System.IO.DirectoryInfo]::new($Path)
		$this.Comparer = $Comparer
	}

	[void] GetFiles([string]$Path) {
		$this.Root.EnumerateFiles('*.*')
	}

	[void] SortFilesAscending() {
		$this.Files.Sort($this.Comparer)
	}

	[void] SortFilesDescending() {
		$this.SortFilesAscending()
		$this.Files.Reverse()
	}
}
#>

$Properties = @{RecurseSubdirectories = [bool]1; IgnoreInaccessible = [bool]1;}
$EnumerationOptions = New-Object -TypeName System.IO.EnumerationOptions -Property $Properties;
$Directory = [System.Collections.Generic.List[System.IO.FileInfo]]@([System.IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*', $EnumerationOptions));
class File {
	[int32] $HashCode
	[int64] $BitLength
	[string] $FileName

	File ($FileName, $BitLength, $HashCode) {
		$this.FileName = $FileName
		$this.BitLength = $BitLength
		$this.HashCode = $HashCode
	}
}

$FileList = [System.Collections.Generic.List[File]]@();
foreach ($Object in $Directory) {
	$FileList.Add([File]::new($Object.Name, $Object.Length, $Object.GetHashCode()))
}

[Func[File, int64]]$InnerDelegate = {$args[0].BitLength};
[Func[File, string]]$OuterDelegate = {$args[0].FileName};
$Query = [System.Linq.Enumerable]::GroupBy($FileList, $InnerDelegate, $OuterDelegate);
