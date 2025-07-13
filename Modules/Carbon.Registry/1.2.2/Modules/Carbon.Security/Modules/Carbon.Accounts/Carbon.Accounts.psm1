# Copyright WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

using namespace System.ComponentModel
using namespace System.Runtime.InteropServices
using namespace System.Security.Principal

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

# Functions should use $script:moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$script:moduleRoot = $PSScriptRoot
$psModulesDirPath = Join-Path -Path $script:moduleRoot -ChildPath 'Modules' -Resolve

# Import the .psm1 directly because it creates one less nested scope. PowerShell has a 10 nested scope limit.
Import-Module -Name (Join-Path -Path $psModulesDirPath -ChildPath 'PureInvoke\PureInvoke.psm1' -Resolve) `
              -Function @(
                    'Invoke-AdvapiLookupAccountName',
                    'Invoke-AdvapiLookupAccountSid',
                    'Invoke-NetApiNetLocalGroupGetMembers'
                ) `
              -Verbose:$false

enum Carbon_Accounts_Principal_Type
{
    User = 1
    Group
    Domain
    Alias
    WellKnownGroup
    DeletedAccount
    Invalid
    Unknown
    Computer
    Label
}

class Carbon_Accounts_Principal
{
    Carbon_Accounts_Principal([String] $Domain,
                             [String] $Name,
                             [SecurityIdentifier]$Sid,
                             [Carbon_Accounts_Principal_Type]$Type)
    {
        $this.Domain = $Domain;
        $this.Name = $Name;
        $this.Sid = $Sid;
        $this.Type = $Type;

        $this.FullName = $Name
        if ($Domain)
        {
            $this.FullName = "${Domain}\${Name}"
        }
    }

    [String] $Domain

    [String] $FullName

    [String] $Name

    [SecurityIdentifier] $Sid

    [Carbon_Accounts_Principal_Type] $Type

    [bool] Equals([Object] $obj)
    {
        if ($null -eq $obj -or $obj -isnot [Carbon_Accounts_Principal])
        {
            return $false;
        }

        return $this.Sid.Equals($obj.Sid);
    }

    [String] ToString()
    {
        return $this.FullName
    }
}

# Store each of your module's functions in its own file in the Functions
# directory. On the build server, your module's functions will be appended to
# this file, so only dot-source files that exist on the file system. This allows
# developers to work on a module without having to build it first. Grab all the
# functions that are in their own files.
$functionsPath = Join-Path -Path $script:moduleRoot -ChildPath 'Functions\*.ps1'
if( (Test-Path -Path $functionsPath) )
{
    foreach( $functionPath in (Get-Item $functionsPath) )
    {
        . $functionPath.FullName
    }
}



function ConvertTo-CSecurityIdentifier
{
    <#
    .SYNOPSIS
    Converts a string or byte array security identifier into a `System.Security.Principal.SecurityIdentifier` object.

    .DESCRIPTION
    `ConvertTo-CSecurityIdentifier` converts a SID in SDDL form (as a string), in binary form (as a byte array) into a
    `System.Security.Principal.SecurityIdentifier` object. It also accepts
    `System.Security.Principal.SecurityIdentifier` objects, and returns them back to you.

    If the string or byte array don't represent a SID, an error is written and nothing is returned.

    .LINK
    Resolve-CPrincipal

    .LINK
    Resolve-CPrincipalName

    .EXAMPLE
    ConvertTo-CSecurityIdentifier -SID 'S-1-5-21-2678556459-1010642102-471947008-1017'

    Demonstrates how to convert a a SID in SDDL into a `System.Security.Principal.SecurityIdentifier` object.

    .EXAMPLE
    ConvertTo-CSecurityIdentifier -SID (New-Object 'Security.Principal.SecurityIdentifier' 'S-1-5-21-2678556459-1010642102-471947008-1017')

    Demonstrates that you can pass a `SecurityIdentifier` object as the value of the SID parameter. The SID you passed
    in will be returned to you unchanged.

    .EXAMPLE
    ConvertTo-CSecurityIdentifier -SID $sidBytes

    Demonstrates that you can use a byte array that represents a SID as the value of the `SID` parameter.
    #>
    [CmdletBinding()]
    param(
        # The SID to convert to a `System.Security.Principal.SecurityIdentifier`. Accepts a SID in SDDL form as a
        # `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of
        # bytes.
        [Parameter(Mandatory)]
        [Object] $SID
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    try
    {
        if ( $SID -is [string])
        {
            New-Object 'Security.Principal.SecurityIdentifier' $SID
        }
        elseif ($SID -is [byte[]])
        {
            New-Object 'Security.Principal.SecurityIdentifier' $SID,0
        }
        elseif ($SID -is [Security.Principal.SecurityIdentifier])
        {
            $SID
        }
        else
        {
            $msg = "Invalid SID parameter value [$($SID.GetType().FullName)]${SID}. Only " +
                   '[System.Security.Principal.SecurityIdentifier] objects, SIDs in SDDL form as a [String], or SIDs ' +
                   'in binary form as a byte array are allowed.'
            return
        }
    }
    catch
    {
        $sidDisplayMsg = ''
        if ($SID -is [String])
        {
            $sidDisplayMsg = " ""${SID}"""
        }
        elseif ($SID -is [byte[]])
        {
            $sidDisplayMsg = " [$($SID -join ', ')]"
        }
        $msg = "Exception converting SID${sidDisplayMsg} to a [System.Security.Principal.SecurityIdentifier] " +
               'object. This usually means you passed an invalid SID in SDDL form (as a string) or an invalid SID ' +
               "in binary form (as a byte array): ${_}"
        Write-Error $msg -ErrorAction $ErrorActionPreference
        return
    }
}



function Get-CLocalGroup
{
    <#
    .SYNOPSIS
    Gets local groups.

    .DESCRIPTION
    The `Get-CLocalGroup` gets local groups. By default, it returns all local groups. To return a specific group, use
    the `Name` parameter. Wildcards supported. To get a group without using wildcard searching, use the `LiteralName`
    parameter.

    This function uses the Microsoft.PowerShell.LocalAccounts cmdlets, so is not supported on 32-bit PowerShell running
    on a 64-bit operating system.

    .EXAMPLE
    Get-CLocalGroup

    Demonstrates how to get all local groups.

    .EXAMPLE
    Get-CLocalGroup -Name 'p_*'

    Demonstrates how to get all groups that match a wildcard pattern.

    .EXAMPLE
    Get-CLocalGroup -LiteralName $name

    Demonstrates how to get a single group without doing a wildcard search by using the `LiteralName` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
        # The name of the group to get. Wildcards supported. By default, all groups are returned.
        [Parameter(Mandatory, ParameterSetName='ByWildcardPattern')]
        [String] $Name,

        # The exact name of the single group to get. Wildcards **not** supported. By default, all groups are returned.
        [Parameter(Mandatory, ParameterSetName='ByLiteralName')]
        [String] $LiteralName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $Name -and -not $LiteralName)
    {
        return Get-LocalGroup
    }

    if ($Name)
    {
        return Get-LocalGroup -Name $Name -ErrorAction $ErrorActionPreference
    }

    return Get-LocalGroup | Where-Object 'Name' -EQ $LiteralName
}


function Get-CLocalGroupMember
{
    <#
    .SYNOPSIS
    Gets the members of a local group.

    .DESCRIPTION
    The `Get-CLocalGroupMember` function gets the members of a local group. Pass the name of the group to the `Name`
    parameter. All the group's members are returned as `Carbon_Accounts_Principal` objects.

    If you want to get a specific group member, pass its name to the `Member` parameter. If the user isn't a member of
    the group, the function writes an error and returns nothing. If you want to check if a principal is a member of a
    group, use the `Test-CLocalGroupMember` function instead.

    .EXAMPLE
    Get-CLocalGroupMember -Name 'Administrators'

    Demonstrates how to get the members of a local group. In this case, all the members of the Administrators group is
    returned.

    .EXAMPLE
    Get-CLocalGroupMember -Name 'Administrators' -Member 'someuser'

    Demonstrates how to get a specific member of a local group. You probably want to use `Test-CLocalGroupMember`
    instead.
    #>
    [CmdletBinding(DefaultParameterSetName='ByWildcardName')]
    param(
        [Parameter(Mandatory, Position=0)]
        [String] $Name,

        [String] $Member
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $group = Get-CLocalGroup -LiteralName $Name
    if (-not $group)
    {
        return
    }

    $memberToFind = $null
    if ($Member)
    {
        $memberToFind = Resolve-CPrincipal -Name $Member
        if (-not $memberToFind)
        {
            return
        }
    }

    $foundMember = $false
    Invoke-NetApiNetLocalGroupGetMembers -LocalGroupName $group.Name -Level 0 |
        ForEach-Object {
            $sid = [Security.Principal.SecurityIdentifier]::New([IntPtr]$_.SidPtr)
            return Resolve-CPrincipal -Sid $sid -ErrorAction Ignore
        } |
        Where-Object {
            if ($memberToFind)
            {
                $isMember = $memberToFind.FullName -eq $_.FullName
                if ($isMember)
                {
                    $foundMember = $true
                }
                return $isMember
            }

            return $true
        } |
        Write-Output

    if ($memberToFind -and -not $foundMember)
    {
        $msg = "Principal ""$($memberToFind.FullName)"" is not a member of group ""$($group.Name)""."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
    }
}



function Install-CLocalGroup
{
    <#
    .SYNOPSIS
    Creates a new local group, or updates the settings for an existing group.

    .DESCRIPTION
    `Install-CLocalGroup` creates a local group, or, updates a group that already exists. Pass the group's name to the
    `Name` parameter and the group's description to the `Description` parameter. If the group doesn't exist, it is
    created. If it exists, the description is updated. Pass any group members to the `Member` parameter. Those accounts
    will be added to the group. Existing members will be unaffected.

    This function uses the Microsoft.PowerShell.LocalAccounts cmdlets, so is not supported on 32-bit PowerShell running
    on a 64-bit operating system.

    .EXAMPLE
    Install-CLocalGroup -Name TIEFighters -Description 'Users allowed to be TIE fighter pilots.' -Members EMPIRE\Pilots,EMPIRE\DarthVader

    If the TIE fighters group doesn't exist, it is created with the given description and default members.  If it
    already exists, its description is updated and the given members are added to it.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the group.
        [Parameter(Mandatory)]
        [String] $Name,

        # A description of the group.
        [String] $Description = '',

        # Members of the group.
        [String[]] $Member = @()
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $group = Get-LocalGroup -Name $Name -ErrorAction Ignore

    if (-not $group)
    {
        $descMsg = '.'
        if ($Description)
        {
            $descMsg = ": ${Description}"
            if (-not $descMsg.EndsWith('.'))
            {
                $descMsg = "${descMsg}."
            }
        }

        Write-Information "Creating local group ""${Name}""${descMsg}"
        New-LocalGroup -Name $Name -Description $Description
    }
    else
    {
        if ($Description -and $group.Description -ne $Description)
        {
            $groupName = Resolve-CPrincipalName -Name $group.Name
            $msg = "Updating local group ""${groupName}"" description.  ""$($group.Description)"" -> ""${Description}"""
            Write-Information $msg
            $group | Set-LocalGroup -Description $Description
        }
    }

    if ($Member)
    {
        Install-CLocalGroupMember -Name $Name -Member $Member
    }
}



function Install-CLocalGroupMember
{
    <#
    .SYNOPSIS
    Adds users or groups to a local group, if they aren't already in the group.

    .DESCRIPTION
    The `Install-CLocalGroupMember` adds an account to a local group. If the account is already in the group, nothing
    happens. Pass the name of the group to the `Name` parameter. Pass one or more account names to the `Member`
    parameter.

    If the local group doesn't exist, the function writes an error and does no work. If any of the accounts being added
    to the group don't exist, an error is written for each. Accounts that exist are still added to the group.

    Windows does not support local nested groups. If the account to add to the group is a local group, the function will
    write an error and not add the account to the group.

    This function uses the Microsoft.PowerShell.LocalAccounts cmdlets, so is not supported on 32-bit PowerShell running
    on a 64-bit operating system.

    .EXAMPLE
    Install-CLocalGroupMember -Name Administrators -Member EMPIRE\DarthVader,EMPIRE\EmperorPalpatine,REBELS\LSkywalker

    Adds Darth Vader, Emperor Palpatine and Luke Skywalker to the local administrators group.

    .EXAMPLE
    Install-CLocalGroupMember -Name TieFighters -Member NetworkService

    Adds the local NetworkService account to the local TieFighters group.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The group name.
        [Parameter(Mandatory)]
        [String] $Name,

        # The users/groups to add to a group.
        [Parameter(Mandatory)]
        [String[]] $Member
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-CLocalGroup -LiteralName $Name))
    {
        $msg = "Failed to add member to local group ""${Name}"" because local group ""${Name}"" does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $groupInfo = Resolve-CPrincipal -Name $Name
    $localGroupName = $groupInfo.Name
    $groupName = $groupInfo.FullName

    $prefix = "Adding member to local group ""${localGroupName}""  "

    foreach( $_member in $Member )
    {
        $principal = Resolve-CPrincipal -Name $_member
        if (-not $principal)
        {
            continue
        }

        $memberName = $principal.FullName

        if (Test-CLocalGroup -LiteralName $principal.Name)
        {
            $msg = "Failed to add local group ""${memberName}"" to local group ""${groupName}"" because " +
                   """${memberName}"" is a local group and Windows does not support nested local groups."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            continue
        }

        if ((Test-CLocalGroupMember -Name $groupName -Member $_member))
        {
            continue
        }

        if (-not $PSCmdlet.ShouldProcess("local group ${groupName}", "add member ${memberName}"))
        {
            continue
        }

        Write-Information "${prefix}+ ${memberName}"
        $prefix = ' ' * $prefix.Length
        Add-LocalGroupMember -Name $Name -Member $principal.FullName
    }
}



function Resolve-CPrincipal
{
    <#
    .SYNOPSIS
    Gets domain, name, type, and SID information about a user or group.

    .DESCRIPTION
    The `Resolve-CPrincipal` function takes a principal name or security identifier (SID) and gets its canonical
    representation. It returns a `Carbon_Accounts_Principal` object, which contains the following information about the
    principal:

     * Domain - the domain the user was found in
     * FullName - the users full name, e.g. Domain\Name
     * Name - the user's username or the group's name
     * Type - the Sid type.
     * Sid - the account's security identifier as a `System.Security.Principal.SecurityIdentifier` object.

    The common name for an account is not always the canonical name used by the operating system.  For example, the
    local Administrators group is actually called BUILTIN\Administrators.  This function uses the `LookupAccountName`
    and `LookupAccountSid` Windows functions to resolve an account name or security identifier into its domain, name,
    full name, SID, and SID type.

    You may pass a `System.Security.Principal.SecurityIdentifer`, a SID in SDDL form (as a string), or a SID in binary
    form (a byte array) as the value to the `SID` parameter. You'll get an error and nothing returned if the SDDL or
    byte array SID are invalid.

    If the name or security identifier doesn't represent an actual user or group, an error is written and nothing is
    returned.

    .LINK
    Test-CPrincipal

    .LINK
    Resolve-CPrincipalName

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa379601.aspx

    .LINK
    ConvertTo-CSecurityIdentifier

    .LINK
    Resolve-CPrincipalName

    .LINK
    Test-CPrincipal

    .OUTPUTS
    Carbon_Accounts_Principal.

    .EXAMPLE
    Resolve-CPrincipal -Name 'Administrators'

    Returns an object representing the `Administrators` group.

    .EXAMPLE
    Resolve-CPrincipal -SID 'S-1-5-21-2678556459-1010642102-471947008-1017'

    Demonstrates how to use a SID in SDDL form to convert a SID into an principal.

    .EXAMPLE
    Resolve-CPrincipal -SID ([Security.Principal.SecurityIdentifier]::New()'S-1-5-21-2678556459-1010642102-471947008-1017')

    Demonstrates that you can pass a `SecurityIdentifier` object as the value of the SID parameter.

    .EXAMPLE
    Resolve-CPrincipal -SID $sidBytes

    Demonstrates that you can use a byte array that represents a SID as the value of the `SID` parameter.
    #>
    [CmdletBinding()]
    param(
        # The name of the principal to return.
        [Parameter(Mandatory, ParameterSetName='ByName', Position=0)]
        [string] $Name,

        # The SID of the principal to return. Accepts a SID in SDDL form as a `string`, a
        # `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.
        [Parameter(Mandatory , ParameterSetName='BySid')]
        [Object] $SID
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PSCmdlet.ParameterSetName -eq 'BySid')
    {
        $SID = ConvertTo-CSecurityIdentifier -SID $SID
        if (-not $SID)
        {
            return
        }

        $sidBytes = [byte[]]::New($SID.BinaryLength)
        $SID.GetBinaryForm($sidBytes, 0)
        $account = Invoke-AdvapiLookupAccountSid -Sid $sidBytes
        if (-not $account)
        {
            Write-Error -Message "SID ""${SID}"" not found." -ErrorAction $ErrorActionPreference
            return
        }
        return [Carbon_Accounts_Principal]::New($account.DomainName, $account.Name, $SID, $account.Use)
    }

    if ($Name.StartsWith('.\'))
    {
        $username = $Name.Substring(2)
        $Name = "$([Environment]::MachineName)\${username}"
        $principal = Resolve-CPrincipal -Name $Name
        if (-not $principal)
        {
            $Name = "BUILTIN\${username}"
            $principal = Resolve-CPrincipal -Name $Name
        }
        return $principal
    }

    if ($Name.Equals("LocalSystem", [StringComparison]::InvariantCultureIgnoreCase))
    {
        $Name = "NT AUTHORITY\SYSTEM"
    }

    $account = Invoke-AdvapiLookupAccountName -AccountName $Name
    if (-not $account)
    {
        Write-Error -Message "Principal ""${Name}"" not found." -ErrorAction $ErrorActionPreference
        return
    }

    $sid = [SecurityIdentifier]::New($account.Sid, 0)
    $ntAccount = $sid.Translate([NTAccount])
    $domainName,$accountName = $ntAccount.Value.Split('\', 2)
    if (-not $accountName)
    {
        $accountName = $domainName
        $domainName = ''
    }
    return [Carbon_Accounts_Principal]::New($domainName, $accountName, $sid, $account.Use)

}


function Resolve-CPrincipalName
{
    <#
    .SYNOPSIS
    Determines the full, NT principal name for a user or group.

    .DESCRIPTION
    `Resolve-CPrincipalName` resolves a user/group name into its full, canonical name, used by the operating system. For
    example, the local Administrators group is actually called BUILTIN\Administrators. With a canonical username, you
    can unambiguously compare identities on objects that contain user/group information.

    If unable to resolve a name into an principal, `Resolve-CPrincipalName` returns nothing.

    If you want to get full principal information (domain, type, sid, etc.), use `Resolve-CPrincipal`.

    You can also resolve a SID into its principal name. The `SID` parameter accepts a SID in SDDL form as a `[String]`, a
    `[System.Security.Principal.SecurityIdentifier]` object, or a SID in binary form as an array of bytes. If the SID no
    longer maps to an active account, you'll get the original SID in SDDL form (as a string) returned to you.

    .LINK
    ConvertTo-CSecurityIdentifier

    .LINK
    Resolve-CPrincipal

    .LINK
    Test-CPrincipal

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa379601.aspx

    .OUTPUTS
    string

    .EXAMPLE
    Resolve-CPrincipalName -Name 'Administrators'

    Returns `BUILTIN\Administrators`, the canonical name for the local Administrators group.
    #>
    [CmdletBinding(DefaultParameterSetName='ByName')]
    [OutputType([String])]
    param(
        # The name of the principal to return.
        [Parameter(Mandatory, ParameterSetName='ByName', Position=0)]
        [String] $Name,

        # Get an principal's name from its SID. Accepts a SID in SDDL form as a `string`, a
        # `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.
        [Parameter(Mandatory, ParameterSetName='BySid')]
        [Object] $SID
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        return Resolve-CPrincipal -Name $Name -ErrorAction Ignore | Select-Object -ExpandProperty 'FullName'
    }

    $id = Resolve-CPrincipal -Sid $SID -ErrorAction Ignore
    if ($id)
    {
        return $id.FullName
    }

    return $SID.ToString()
}




function Test-CLocalGroup
{
    <#
    .SYNOPSIS
    Checks if a local group exists.

    .DESCRIPTION
    The `Test-CLocalGroup` function tests if a local group exists. Pass the group name to the `Name` parameter. Returns
    `$true` if the group exists, `$false` otherwise.

    Wildcards are supported by the `Name` parameter. If you want to make sure a single group exists using an exact name,
    use the `LiteralName` parameter.

    This function uses the `Microsoft.PowerShell.LocalAccounts` PowerShell module, so is not supported on 32-bit
    PowerShell running on a 64-bit operating system.

    .OUTPUTS
    System.Boolean

    .LINK
    Get-CLocalGroup

    .LINK
    Install-CLocalGroup

    .LINK
    Uninstall-CLocalGroup

    .EXAMPLE
    Test-CLocalGroup -Name 'RebelAlliance'

    Checks if the `RebelAlliance` local group exists.  Returns `$true` if it does, `$false` if it doesn't.

    .EXAMPLE
    Test-CLocalGroup -LiteralName $groupName

    Demonstrates how to check that a single group exists by using the `LiteralName` parameter.
    #>
    [CmdletBinding()]
    param(
        # The name of the local group to check. Wildcards supported.
        [Parameter(Mandatory, ParameterSetName='ByWildcardPattern')]
        [String] $Name,

        # The exact name of the local group to check. Wildcards **not** supported.
        [Parameter(Mandatory, ParameterSetName='ByLiteralName`')]
        [String] $LiteralName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $nameArg = @{}
    if ($Name)
    {
        $nameArg['Name'] = $Name
    }

    if ($LiteralName)
    {
        $nameArg['LiteralName'] = $LiteralName
    }

    $group = Get-CLocalGroup @nameArg -ErrorAction Ignore
    if ($group)
    {
        return $true
    }

    return $false
}




function Test-CLocalGroupMember
{
    <#
    .SYNOPSIS
    Tests if an account is a member of a local group.

    .DESCRIPTION
    The `Test-CLocalGroupMember` function tests if a user or group is a member of a local group. Pass the group name to
    the `Name` parameter. Pass the account name to the `Member` parameter. The function returns `$true` if the member is
    in the group, `$false` otherwise.

    If the group or member don't exist, the function writes an error and return nothing.

    This function uses the Microsoft.PowerShell.LocalAccounts cmdlets, so is not supported on 32-bit PowerShell running
    on a 64-bit operating system.

    .LINK
    Install-CLocalGroupMember

    .LINK
    Install-CLocalGroup

    .LINK
    Uninstall-CLocalGroupMember

    .LINK
    Test-CLocalGroup

    .LINK
    Uninstall-CLocalGroup

    .EXAMPLE
    Test-CLocalGroupMember -Name 'SithLords' -Member 'REBELS\LSkywalker'

    Demonstrates how to test if a user is a member of a group. In this case, it tests if `REBELS\LSkywalker` is in the
    local `SithLords`, *which obviously he isn't*, so `$false` is returned.
    #>
    [CmdletBinding()]
    param(
        # The name of the group whose membership is being tested.
        [Parameter(Mandatory)]
        [String] $Name,

        # The name of the member to check.
        [Parameter(Mandatory)]
        [String] $Member
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # PowerShell's local account cmdlets don't accept names with local machine name prefix.
    $groupInfo = Resolve-CPrincipal -Name $Name
    if (-not $groupInfo)
    {
        Write-Error -Message "Local group ""${Name}"" does not exist." -ErrorAction $ErrorActionPreference
        return
    }

    $group = Get-LocalGroup -Name $groupInfo.Name
    if (-not $group)
    {
        return
    }

    $principal = Resolve-CPrincipal -Name $Member
    if (-not $principal)
    {
        return
    }

    $existingMember =
        Get-CLocalGroupMember -Name $groupInfo.Name |
        Where-Object 'FullName' -EQ $principal.FullName
    if ($existingMember)
    {
        return $true
    }

    return $false
}



function Test-CPrincipal
{
    <#
    .SYNOPSIS
    Tests that a name is a valid Windows local or domain user/group.

    .DESCRIPTION
    Uses the Windows `LookupAccountName` function to find a principal.  If it can't be found, returns `$false`.
    Otherwise, it returns `$true`.

    Use the `PassThru` switch to return a `[Carbon_Accounts_Principal]` object (instead of `$true` if the principal
    exists).

    .LINK
    Resolve-CPrincipal

    .LINK
    Resolve-CPrincipalName

    .EXAMPLE
    Test-CPrincipal -Name 'Administrators

    Tests that a user or group called `Administrators` exists on the local computer.

    .EXAMPLE
    Test-CPrincipal -Name 'CARBON\Testers'

    Tests that a group called `Testers` exists in the `CARBON` domain.

    .EXAMPLE
    Test-CPrincipal -Name 'Tester' -PassThru

    Tests that a user or group named `Tester` exists and returns a `[Carbon_Accounts_Principal]` object if it does.
    #>
    [CmdletBinding()]
    param(
        # The name of the principal to test.
        [Parameter(Mandatory)]
        [string] $Name,

        # Returns a principal object if the principal exists.
        [switch] $PassThru
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $principal = Resolve-CPrincipal -Name $Name -ErrorAction Ignore
    if (-not $principal)
    {
        return $false
    }

    if ($PassThru)
    {
        return $principal
    }
    return $true
}




function Uninstall-CLocalGroup
{
    <#
    .SYNOPSIS
    Removes a local group, if it exists.

    .DESCRIPTION
    The `Uninstall-CLocalGroup` function removes a local group. Pass the group name to the `Name` parameter. If the
    group exists, it is removed. Otherwise, if the group doesn't exist, nothing happens.

    This function uses the Microsoft.PowerShell.LocalAccounts cmdlets, so is not supported on 32-bit PowerShell running
    on a 64-bit operating system.

    .LINK
    Install-CLocalGroupMember

    .LINK
    Install-CLocalGroup

    .LINK
    Uninstall-CLocalGroupMember

    .LINK
    Test-CLocalGroup

    .LINK
    Test-CLocalGroupMember

    .INPUTS
    System.String

    .EXAMPLE
    Uninstall-CLocalGroup -Name 'TestGroup1'

    Demonstrates how to uninstall a group. In this case, the `TestGroup1` group is removed.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        # The name of the group to remove/uninstall.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CLocalGroup -LiteralName $Name) )
    {
        return
    }

    Write-Information "Deleting local group ""${Name}""."
    Get-CLocalGroup -LiteralName $Name | Remove-LocalGroup
}



function Uninstall-CLocalGroupMember
{
    <#
    .SYNOPSIS
    Removes accounts from a local group, if they are part of the group.

    .DESCRIPTION
    The `Uninstall-CLocalGroupMember` function removes accounts from local groups. Pass the group name to the `Name`
    parameter. Pass the account names to the `Member` parameter. If the given accounts are in the local group, they are
    removed. Any account that is not in the group is ignored.

    The function writes an error if the group doesn't exist, or if any of the members you're trying to remove from the
    group don't exist.

    This function uses the Microsoft.PowerShell.LocalAccounts cmdlets, so is not supported on 32-bit PowerShell running
    on a 64-bit operating system.

    .EXAMPLE
    Uninstall-CLocalGroupMember -Name Administrators -Member EMPIRE\DarthVader,EMPIRE\EmperorPalpatine,REBELS\LSkywalker

    Demonstrates how to remove multiple accounts from a group by passing multiple account names to the `Member`
    parameter. In this example, Darth Vader, Emperor Palpatine and Luke Skywalker are removed from the local
    administrators group.

    .EXAMPLE
    Uninstall-CLocalGroupMember -Name TieFighters -Member NetworkService

    Demonstrates how to remove a single account from a group by passing the account name to the `Member` parameter. In
    this example, the local NetworkService account is removed from the local TieFighters group.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The group name.
        [Parameter(Mandatory)]
        [String] $Name,

        # The users/groups to remove from a group.
        [Parameter(Mandatory)]
        [String[]] $Member
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-CLocalGroup -LiteralName $Name))
    {
        $msg = "Failed to remove members from local group ""${Name}"" because that group does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $groupInfo = Resolve-CPrincipal -Name $Name

    $localGroupName = $groupInfo.Name
    $prefix = "Removing member from local group ""$($groupInfo.Name)""  "

    foreach ($_member in $Member)
    {
        if (-not (Test-CLocalGroupMember -Name $localGroupName -Member $_member))
        {
            continue
        }

        Write-Information "${prefix}- ${_member}"
        $prefix = ' ' * $prefix.Length
        Remove-LocalGroupMember -Name $localGroupName -Member $_member
    }
}



function Use-CallerPreference
{
    <#
    .SYNOPSIS
    Sets the PowerShell preference variables in a module's function based on the callers preferences.

    .DESCRIPTION
    Script module functions do not automatically inherit their caller's variables, including preferences set by common
    parameters. This means if you call a script with switches like `-Verbose` or `-WhatIf`, those that parameter don't
    get passed into any function that belongs to a module. 

    When used in a module function, `Use-CallerPreference` will grab the value of these common parameters used by the
    function's caller:

     * ErrorAction
     * Debug
     * Confirm
     * InformationAction
     * Verbose
     * WarningAction
     * WhatIf
    
    This function should be used in a module's function to grab the caller's preference variables so the caller doesn't
    have to explicitly pass common parameters to the module function.

    This function is adapted from the [`Get-CallerPreference` function written by David Wyatt](https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d).

    There is currently a [bug in PowerShell](https://connect.microsoft.com/PowerShell/Feedback/Details/763621) that
    causes an error when `ErrorAction` is implicitly set to `Ignore`. If you use this function, you'll need to add
    explicit `-ErrorAction $ErrorActionPreference` to every `Write-Error` call. Please vote up this issue so it can get
    fixed.

    .LINK
    about_Preference_Variables

    .LINK
    about_CommonParameters

    .LINK
    https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d

    .LINK
    http://powershell.org/wp/2014/01/13/getting-your-script-module-functions-to-inherit-preference-variables-from-the-caller/

    .EXAMPLE
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Demonstrates how to set the caller's common parameter preference variables in a module function.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        #[Management.Automation.PSScriptCmdlet]
        # The module function's `$PSCmdlet` object. Requires the function be decorated with the `[CmdletBinding()]`
        # attribute.
        $Cmdlet,

        [Parameter(Mandatory)]
        # The module function's `$ExecutionContext.SessionState` object.  Requires the function be decorated with the
        # `[CmdletBinding()]` attribute. 
        #
        # Used to set variables in its callers' scope, even if that caller is in a different script module.
        [Management.Automation.SessionState]$SessionState
    )

    Set-StrictMode -Version 'Latest'

    # List of preference variables taken from the about_Preference_Variables and their common parameter name (taken
    # from about_CommonParameters).
    $commonPreferences = @{
                              'ErrorActionPreference' = 'ErrorAction';
                              'DebugPreference' = 'Debug';
                              'ConfirmPreference' = 'Confirm';
                              'InformationPreference' = 'InformationAction';
                              'VerbosePreference' = 'Verbose';
                              'WarningPreference' = 'WarningAction';
                              'WhatIfPreference' = 'WhatIf';
                          }

    foreach( $prefName in $commonPreferences.Keys )
    {
        $parameterName = $commonPreferences[$prefName]

        # Don't do anything if the parameter was passed in.
        if( $Cmdlet.MyInvocation.BoundParameters.ContainsKey($parameterName) )
        {
            continue
        }

        $variable = $Cmdlet.SessionState.PSVariable.Get($prefName)
        # Don't do anything if caller didn't use a common parameter.
        if( -not $variable )
        {
            continue
        }

        if( $SessionState -eq $ExecutionContext.SessionState )
        {
            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
        }
        else
        {
            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
        }
    }
}