[Net.ServicePointManager]::SecurityProtocol = "Tls12"

##
##
## DO NOT EDIT ANYTHING BELOW THIS
##
##

## Set Variables
$uri = "https://api.d.threatlocker.com/getgroupkey.ashx"
$organizationName = Read-Host -Prompt "Please specify the Organization Name"
$groupName = "Workstations"
$identifier = "152b346c-6432-4fc4-af4b-cb1288df9138"


## Verify Identifier is added
if ($identifier -eq "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX") {
    Write-Output "Identifier required";
    Exit 1;
}

## Check if service exists and is running
$service = Get-Service -Name ThreatLockerService -ErrorAction SilentlyContinue;

if ($service.Name -eq "ThreatLockerService" -and $service.Status -ne "Running") {
    ## If service exists and is not running, start the service
    Start-Service ThreatLockerService;
}

$service = Get-Service -Name ThreatLockerService -ErrorAction SilentlyContinue;

if ($service.Status -eq "Running") {
    ## If the service is running, exit the script
    Write-Output "Service already present";
    Exit 0;
} 
else {
    ## Check the OS type
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    
    if ($osInfo.ProductType -ne 1) {
        ## If not a workstations, set the group to named computer group
        $groupName = {[ComputerGroup]};
    }
}

## Attempt to get the group id
try {
    $headers = @{'Authorization'=$identifier;'OrganizationName'=$organizationName;'GroupName'=$groupName}; 
    $response = (Invoke-RestMethod -Method 'Post' -uri $uri -Headers $headers -Body ''); 
    $groupId = $response.split([Environment]::NewLine)[0].split(':')[1].trim();
    # Process the group ID here
}
catch {
    Write-Output "Failed to retrive group ID from API endpoint: $_";
    Exit 1;
}

## Verify the output from the group id
if ($groupId.Length -eq 24) {
    ## Check if C:\Temp directory exists and create if not
    if (!(Test-Path "C:\Temp")) {
        mkdir "C:\Temp";
    }

    ## Check the OS architecture and download the correct installer
    try {
        if ([Environment]::Is64BitOperatingSystem) {
            $downloadURL = "https://api.threatlocker.com/installers/threatlockerstubx64.exe";
        }
        else {
            $downloadURL = "https://api.threatlocker.com/installers/threatlockerstubx86.exe";
        }

        $localInstaller = "C:\Temp\ThreatLockerStub.exe";

        Invoke-WebRequest -Uri $downloadURL -OutFile $localInstaller;
    
    }
    catch {
        Write-Output "Failed to get download the installer";
        Exit 1;
    }

    ## Attempt install
    try {
        & C:\Temp\ThreatLockerStub.exe Instance="D" InstallKey=$groupId Company=$organizationName groupName=$groupName;
    }
    catch {
        Write-Output "Installation Failed";
        Exit 1
    }

    ## Verify install
    $service = Get-Service -Name ThreatLockerService -ErrorAction SilentlyContinue;

    if ($service.Name -eq "ThreatLockerService" -and $service.Status -eq "Running") {
        Write-Output "Installation successful";
        Exit 0;
    }
    else {
        ## Check the OS type
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    
        if ($osInfo.ProductType -ne 1) {
            Write-Output "Installation Failed";
            Exit 1
        }
    }
}
else {
    Write-Output "Unable to get correct group id";
    Exit 1;
}