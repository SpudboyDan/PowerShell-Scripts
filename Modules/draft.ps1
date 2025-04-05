do {
	$Uri = AteraAddress;
	$Call = Invoke-RestMethod -Uri $Uri;
	$totalPages = $Call.totalPages;
	$CallData = @();
	$Uri = $Call.nextLink;
}

while ("" -ne $Call.nextLink -and $Index -lt $totalPages)
