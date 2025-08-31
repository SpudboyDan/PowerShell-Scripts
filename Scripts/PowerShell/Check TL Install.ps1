#*================================================================================
# Check ThreatLocker Install
#*================================================================================

# Sets variable for the ThreatLocker service name.
$service = Get-Service -Name ThreatLockerService -ErrorAction SilentlyContinue;

# Checks for the ThreatLocker Service and throws an error if found.
if ($service.Name -eq "ThreatLockerService") {
    throw "ThreatLocker is still installed!";
}

else {
    Write-Host "The ThreatLocker service was not found on $env:COMPUTERNAME.";
}
