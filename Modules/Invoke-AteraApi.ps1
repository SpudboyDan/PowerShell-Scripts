function Invoke-AteraApi {
    param ([parameter(Mandatory = $true, Position = 0)]
        [string]$Key,
        [parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Agents", "Customers", "CustomerAgents", "MachineByName")]
        [string]$Query,
        [parameter(Mandatory = $false, Position = 2)]
        [long]$CustomerId,
        [parameter(Mandatory = $false, Position = 3)]
        [string]$MachineName,
        [parameter(Mandatory = $false, Position = 4)]
        [int]$PageNumber = 1,
        [parameter(Mandatory = $false, Position = 5)]
        [int]$ItemAmount = 20)

    switch ($Query) {
        "Agents" {
            $RestParams = @{
                Uri         = "https://app.atera.com/api/v3/agents?page=$PageNumber&itemsInPage=$ItemAmount";
                Headers     = @{
                    "method"          ="GET"
                    "scheme"          ="https"
                    "accept"          ="application/json;charset=utf-8,*/*"
                    "accept-encoding" ="gzip, deflate, br, zstd"
                    "accept-language" ="en-US,en;q=0.9"
                    "x-api-key"       ="$Key"
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

            $PageItemResults = @{Object =`
                "Page: $($Call.page)`n",
                "`bItems in page: $($Call.itemsInPage)`n",
                "`bTotal item count: $($Call.totalItemCount)`n",
                "`bTotal pages: $($Call.totalPages)`n";
                ForegroundColor         = "Yellow"
            };

            Write-Host @PageItemResults;
        }

        "Customers" {
            $RestParams = @{
                Uri         = "https://app.atera.com/api/v3/customers?page=$PageNumber&itemsInPage=$ItemAmount";
                Headers     = @{
                    "method"          ="GET"
                    "scheme"          ="https"
                    "accept"          ="application/json;charset=utf-8,*/*"
                    "accept-encoding" ="gzip, deflate, br, zstd"
                    "accept-language" ="en-US,en;q=0.9"
                    "x-api-key"       ="$Key"
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

        "CustomerAgents" {
            $RestParams = @{
                Uri         = "https://app.atera.com/api/v3/agents/customer/$CustomerId`?page=$PageNumber&itemsInPage=$ItemAmount";
                Headers     = @{
                    "method"          ="GET"
                    "scheme"          ="https"
                    "accept"          ="application/json;charset=utf-8,*/*"
                    "accept-encoding" ="gzip, deflate, br, zstd"
                    "accept-language" ="en-US,en;q=0.9"
                    "x-api-key"       ="$Key"
                };
                ErrorAction = "Stop";
            }

            try {
                $Call = Invoke-RestMethod @RestParams;
                if ($Call.totalItemCount -eq 0) {
                    throw "Customer with ID '$CustomerId' was not found"
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($PSItem);
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

            $PageItemResults = @{Object =`
                "Page: $($Call.page)`n",
                "`bItems in page: $($Call.itemsInPage)`n",
                "`bTotal item count: $($Call.totalItemCount)`n",
                "`bTotal pages: $($Call.totalPages)`n";
                ForegroundColor         = "Yellow"
            };

            Write-Host @PageItemResults;
        }

        "MachineByName" {
            $RestParams = @{
                Uri         = "https://app.atera.com/api/v3/agents/machine/$MachineName`?page=$PageNumber&itemsInPage=$ItemAmount";
                Headers     = @{
                    "method"          ="GET"
                    "scheme"          ="https"
                    "accept"          ="application/json;charset=utf-8,*/*"
                    "accept-encoding" ="gzip, deflate, br, zstd"
                    "accept-language" ="en-US,en;q=0.9"
                    "x-api-key"       ="$Key"
                };
                ErrorAction = "Stop";
            }

            try {
                $Call = Invoke-RestMethod @RestParams;
                if ($Call.totalItemCount -eq 0) {
                    throw "Machine '$MachineName' was not found."
                };
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($PSItem);
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
        }
    }
}
