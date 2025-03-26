using namespace System;
using namespace System.Collections.Generic;
using namespace System.Security.Cryptography;
using assembly "C:\Program Files\PackageManagement\NuGet\Packages\System.IO.Hashing.9.0.3\lib\net9.0\System.IO.Hashing.dll";

class TinyHashInfo : Microsoft.PowerShell.Commands.FileHashInfo {
	# Class properties
	[string]	$FileHash
	[string]	$FilePath
	# Default constructor
	TinyHashInfo() {$this.Init(@{})}
	# Convenience constructor from hashtable
	TinyHashInfo([hashtable]$Properties) {$this.Init($Properties)}
	# Common constructor
	TinyHashInfo([string]$FileHash, [string]$FilePath) {
		$this.Init(@{Hash = $FileHash; Path = $FilePath})
	}
	# Shared initializer method
	[void] Init([hashtable]$Properties) {
		foreach ($Property in $Properties.Keys) {
			$this.$Property = $Properties.$Property
		}
	}
}

function Get-DuplicatesV3
{
	param ([switch]$Recurse)

	switch ($Recurse)
	{
		$true {$EnumOptions = [IO.EnumerationOptions]@{RecurseSubdirectories = $true};
		$Directory = [List[IO.FileInfo]]@([IO.DirectoryInfo]::new("$PWD").EnumerateFiles("*.*", $EnumOptions));
		[Func[IO.FileInfo, int64]]$InnerDelegateLength = {$args[0].Length};
		[Func[IO.FileInfo, string]]$OuterDelegateName = {$args[0].FullName};
		$LengthGroups = [Linq.Enumerable]::Where([Linq.Enumerable]::GroupBy($Directory, $InnerDelegateLength, $OuterDelegateName), [Func[Linq.IGrouping`2[Int64, String], bool]] {$args[0].Count -gt 1});

		[Func[TinyHashInfo, string]]$InnerDelegateHash = {$args[0].Hash};
		[Func[TinyHashInfo, string]]$OuterDelegatePath = {$args[0].Path};
		$Hashes = [List[TinyHashInfo]]@($LengthGroups.ForEach({$_.ForEach({[TinyHashInfo]@{Hash = [BitConverter]::ToString([IO.Hashing.XxHash3]::Hash([IO.File]::ReadAllBytes("$_"))).Replace("-", ""); Path = "$_";}})}));
		$HashGroups = [Linq.Enumerable]::OrderBy([Linq.Enumerable]::Where([Linq.Enumerable]::GroupBy($Hashes, $InnerDelegateHash, $OuterDelegatePath),`
		[Func[Linq.IGrouping`2[string, string], bool]] {$args[0].Count -gt 1}), [Func[Linq.IGrouping`2[string, string], string]] {$args[0]});
		& {$HashGroups.ForEach({$_.Key, ("-"*16), $_.Replace("$PWD\", ""), "`n"})}};

		$false {$Directory = [List[IO.FileInfo]]@([IO.DirectoryInfo]::new("$PWD").EnumerateFiles("*.*"));
		[Func[IO.FileInfo, int64]]$InnerDelegateLength = {$args[0].Length};
		[Func[IO.FileInfo, string]]$OuterDelegateName = {$args[0].FullName};
		$LengthGroups = [Linq.Enumerable]::Where([Linq.Enumerable]::GroupBy($Directory, $InnerDelegateLength, $OuterDelegateName), [Func[Linq.IGrouping`2[Int64, String], bool]] {$args[0].Count -gt 1});

		[Func[TinyHashInfo, string]]$InnerDelegateHash = {$args[0].Hash};
		[Func[TinyHashInfo, string]]$OuterDelegatePath = {$args[0].Path};
		$Hashes = [List[TinyHashInfo]]@($LengthGroups.ForEach({$_.ForEach({[TinyHashInfo]@{Hash = [BitConverter]::ToString([IO.Hashing.XxHash3]::Hash([IO.File]::ReadAllBytes("$_"))).Replace("-", ""); Path = "$_";}})}));
		$HashGroups = [Linq.Enumerable]::OrderBy([Linq.Enumerable]::Where([Linq.Enumerable]::GroupBy($Hashes, $InnerDelegateHash, $OuterDelegatePath),`
		[Func[Linq.IGrouping`2[string, string], bool]] {$args[0].Count -gt 1}), [Func[Linq.IGrouping`2[string, string], string]] {$args[0]});
		& {$HashGroups.ForEach({$_.Key, ("-"*16), $_.Replace("$PWD\", ""), "`n"})}};
	}
}
