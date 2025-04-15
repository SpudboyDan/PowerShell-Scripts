function Get-AteraCustomer {
    [CmdletBinding()]
    param ([Parameter(Mandatory = $true, Position = 0)]
        [string]$ApiKey,
        [Parameter(Mandatory = $false, Position = 1)]
        [switch]$All,
        [Parameter(Mandatory = $false, Position = 2)]
        [int]$PageNumber = 1,
        [Parameter(Mandatory = $false, Position = 3)]
        [int]$ItemAmount = 20)

    $RestParams = @{
        Uri         = "https://app.atera.com/api/v3/customers?page=$PageNumber&itemsInPage=$ItemAmount";
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

    $FilteredResults = @{Property =`
        "CustomerID",
        "CustomerName"
    };

    $Call.items | Select-Object @FilteredResults | Sort-Object -Property CustomerName;

    $PageItemResults = @{Object =`
        "Page: $($Call.page)`n",
        "`bItems in page: $($Call.itemsInPage)`n",
        "`bTotal item count: $($Call.totalItemCount)`n",
        "`bTotal pages: $($Call.totalPages)`n";
        ForegroundColor         = "Yellow"
    };

    Write-Host @PageItemResults;
}
