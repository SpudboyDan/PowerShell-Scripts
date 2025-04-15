function Get-AteraAgent {
	[CmdletBinding()]
    param ([Parameter(Mandatory = $true, Position = 0)]
        [string]$ApiKey,
        [Parameter(Mandatory = $false, Position = 1)]
        [switch]$All,
	[Parameter(Mandatory = $false, Position = 2)]
	[ValidateNotNull()]
	[long]$CustomerID = 0,
        [Parameter(Mandatory = $false, Position = 3)]
        [int]$PageNumber = 1,
        [Parameter(Mandatory = $false, Position = 4)]
        [int]$ItemAmount = 20)

    $FilteredResults = @{Property =`
        "AppViewUrl",
        "FolderName",
        "CustomerID",
        "CustomerName",
        "AgentName",
        "MachineName",
        "Online",
        "LastSeen",
        "Processor",
        "Memory",
        "Vendor",
        "VendorSerialNumber",
        "VendorBrandModel",
        "BiosManufacturer",
        "BiosVersion",
        "BiosReleaseDate",
        "HardwareDisks",
        "BatteryInfo",
        "OS",
        "LastRebootTime",
        "OSVersion",
        "OSBuild",
        "LastLoginUser"
    };

    switch ($All) {
        $true {
            [string]$Uri = "https://app.atera.com/api/v3/agents?page=1&itemsInPage=50";
            $FirstCallParams = @{
                Uri         = $Uri;
                Headers     = @{
                    "method"          ="GET"
                    "scheme"          ="https"
                    "accept"          ="application/json;charset=utf-8,*/*"
                    "accept-encoding" ="gzip, deflate, br, zstd"
                    "accept-language" ="en-US,en;q=0.9"
                    "x-api-key"       ="$ApiKey"
                };
                ErrorAction = "Stop";
            }
            [long]$TotalPages = (Invoke-RestMethod @FirstCallParams).totalPages
   
            for ([long]$Index = 1; $Index -le $TotalPages; $Index++) {
                [string]$Uri = "https://app.atera.com/api/v3/agents?page=$Index&itemsInPage=50";
                $RestParams = @{
                    Uri         = $Uri;
                    Headers     = @{
                        "method"          ="GET"
                        "scheme"          ="https"
                        "accept"          ="application/json;charset=utf-8,*/*"
                        "accept-encoding" ="gzip, deflate, br, zstd"
                        "accept-language" ="en-US,en;q=0.9"
                        "x-api-key"       ="$ApiKey"
                    };
                    ErrorAction = "Stop";
                }

                (Invoke-RestMethod @RestParams).items | Select-Object @FilteredResults;
            }
        }
        $false {
            [string]$Uri = "https://app.atera.com/api/v3/agents/customer/$CustomerId`?page=$PageNumber&itemsInPage=$ItemAmount";
            $RestParams = @{
                Uri         = $Uri;
                Headers     = @{
                    "method"          ="GET"
                    "scheme"          ="https"
                    "accept"          ="application/json;charset=utf-8,*/*"
                    "accept-encoding" ="gzip, deflate, br, zstd"
                    "accept-language" ="en-US,en;q=0.9"
                    "x-api-key"       ="$ApiKey"
                };
                ErrorAction = "Stop";
            }
	    try {
            $Call = Invoke-RestMethod @RestParams;
	    }
	    catch {
		    $PSCmdlet.ThrowTerminatingError($PSItem);
	    }

	    $Call.items | Select-Object @FilteredResults;
	    $PageItemResults = @{Object =`
                "Page: $($Call.page)`n",
                "`bItems in page: $($Call.itemsInPage)`n",
                "`bTotal item count: $($Call.totalItemCount)`n",
                "`bTotal pages: $($Call.totalPages)`n";
                ForegroundColor         = "Yellow"
	    };

	    Write-Host @PageItemResults;
        }
    }
}
