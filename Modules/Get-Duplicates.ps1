using namespace System;
using namespace System.Collections.Generic;
using namespace System.Security.Cryptography;

class TinyHashInfo : Microsoft.PowerShell.Commands.FileHashInfo {
	[string]	$FileHash
	[string]	$FilePath
	
	TinyHashInfo([string]$FileHash, [string]$FilePath) {
		$this.Hash = $FileHash; $this.Path = $FilePath; 
	}
}

function Get-DuplicatesV3
{
	param ([switch]$Recurse)

	switch ($Recurse)
	{
		$true {$EnumOptions = [IO.EnumerationOptions]::new();
		$EnumOptions.RecurseSubdirectories = $true;
		$Directory = [List[IO.FileInfo]]@([IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*', $EnumOptions));
		[Func[IO.FileInfo, int64]]$InnerDelegateLength = {$args[0].Length};
		[Func[IO.FileInfo, string]]$OuterDelegateName = {$args[0].FullName};
		$LengthGroups = [Linq.Enumerable]::Where([Linq.Enumerable]::GroupBy($Directory, $InnerDelegateLength, $OuterDelegateName), [Func[Linq.IGrouping`2[Int64, String], bool]] {$args[0].Count -gt 1});
		[Func[TinyHashInfo, string]]$InnerDelegateHash = {$args[0].Hash};
		[Func[TinyHashInfo, string]]$OuterDelegatePath = {$args[0].Path};
		$Hashes = [List[TinyHashInfo]]@($LengthGroups.ForEach({$_.ForEach({[TinyHashInfo]::new([string]([BitConverter]::ToString([SHA256]::HashData([IO.File]::OpenRead($_))).Replace("-", "")), "$_")})}));

		$HashGroups = [Linq.Enumerable]::OrderBy([Linq.Enumerable]::Where([Linq.Enumerable]::GroupBy($Hashes, $InnerDelegateHash, $OuterDelegatePath),`
		[Func[Linq.IGrouping`2[string, string], bool]] {$args[0].Count -gt 1}), [Func[Linq.IGrouping`2[string, string], string]] {$args[0]});
		$Prettier = {$HashGroups.ForEach({$_.Key, ("-"*64), $_.Replace("$PWD\", ""), "`n"})};
		& $Prettier;}

		$false {$Directory = [List[IO.FileInfo]]@([IO.DirectoryInfo]::new("$PWD").EnumerateFiles('*.*'));
		[Func[IO.FileInfo, int64]]$InnerDelegateLength = {$args[0].Length};
		[Func[IO.FileInfo, string]]$OuterDelegateName = {$args[0].FullName};
		$LengthGroups = [Linq.Enumerable]::Where([Linq.Enumerable]::GroupBy($Directory, $InnerDelegateLength, $OuterDelegateName), [Func[Linq.IGrouping`2[Int64, String], bool]] {$args[0].Count -gt 1});
		[Func[TinyHashInfo, string]]$InnerDelegateHash = {$args[0].Hash};
		[Func[TinyHashInfo, string]]$OuterDelegatePath = {$args[0].Path};
		$Hashes = [List[TinyHashInfo]]@($LengthGroups.ForEach({$_.ForEach({[TinyHashInfo]::new([string]([BitConverter]::ToString([SHA256]::HashData([IO.File]::OpenRead($_))).Replace("-", "")), "$_")})}));

		$HashGroups = [Linq.Enumerable]::OrderBy([Linq.Enumerable]::Where([Linq.Enumerable]::GroupBy($Hashes, $InnerDelegateHash, $OuterDelegatePath),`
		[Func[Linq.IGrouping`2[string, string], bool]] {$args[0].Count -gt 1}), [Func[Linq.IGrouping`2[string, string], string]] {$args[0]});
		$Prettier = {$HashGroups.ForEach({$_.Key, ("-"*64), $_.Replace("$PWD\", ""), "`n"})};
		& $Prettier;}
	}
}
