class HashPath : Microsoft.PowerShell.Commands.FileHashInfo {
	[string]	$Algorithm
	[string]	$FileHash
	[string]	$FilePath

	HashPath([string]$Algorithm, [string]$FileHash, [string]$FilePath) {
		$this.Algorithm = $Algorithm; $this.Hash = $FileHash; $this.Path = $FilePath; 
	}
}
