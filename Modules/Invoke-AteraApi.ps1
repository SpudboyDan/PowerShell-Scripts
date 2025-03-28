class ApiResults {
	# Class properties
	[int]	$PageNum
	[int]	$ItemNum
}

function Invoke-AteraApi {
	param ([parameter(Mandatory = $true, Position = 0)]
		[string]$Key,
		[parameter(Mandatory = $true, Position = 1)]
		[ValidateSet("Agents", "Customers", "CustomerAgents", "CustomerById", "MachineByName")]
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
		"Agents" 	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}
				}

		"Customers"	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/customers?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}
				}

	"CustomerAgents"	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents/customer/$CustomerId`?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}
				}

		"CustomerById"	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/customers/$CustomerId" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}
				}

		"MachineByName"	{Invoke-RestMethod -Uri "https://app.atera.com/api/v3/agents/machine/$MachineName`?page=$PageNumber&itemsInPage=$ItemAmount" -Headers @{
					"method"="GET"
					"scheme"="https"
  					"accept"="application/json;charset=utf-8,*/*"
  					"accept-encoding"="gzip, deflate, br, zstd"
  					"accept-language"="en-US,en;q=0.9"
  					"x-api-key"="$Key"}
				}
		  	}
}
