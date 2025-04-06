function Get-AteraAgent {
    param ([parameter(Mandatory = $true, Position = 0)]
        [string]$ApiKey,
        [parameter(Mandatory = $false, Position = 1)]
        [switch]$All,
        [parameter(Mandatory = $false, Position = 2)]
        [int]$PageNumber = 1,
        [parameter(Mandatory = $false, Position = 3)]
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
            [string]$Uri = "https://app.atera.com/api/v3/agents?page=$PageNumber&itemsInPage=$ItemAmount";
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
}
