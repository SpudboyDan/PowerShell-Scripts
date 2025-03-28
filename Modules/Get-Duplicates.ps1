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

function Get-DuplicatesV3 {
	param ([switch]$Recurse)

	switch ($Recurse) {
		$true {
		$EnumOptions = [IO.EnumerationOptions]@{RecurseSubdirectories = $true};
		$Directory = [List[IO.FileInfo]]@([IO.DirectoryInfo]::new("$PWD").EnumerateFiles("*.*", $EnumOptions));
		[Func[IO.FileInfo, int64]]$InnerDelegateLength = {$args[0].Length};
		[Func[IO.FileInfo, string]]$OuterDelegateName = {$args[0].FullName};
		$LengthGroups = [Linq.Enumerable]::GroupBy($Directory, $InnerDelegateLength, $OuterDelegateName);

		[Func[Linq.IGrouping`2[Int64, String], bool]]$FileDelegate = {$args[0].Count -gt 1 -and $args[0].Key -le 2147483591};
		$FileGroups = [Linq.Enumerable]::Where($LengthGroups, $FileDelegate);
		$LengthGroups.Dispose();

		[Func[TinyHashInfo, string]]$InnerDelegateHash = {$args[0].Hash};
		[Func[TinyHashInfo, string]]$OuterDelegatePath = {$args[0].Path};
		$Hashes = [List[TinyHashInfo]]@($FileGroups.ForEach({
			$_.ForEach({
				[TinyHashInfo]@{Hash = [BitConverter]::ToString([IO.Hashing.XxHash3]::Hash([IO.File]::ReadAllBytes("$_"))).Replace("-", ""); Path = "$_";}
			})
		}));
		$FileGroups.Dispose();
		$HashGroups = [Linq.Enumerable]::GroupBy($Hashes, $InnerDelegateHash, $OuterDelegatePath);
		[GC]::Collect();

		[Func[Linq.IGrouping`2[string, string], bool]]$DuplicatesDelegate = {$args[0].Count -gt 1};
		[Func[Linq.IGrouping`2[string, string], string]]$OrderedDelegate = {$args[0]};
		$HashGroupDuplicates = [Linq.Enumerable]::Where($HashGroups, $DuplicatesDelegate);
		$HashGroups.Dispose();

		$HashDuplicatesOrdered = [Linq.Enumerable]::OrderBy($HashGroupDuplicates, $OrderedDelegate);
		$HashGroupDuplicates.Dispose();
		$HashDuplicatesOrdered.ForEach({
			$_.Key, "----------------", $_.Replace("$PWD\", ""), "`n"
		});
		$HashDuplicatesOrdered.Dispose();
		}

		$false {
		$EnumOptions = [IO.EnumerationOptions]@{RecurseSubdirectories = $false};
		$Directory = [List[IO.FileInfo]]@([IO.DirectoryInfo]::new("$PWD").EnumerateFiles("*.*", $EnumOptions));
		[Func[IO.FileInfo, int64]]$InnerDelegateLength = {$args[0].Length};
		[Func[IO.FileInfo, string]]$OuterDelegateName = {$args[0].FullName};
		$LengthGroups = [Linq.Enumerable]::GroupBy($Directory, $InnerDelegateLength, $OuterDelegateName);

		[Func[Linq.IGrouping`2[Int64, String], bool]]$FileDelegate = {$args[0].Count -gt 1 -and $args[0].Key -le 2147483591};
		$FileGroups = [Linq.Enumerable]::Where($LengthGroups, $FileDelegate);
		$LengthGroups.Dispose();

		[Func[TinyHashInfo, string]]$InnerDelegateHash = {$args[0].Hash};
		[Func[TinyHashInfo, string]]$OuterDelegatePath = {$args[0].Path};
		$Hashes = [List[TinyHashInfo]]@($FileGroups.ForEach({
			$_.ForEach({
				[TinyHashInfo]@{Hash = [BitConverter]::ToString([IO.Hashing.XxHash3]::Hash([IO.File]::ReadAllBytes("$_"))).Replace("-", ""); Path = "$_";}
			})
		}));
		$FileGroups.Dispose();
		$HashGroups = [Linq.Enumerable]::GroupBy($Hashes, $InnerDelegateHash, $OuterDelegatePath);
		[GC]::Collect();

		[Func[Linq.IGrouping`2[string, string], bool]]$DuplicatesDelegate = {$args[0].Count -gt 1};
		[Func[Linq.IGrouping`2[string, string], string]]$OrderedDelegate = {$args[0]};
		$HashGroupDuplicates = [Linq.Enumerable]::Where($HashGroups, $DuplicatesDelegate);
		$HashGroups.Dispose();

		$HashDuplicatesOrdered = [Linq.Enumerable]::OrderBy($HashGroupDuplicates, $OrderedDelegate);
		$HashGroupDuplicates.Dispose();
		$HashDuplicatesOrdered.ForEach({
			$_.Key, "----------------", $_.Replace("$PWD\", ""), "`n"
		});
		$HashDuplicatesOrdered.Dispose();
		}
	}
}
