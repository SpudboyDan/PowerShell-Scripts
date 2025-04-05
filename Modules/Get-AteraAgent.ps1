function Get-AteraAgent {
    [CmdletBinding()]
    param ([parameter(Mandatory = $true, Position = 0)]
        [string]$ApiKey,
        [parameter(Mandatory = $false, Position = 1)]
        [switch]$All,
        [parameter(Mandatory = $false, Position = 2)]
        [int]$PageNumber = 1,
        [parameter(Mandatory = $false, Position = 3)]
        [int]$ItemAmount = 20)

    switch ($All) {
        $true {
            $FirstCallParams = @{
                Uri         = "https://app.atera.com/api/v3/agents?page=1&itemsInPage=50";
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
                $Call = Invoke-RestMethod @FirstCallParams;
                for ($Index = 1; $Index -le $Call.totalPages; $Index++) {
                    $RestParams = @{
                        Uri         = $Call.nextLink;
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
                    $Call.items | Select-Object @FilteredResults;
                };
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($PSItem);
            }
        };

        $false {
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
