
using namespace System.Diagnostics.CodeAnalysis
using namespace System.IO
using namespace System.Security.AccessControl

# Copyright WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

# Functions should use $moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$script:moduleRoot = $PSScriptRoot

$psModulesDirPath = Join-Path -Path $script:moduleRoot -ChildPath 'Modules' -Resolve
Import-Module -Name (Join-Path -Path $psModulesDirPath -ChildPath 'Carbon.Core\Carbon.Core.psm1') `
              -Function @('Get-CPathProvider') `
              -Verbose:$false
Import-Module -Name (Join-Path -Path $psModulesDirPath -ChildPath 'Carbon.Accounts\Carbon.Accounts.psm1') `
              -Function @('Resolve-CPrincipal', 'Resolve-CPrincipalName', 'Test-CPrincipal') `
              -Verbose:$false
Import-Module -Name (Join-Path -Path $psModulesDirPath -ChildPath 'PureInvoke\PureInvoke.psm1' -Resolve) `
              -Function @(
                    'Invoke-AdvApiLookupPrivilegeName'
                    'Invoke-AdvApiLookupPrivilegeValue',
                    'Invoke-AdvApiLsaAddAccountRights',
                    'Invoke-AdvApiLsaClose',
                    'Invoke-AdvApiLsaEnumerateAccountRights',
                    'Invoke-AdvApiLsaOpenPolicy',
                    'Invoke-AdvApiLsaRemoveAccountRights'
              ) `
              -Verbose:$false

if (-not (Test-Path -Path 'variable:IsWindows'))
{
    [SuppressMessage('PSAvoidAssignmentToAutomaticVariable', '')]
    $IsWindows = $true
    [SuppressMessage('PSAvoidAssignmentToAutomaticVariable', '')]
    $IsMacOS = $false
    [SuppressMessage('PSAvoidAssignmentToAutomaticVariable', '')]
    $IsLinux = $false
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



function Get-CAcl
{
    <#
    .SYNOPSIS
    Gets the access control (i.e. security descriptor) for a file, directory, or registry key.

    .DESCRIPTION
    The `Get-CAcl` function gets the access control (i.e. security descriptor) for a file, directory, or registry key.
    Pipe the item whose security descriptor to get to the function. By default all parts of the security descriptor
    information is returned. To return only specific sections of the security descriptor, pass the sections to get to
    the `IncludeSection` parameter.

    .EXAMPLE
    Get-Item . | Get-CAcl

    Demonstrates how to get the security descriptor for an item by piping it into `Get-CAcl`.

    .EXAMPLE
    Get-Item . | Get-CAcl -IncludeSection ([Security.AccesControl.AccessControlSections]::Access -bor [Security.AccesControl.AccessControlSections]::Owner)

    Demonstrates how to only get specific sections of the security descriptor by passing the sections to get to the
    `IncludeSection` parmeter. Also demonstrates how to get multiple sections by using the `-bor` operator to combine
    two `[System.Security.AccesControl.AccessControlSections]` values together.
    #>
    [CmdletBinding()]
    [OutputType([Security.AccessControl.NativeObjectSecurity])]
    param(
        # The registry key, file info, or directory info object whose security descriptor to get.
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object] $InputObject,

        # The sections/parts of the security descriptor to get. By default, all sections are returned.
        [AccessControlSections] $IncludeSection
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        if (-not $PSBoundParameters.ContainsKey('IncludeSection'))
        {
            $IncludeSection = [AccessControlSections]::All
        }
    }

    process
    {
        if ($InputObject | Get-Member -Name 'GetAccessControl' -MemberType Method)
        {
            return $InputObject.GetAccessControl($IncludeSection)
        }

        if ($InputObject -isnot [FileSystemInfo])
        {
            $msg = "Failed to get ACL for ""${InputObject}"" because it doesn't have a ""GetAccessControl"" member " +
                   "and is a [$($InputObject.GetType().FullName)] object and not a FileInfo or DirectoryInfo object."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        return [FileSystemAclExtensions]::GetAccessControl($InputObject, $IncludeSection)
    }
}


function Get-CPermission
{
    <#
    .SYNOPSIS
    Gets the permissions (access control rules) for a file, directory, or registry key.

    .DESCRIPTION
    The `Get-CPermission` function gets the permissions, as access control rule objects, for a file, directory, or
    registry key. Using this function and module are not recommended. Instead,

    * for file directory permissions, use `Get-CNtfsPermission` in the `Carbon.FileSystem` module.
    * for registry permissions, use `Get-CRegistryPermission` in the `Carbon.Registry` module.
    * for private key and/or key container permissions, use `Get-CPrivateKeyPermission` in the `Carbon.Cryptography`
      module.

    Pass the path to the `Path` parameter. By default, all non-inherited permissions on that item are returned. To
    return inherited permissions, use the `Inherited` switch.

    To return the permissions for a specific user or group, pass the account's name to the `Identity` parameter.

    .OUTPUTS
    System.Security.AccessControl.AccessRule.

    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Revoke-CPermission

    .LINK
    Test-CPermission

    .EXAMPLE
    Get-CPermission -Path 'C:\Windows'

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the non-inherited rules on
    `C:\windows`.

    .EXAMPLE
    Get-CPermission -Path 'hklm:\Software' -Inherited

    Returns `System.Security.AccessControl.RegistryAccessRule` objects for all the inherited and non-inherited rules on
    `hklm:\software`.

    .EXAMPLE
    Get-CPermission -Path 'C:\Windows' -Idenity Administrators

    Returns `System.Security.AccessControl.FileSystemAccessRule` objects for all the `Administrators'` rules on
    `C:\windows`.
    #>
    [CmdletBinding()]
    [OutputType([System.Security.AccessControl.AccessRule])]
    param(
        # The path whose permissions (i.e. access control rules) to return. File system or registry paths supported.
        # Wildcards supported.
        [Parameter(Mandatory)]
        [String] $Path,

        # The user/group name whose permissiosn (i.e. access control rules) to return.
        [String] $Identity,

        # Return inherited permissions in addition to explicit permissions.
        [switch] $Inherited
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $rArgs = Resolve-Arg -Path $Path -Identity $Identity -Action 'get'
    if (-not $rArgs)
    {
        return
    }

    Get-Item -Path $Path -Force |
        Get-CAcl -IncludeSection ([AccessControlSections]::Access) |
        Select-Object -ExpandProperty 'Access' |
        Where-Object {
            if ($Inherited)
            {
                return $true
            }
            return (-not $_.IsInherited)
        } |
        Where-Object {
            if ($Identity)
            {
                return ($_.IdentityReference.Value -eq $rArgs.AccountName)
            }

            return $true
        }
}



function Get-CPrivilege
{
    <#
    .SYNOPSIS
    Gets an account's rights and privileges.

    .DESCRIPTION
    The `Get-CPrivilege` function gets an account's rights and privileges. These privileges are usually managed by Group
    Policy and control the system operations and types of logons an account can perform. Only privileges directly
    granted to the account are returned. If an account is granted a privilege through a group, those privileges are
    *not* returned.

    [Windows privileges can be in one of three states:](https://superuser.com/a/1254265/45274)

    * not granted
    * granted and enabled
    * granted and disabled

    The `Get-CPrivilege` function returns granted privileges, regardless if they are enabled or disabled.

    .OUTPUTS
    System.String

    .LINK
    Grant-CPrivilege

    .LINK
    Revoke-CPrivilege

    .LINK
    Test-CPrivilege

    .LINK
    Test-CPrivilegeName

    .EXAMPLE
    Get-CPrivilege -Identity TheBeast

    Gets `TheBeast` account's privileges as an array of strings.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        # The user/group name whose privileges to return.
        [Parameter(Mandatory)]
        [String] $Identity
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = Resolve-CPrincipal -Name $Identity
    if (-not $account)
    {
        return
    }

    $pHandle = Invoke-AdvApiLsaOpenPolicy -DesiredAccess LookupNames
    if (-not $pHandle)
    {
        return
    }

    try
    {
        Invoke-AdvApiLsaEnumerateAccountRights -PolicyHandle $pHandle -Sid $account.Sid | Write-Output
    }
    finally
    {
        Invoke-AdvApiLsaClose -PolicyHandle $pHandle | Out-Null
    }
}


 function Grant-CPermission
{
    <#
    .SYNOPSIS
    Grants permissions on a file, directory, or registry key.

    .DESCRIPTION
    The `Grant-CPermission` function grants permissions to files, directories, or registry keys. Using this function and
    module are not recommended. Instead,

    * for file/directory permissions, use `Grant-CNtfsPermission` in the `Carbon.FileSystem` module.
    * for registry permissions, use `Grant-CRegistryPermission` in the `Carbon.Registry` module.
    * for private key and/or key container permissions, use `Grant-CPrivateKeyPermission` in the `Carbon.Cryptography`
      module.

    Pass the item's path to the `Path` parameter, the name of the user/group receiving the permission to the `Identity`
    parameter, and the permission to grant to the `Permission` parameter. If the identity doesn't have the permission,
    the item's ACL is updated to include the new permission. If the identity has permission, but it doesn't match the
    permission being set, the identity's current permissions are changed to match. If the identity already has the given
    permission, nothing happens. Inherited permissions are ignored. To always grant permissions, use the `Force`
    (switch).

    The `Permissions` attribute should be a list of
    [FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx) or
    [RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx), for
    files/directories or registry keys, respectively. These commands will show you the values for the appropriate
    permissions for your object:

        [Enum]::GetValues([Security.AccessControl.FileSystemRights])
        [Enum]::GetValues([Security.AccessControl.RegistryRights])

    To get back the access rule, use the `PassThru` switch.

    By default, an `Allow` access rule is created and granted. To create a `Deny` access rule, pass `Deny` to the `Type`
    parameter.

    To append/add permissions instead of replacing existing permissions, use the `Append` switch.

    To control how the permission is applied and inherited, use the `ApplyTo` and `OnlyApplyToChildren` parameters.
    These behave like the "Applies to" and "Only apply these permissions to objects and/or containers within this
    container" fields in the Windows Permission user interface. The following table shows how these parameters are
    converted to `[Security.AccesControl.InheritanceFlags]` and `[Security.AccessControl.PropagationFlags]` values:

    | ApplyTo                         | OnlyApplyToChildren | InheritanceFlags                | PropagationFlags
    | ------------------------------- | ------------------- | ------------------------------- | ----------------
    | ContainerOnly                   | false               | None                            | None
    | ContainerSubcontainersAndLeaves | false               | ContainerInherit, ObjectInherit | None
    | ContainerAndSubcontainers       | false               | ContainerInherit                | None
    | ContainerAndLeaves              | false               | ObjectInherit                   | None
    | SubcontainersAndLeavesOnly      | false               | ContainerInherit, ObjectInherit | InheritOnly
    | SubcontainersOnly               | false               | ContainerInherit                | InheritOnly
    | LeavesOnly                      | false               | ObjectInherit                   | InheritOnly
    | ContainerOnly                   | true                | None                            | None
    | ContainerSubcontainersAndLeaves | true                | ContainerInherit, ObjectInherit | NoPropagateInherit
    | ContainerAndSubcontainers       | true                | ContainerInherit                | NoPropagateInherit
    | ContainerAndLeaves              | true                | ObjectInherit                   | NoPropagateInherit
    | SubcontainersAndLeavesOnly      | true                | ContainerInherit, ObjectInherit | NoPropagateInherit, InheritOnly
    | SubcontainersOnly               | true                | ContainerInherit                | NoPropagateInherit, InheritOnly
    | LeavesOnly                      | true                | ObjectInherit                   | NoPropagateInherit, InheritOnly

    .OUTPUTS
    System.Security.AccessControl.AccessRule. When setting permissions on a file or directory, a
    `System.Security.AccessControl.FileSystemAccessRule` is returned. When setting permissions on a registry key, a
    `System.Security.AccessControl.RegistryAccessRule` returned.

    .LINK
    Get-CPermission

    .LINK
    Revoke-CPermission

    .LINK
    Test-CPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3

    .EXAMPLE
    Grant-CPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path C:\EngineRoom

    Grants the Enterprise's engineering group full control on the engine room.  Very important if you want to get
    anywhere.

    .EXAMPLE
    Grant-CPermission -Identity ENTERPRISE\Interns -Permission ReadKey,QueryValues,EnumerateSubKeys -Path rklm:\system\WarpDrive

    Grants the Enterprise's interns access to read about the warp drive.  They need to learn someday, but at least they
    can't change anything.

    .EXAMPLE
    Grant-CPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path C:\EngineRoom -Clear

    Grants the Enterprise's engineering group full control on the engine room.  Any non-inherited, existing access rules
    are removed from `C:\EngineRoom`.

    .EXAMPLE
    Grant-CPermission -Identity BORG\Locutus -Permission FullControl -Path 'C:\EngineRoom' -Type Deny

    Demonstrates how to grant deny permissions on an objecy with the `Type` parameter.

    .EXAMPLE
    Grant-CPermission -Path C:\Bridge -Identity ENTERPRISE\Wesley -Permission 'Read' -ApplyTo ContainerAndSubContainersAndLeaves -Append
    Grant-CPermission -Path C:\Bridge -Identity ENTERPRISE\Wesley -Permission 'Write' -ApplyTo ContainerAndLeaves
    -Append

    Demonstrates how to grant multiple access rules to a single identity with the `Append` switch. In this case,
    `ENTERPRISE\Wesley` will be able to read everything in `C:\Bridge` and write only in the `C:\Bridge` directory, not
    to any sub-directory.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='ApplyToContainersSubcontainersAndLeaves')]
    [OutputType([Security.AccessControl.AccessRule])]
    param(
        # The path on which the permissions should be granted.  Can be a file system or registry path. If the path is
        # relative, it uses the current location to determine the full path.
        [Parameter(Mandatory)]
        [String] $Path,

        # The user or group getting the permissions.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from
        # [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).
        # For registry items, use values from
        # [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        [Parameter(Mandatory)]
        [String[]] $Permission,

        # How the permissions should be applied recursively to subcontainers and leaves. Default is
        # `ContainerSubcontainersAndLeaves`.
        [Parameter(Mandatory, ParameterSetName='IncludeAppliesTo')]
        [ValidateSet('ContainerOnly', 'ContainerSubcontainersAndLeaves', 'ContainerAndSubcontainers',
            'ContainerAndLeaves', 'SubcontainersAndLeavesOnly', 'SubcontainersOnly', 'LeavesOnly')]
        [String] $ApplyTo,

        # Inherited permissions should only apply to the children of the container, i.e. only one level deep.
        [Parameter(ParameterSetName='IncludeAppliesTo')]
        [switch] $OnlyApplyToChildren,

        # The type of rule to apply, either `Allow` or `Deny`. The default is `Allow`, which will allow access to the
        # item. The other option is `Deny`, which will deny access to the item.
        [AccessControlType] $Type = [AccessControlType]::Allow,

        # Removes all non-inherited permissions on the item.
        [switch] $Clear,

        # Returns an object representing the permission created or set on the `Path`. The returned object will have a
        # `Path` propery added to it so it can be piped to any cmdlet that uses a path.
        [switch] $PassThru,

        # Grants permissions, even if they are already present.
        [switch] $Force,

        # When granting permissions on files, directories, or registry items, add the permissions as a new access rule
        # instead of replacing any existing access rules.
        [switch] $Append,

        # ***Internal.*** Do not use.
        [String] $Description
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $ApplyTo)
    {
        $ApplyTo = 'ContainerSubcontainersAndLeaves'
    }

    $rArgs = Resolve-Arg -Path $Path `
                         -Identity $Identity `
                         -Permission $Permission `
                         -ApplyTo $ApplyTo `
                         -OnlyApplyToChildren:$OnlyApplyToChildren `
                         -Action 'grant'
    if (-not $rArgs)
    {
        return
    }

    $providerName = $rArgs.ProviderName
    $rights = $rArgs.Rights
    $accountName = $rArgs.AccountName
    $inheritanceFlags = $rArgs.InheritanceFlags
    $propagationFlags = $rArgs.PropagationFlags

    foreach ($currentPath in $rArgs.Paths)
    {
        # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information. When
        # passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security
        # descriptor. See
        # http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
        $currentAcl = Get-Item -LiteralPath $currentPath -Force | Get-CAcl -IncludeSection ([AccessControlSections]::Access)

        $testPermsFlagsArgs = @{ }
        if (Test-Path -LiteralPath $currentPath -PathType Container)
        {
            $testPermsFlagsArgs['ApplyTo'] = $ApplyTo
            $testPermsFlagsArgs['OnlyApplyToChildren'] = $OnlyApplyToChildren
        }
        else
        {
            $inheritanceFlags = [InheritanceFlags]::None
            $propagationFlags = [PropagationFlags]::None
            if($PSBoundParameters.ContainsKey('ApplyTo') -or $PSBoundParameters.ContainsKey('OnlyApplyToChildren'))
            {
                $msg = "Failed to set ""applies to"" flags on path ""${currentPath}"" because it is a file. Please " +
                       'omit "ApplyTo" and "OnlyApplyToChildren" parameters when granting permissions on a file.'
                Write-Warning $msg
            }
        }

        if (-not $Description)
        {
            $Description = $currentPath
        }

        $rulesToRemove = $null
        if( $Clear )
        {
            $rulesToRemove =
                $currentAcl.Access |
                Where-Object { $_.IdentityReference.Value -ne $accountName } |
                # Don't remove Administrators access.
                Where-Object { $_.IdentityReference.Value -ne 'BUILTIN\Administrators' } |
                Where-Object { -not $_.IsInherited }

            if( $rulesToRemove )
            {
                foreach( $ruleToRemove in $rulesToRemove )
                {
                    $rmType = $ruleToRemove.AccessControlType.ToString().ToLowerInvariant()
                    $rmRights = $ruleToRemove."${providerName}Rights"
                    Write-Information "${Description}  ${Identity}  - ${rmType} ${rmRights}"
                    [void]$currentAcl.RemoveAccessRule( $ruleToRemove )
                }
            }
        }


        $accessRule =
            New-Object -TypeName "Security.AccessControl.${providerName}AccessRule" `
                       -ArgumentList $accountName,$rights,$inheritanceFlags,$propagationFlags,$Type |
            Add-Member -MemberType NoteProperty -Name 'Path' -Value $currentPath -PassThru

        $missingPermission = -not (Test-CPermission -Path $currentPath `
                                                    -Identity $accountName `
                                                    -Permission $Permission `
                                                    @testPermsFlagsArgs `
                                                    -Strict)

        $setAccessRule = ($Force -or $missingPermission)
        if( $setAccessRule )
        {
            if( $Append )
            {
                $currentAcl.AddAccessRule( $accessRule )
            }
            else
            {
                $currentAcl.SetAccessRule( $accessRule )
            }
        }

        if ($rulesToRemove -or $setAccessRule)
        {
            $currentPerm = Get-CPermission -Path $currentPath -Identity $accountName
            $curRights = 0
            $curType = ''
            $curIdentity = $accountName
            if ($currentPerm)
            {
                $curType = $currentPerm.AccessControlType.ToString().ToLowerInvariant()
                $curRights = $currentPerm."${providerName}Rights"
                $curIdentity = $currentPerm.IdentityReference
            }
            $newType = $accessRule.AccessControlType.ToString().ToLowerInvariant()
            $newRights = $accessRule."${providerName}Rights"
            $newIdentity = $accessRule.IdentityReference
            if ($Append)
            {
                Write-Information "${Description}  ${newIdentity}  + ${newType} ${newRights}"
            }
            else
            {
                if ($currentPerm)
                {
                    Write-Information "${Description}  ${curIdentity}  - ${curType} ${curRights}"
                }
                Write-Information "${Description}  ${newIdentity}  + ${newType} ${newRights}"
            }
            Set-Acl -Path $currentPath -AclObject $currentAcl
        }

        if( $PassThru )
        {
            $accessRule | Write-Output
        }
    }
}



function Grant-CPrivilege
{
    <#
    .SYNOPSIS
    Grants an account privileges to perform system operations.

    .DESCRIPTION
    The `Grant-CPrivilege` function grants a user/group rights and privileges. Pass the name of the user/group to the
    `Identity` parameter. Pass the list of account rights and/or privileges to grant to the `Privilege` parameter. The
    account is granted any rights/privileges it doesn't currently have.

    Rights and privilege names are documented on Microsoft's website, duplicated below. These lists may be out-of-date.

    [Privilege Constants](https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants):

     * SeAssignPrimaryTokenPrivilege
     * SeAuditPrivilege
     * SeBackupPrivilege
     * SeChangeNotifyPrivilege
     * SeCreateGlobalPrivilege
     * SeCreatePagefilePrivilege
     * SeCreatePermanentPrivilege
     * SeCreateSymbolicLinkPrivilege
     * SeCreateTokenPrivilege
     * SeDebugPrivilege
     * SeDelegateSessionUserImpersonatePrivilege
     * SeEnableDelegationPrivilege
     * SeImpersonatePrivilege
     * SeIncreaseBasePriorityPrivilege
     * SeIncreaseQuotaPrivilege
     * SeIncreaseWorkingSetPrivilege
     * SeLoadDriverPrivilege
     * SeLockMemoryPrivilege
     * SeMachineAccountPrivilege
     * SeManageVolumePrivilege
     * SeProfileSingleProcessPrivilege
     * SeRelabelPrivilege
     * SeRemoteInteractiveLogonRight
     * SeRemoteShutdownPrivilege
     * SeRestorePrivilege
     * SeSecurityPrivilege
     * SeShutdownPrivilege
     * SeSyncAgentPrivilege
     * SeSystemEnvironmentPrivilege
     * SeSystemProfilePrivilege
     * SeSystemtimePrivilege
     * SeTakeOwnershipPrivilege
     * SeTcbPrivilege
     * SeTimeZonePrivilege
     * SeTrustedCredManAccessPrivilege
     * SeUndockPrivilege
     * SeUnsolicitedInputPrivilege

    [Account Right Constants](https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants):

     * SeBatchLogonRight
     * SeDenyBatchLogonRight
     * SeDenyInteractiveLogonRight
     * SeDenyNetworkLogonRight
     * SeDenyRemoteInteractiveLogonRight
     * SeDenyServiceLogonRight
     * SeInteractiveLogonRight
     * SeNetworkLogonRight
     * SeServiceLogonRight

    .LINK
    Get-CPrivilege

    .LINK
    Revoke-CPrivilege

    .LINK
    Test-CPrivilege

    .LINK
    Test-CPrivilegeName

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants

    .EXAMPLE
    Grant-CPrivilege -Identity Batcomputer -Privilege SeServiceLogonRight

    Grants the Batcomputer account the ability to logon as a service.
    #>
    [CmdletBinding()]
    param(
        # The user/group name to grant rights/privileges.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The rights/privileges to grant.
        #
        # [Privilege names are documented on the "Privilege Constants"
        # page.](https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants)
        #
        # [Rights names are documented on the "Account Rights Constants"
        # page.](https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants)
        [Parameter(Mandatory)]
        [String[]] $Privilege
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = Resolve-CPrincipal -Name $Identity
    if( -not $account )
    {
        return
    }

    $privilegesToGrant = $Privilege | Where-Object { -not (Test-CPrivilege -Identity $account.FullName -Privilege $_) }
    if (-not $privilegesToGrant)
    {
        return
    }

    $unknownPrivileges = $privilegesToGrant | Where-Object { -not (Test-CPrivilegeName -Name $_) }
    if ($unknownPrivileges)
    {
        $privileges = 'privilege'
        $thatThose = 'that'
        $isAre = 'is'
        if (($unknownPrivileges | Measure-Object).Count -gt 1)
        {
            $privileges = 'privileges'
            $thatThose = 'those'
            $isAre = 'are'
        }
        $msg = "Failed to grant the $($account.FullName) account $($unknownPrivileges -join ', ') ${privileges} " +
               "because ${thatThose} ${privileges} ${isAre} unknown."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
    }

    # Privilege names are case-sensitive when granting, so get the actual value of the privilege names.
    $privilegesToGrant = $privilegesToGrant | Test-CPrivilegeName -PassThru | Where-Object { $_ }
    if (-not $privilegesToGrant)
    {
        return
    }

    $pHandle = Invoke-AdvApiLsaOpenPolicy -DesiredAccess CreateAccount,LookupNames
    if (-not $pHandle)
    {
        return
    }

    try
    {
        Write-Information "$($account.FullName)  + $($privilegesToGrant -join ',')"
        Invoke-AdvApiLsaAddAccountRights -PolicyHandle $pHandle -Sid $account.Sid -Privilege $privilegesToGrant |
            Out-Null
    }
    finally
    {
        Invoke-AdvApiLsaClose -PolicyHandle $pHandle | Out-Null
    }
}



function Resolve-Arg
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $Path,

        [String] $Identity,

        [String[]] $Permission,

        [String] $ApplyTo,

        [switch] $OnlyApplyToChildren,

        [Parameter(Mandatory)]
        [ValidateSet('get', 'grant', 'revoke', 'test')]
        [String] $Action
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $result = [pscustomobject]@{
        Paths = @();
        AccountName = '';
        Rights = 0x0;
        ProviderName = '';
        InheritanceFlags = [InheritanceFlags]::None;
        PropagationFlags = [PropagationFlags]::None;
    }

    $permsMsg = ' permissions'
    if ($Permission)
    {
        $permsMsg = " $($Permission -join ',') permissions"
    }

    $accountMsg = ''
    if ($Identity)
    {
        if (-not (Test-CPrincipal -Name $Identity))
        {
            $msg = "Failed to ${Action}${permsMsg} on path ""${Path}"" to account ""${Identity}"" because that " +
                   'account does not exist.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $accountName = $result.AccountName = Resolve-CPrincipalName -Name $Identity
        $accountMsg = " account ""${accountName}"""

        if ($Permission)
        {
            $accountMsg = " ""${accountName}"" account's"
        }
    }

    if (-not (Test-Path -Path $Path))
    {
        $msg = "Failed to ${Action}${accountMsg}${permsMsg} on path ""${Path}"" because that path does not exist."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return $false
    }

    $result.Paths = $Path | Resolve-Path

    $providerName = Get-CPathProvider -Path $Path | Select-Object -ExpandProperty 'Name'
    if (-not $providerName)
    {
        $msg = "Failed to ${Action}${accountMsg}${permsMsg} on path ""${Path}"" because that path has an unknown " +
               'provider.'
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    if ($providerName -ne 'Registry' -and $providerName -ne 'FileSystem')
    {
        $msg = "Failed to ${Action}${accountMsg}${permsMsg} on path ""${Path}"" because that path uses the " +
               "unsupported ""${providerName}"" provider but only file system and registry paths are supported."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }
    $result.ProviderName = $providerName

    if ($Permission)
    {
        $rightTypeName = "Security.AccessControl.${providerName}Rights"

        $rights = 0 -as $rightTypeName

        foreach ($value in $Permission)
        {
            $right = $value -as $rightTypeName
            if (-not $right)
            {
                $allowedValues = [Enum]::GetNames($rightTypeName) -join ', '
                $msg = "Failed to ${Action}${accountMsg} ""${value}"" permission because that permission is invalid " +
                       "or unknown. It must be a [${rightTypeName}] enumeration value: ${allowedValues}."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            Write-Debug "    ${value} → ${right}/0x$($right.ToString('x'))"
            $rights = $rights -bor $right
        }

        $result.Rights = $rights
    }

    if ($ApplyTo)
    {
        # ApplyTo                          OnlyApplyToChildren  InheritanceFlags                 PropagationFlags
        # -------                          -------------------  ----------------                 ----------------
        # ContainerOnly                    true                 None                             None
        # ContainerSubcontainersAndLeaves  true                 ContainerInherit, ObjectInherit  NoPropagateInherit
        # ContainerAndSubcontainers        true                 ContainerInherit                 NoPropagateInherit
        # ContainerAndLeaves               true                 ObjectInherit                    NoPropagateInherit
        # SubcontainersAndLeavesOnly       true                 ContainerInherit, ObjectInherit  NoPropagateInherit, InheritOnly
        # SubcontainersOnly                true                 ContainerInherit                 NoPropagateInherit, InheritOnly
        # LeavesOnly                       true                 ObjectInherit                    NoPropagateInherit, InheritOnly
        # ContainerOnly                    false                None                             None
        # ContainerSubcontainersAndLeaves  false                ContainerInherit, ObjectInherit  None
        # ContainerAndSubcontainers        false                ContainerInherit                 None
        # ContainerAndLeaves               false                ObjectInherit                    None
        # SubcontainersAndLeavesOnly       false                ContainerInherit, ObjectInherit  InheritOnly
        # SubcontainersOnly                false                ContainerInherit                 InheritOnly
        # LeavesOnly                       false                ObjectInherit                    InheritOnly

        $inheritanceFlags = [InheritanceFlags]::None
        $propagationFlags = [PropagationFlags]::None

        switch ($ApplyTo)
        {
            'ContainerOnly'
            {
                $inheritanceFlags = [InheritanceFlags]::None
                $propagationFlags = [PropagationFlags]::None
            }
            'ContainerSubcontainersAndLeaves'
            {
                $inheritanceFlags = [InheritanceFlags]::ContainerInherit -bor [InheritanceFlags]::ObjectInherit
                $propagationFlags = [PropagationFlags]::None
            }
            'ContainerAndSubcontainers'
            {
                $inheritanceFlags = [InheritanceFlags]::ContainerInherit
                $propagationFlags = [PropagationFlags]::None
            }
            'ContainerAndLeaves'
            {
                $inheritanceFlags = [InheritanceFlags]::ObjectInherit
                $propagationFlags = [PropagationFlags]::None
            }
            'SubcontainersAndLeavesOnly'
            {
                $inheritanceFlags = [InheritanceFlags]::ContainerInherit -bor [InheritanceFlags]::ObjectInherit
                $propagationFlags = [PropagationFlags]::InheritOnly
            }
            'SubcontainersOnly'
            {
                $inheritanceFlags = [InheritanceFlags]::ContainerInherit
                $propagationFlags = [PropagationFlags]::InheritOnly
            }
            'LeavesOnly'
            {
                $inheritanceFlags = [InheritanceFlags]::ObjectInherit
                $propagationFlags = [PropagationFlags]::InheritOnly
            }
            default
            {
                $msg = "Failed to ${Action}${accountMsg}${permsMsg} on path ""${Path}"" because the ""AppliesTo"" " +
                       "parameter ""${ApplyTo}"" is invalid or unknown. Supported values are ""ContainerOnly, " +
                       'ContainerSubcontainersAndLeaves, ContainerAndSubcontainers, ContainerAndLeaves, ' +
                       'SubcontainersAndLeavesOnly, SubcontainersOnly, LeavesOnly"".'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }
        }

        if ($OnlyApplyToChildren -and $ApplyTo -ne 'ContainerOnly')
        {
            $propagationFlags = $propagationFlags -bor [PropagationFlags]::NoPropagateInherit
        }

        $result.InheritanceFlags = $inheritanceFlags
        $result.PropagationFlags = $propagationFlags
    }

    return $result
}


function Revoke-CPermission
{
    <#
    .SYNOPSIS
    Revokes permissions on a file, directory, or registry keys.

    .DESCRIPTION
    The `Revoke-CPermission` function removes a user or group's *explicit, non-inherited* permissions on a file,
    directory, or registry key. Using this function and module are not recommended. Instead,

    * for file directory permissions, use `Revoke-CNtfsPermission` in the `Carbon.FileSystem` module.
    * for registry permissions, use `Revoke-CRegistryPermission` in the `Carbon.Registry` module.
    * for private key and/or key container permissions, use `Revoke-CPrivateKeyPermission` in the `Carbon.Cryptography`
      module.

    Pass the path to the item to the `Path` parameter. Pass the user/group's name to the `Identity` parameter. If the
    identity has any non-inherited permissions on the item, those permissions are removed. If the identity has no
    permissions on the item, nothing happens.

    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Test-CPermission

    .EXAMPLE
    Revoke-CPermission -Identity ENTERPRISE\Engineers -Path 'C:\EngineRoom'

    Demonstrates how to revoke all of the 'Engineers' permissions on the `C:\EngineRoom` directory.

    .EXAMPLE
    Revoke-CPermission -Identity ENTERPRISE\Interns -Path 'hklm:\system\WarpDrive'

    Demonstrates how to revoke permission on a registry key.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path on which the permissions should be revoked. Can be a file system or registry path.
        [Parameter(Mandatory)]
        [String] $Path,

        # The identity losing permissions.
        [Parameter(Mandatory)]
        [String] $Identity,

        # ***Internal.*** Do not use.
        [String] $Description
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $rArgs = Resolve-Arg -Path $Path -Identity $Identity -Action 'revoke'
    if (-not $rArgs)
    {
        return
    }

    $accountName = $rArgs.AccountName

    $rulesToRemove = Get-CPermission -Path $Path -Identity $accountName
    if (-not $rulesToRemove)
    {
        return
    }

    $providerName = $rArgs.ProviderName

    foreach ($currentPath in $rArgs.Paths)
    {
        if (-not $Description)
        {
            $Description = $currentPath
        }

        # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
        # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security
        # descriptor. See
        # http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
        $currentAcl =
            Get-Item -LiteralPath $currentPath -Force | Get-CAcl -IncludeSection ([AccessControlSections]::Access)

        foreach ($ruleToRemove in $rulesToRemove)
        {
            $rmIdentity = $ruleToRemove.IdentityReference
            $rmType = $ruleToRemove.AccessControlType.ToString().ToLowerInvariant()
            $rmRights = $ruleToRemove."${providerName}Rights"
            Write-Information "${Description}  ${rmIdentity}  - ${rmType} ${rmRights}"
            [void]$currentAcl.RemoveAccessRule($ruleToRemove)
        }

        if ($PSCmdlet.ShouldProcess($currentPath, "revoke ""${accountName}"" account's permissions"))
        {
            Set-Acl -Path $currentPath -AclObject $currentAcl
        }
    }
}




function Revoke-CPrivilege
{
    <#
    .SYNOPSIS
    Removes an account's rights and/or privileges.

    .DESCRIPTION
    The `Revoke-CPrivilege` function removes a user or group's rights and/or privileges. Pass the user/group name to the
    `Identity` parameter. Pass the right/privilege names to remove to the `Privilege` parameter. Any right/privilege the
    user/group has is removed. If the user doesn't have the right/privilege, nothing happens.

    To see the user/group's current rights/privileges, use the `Get-CPrivilege` function.

    Rights and privilege names are documented on Microsoft's website, duplicated below. These lists may be out-of-date.

    [Privilege Constants](https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants):

     * SeAssignPrimaryTokenPrivilege
     * SeAuditPrivilege
     * SeBackupPrivilege
     * SeChangeNotifyPrivilege
     * SeCreateGlobalPrivilege
     * SeCreatePagefilePrivilege
     * SeCreatePermanentPrivilege
     * SeCreateSymbolicLinkPrivilege
     * SeCreateTokenPrivilege
     * SeDebugPrivilege
     * SeDelegateSessionUserImpersonatePrivilege
     * SeEnableDelegationPrivilege
     * SeImpersonatePrivilege
     * SeIncreaseBasePriorityPrivilege
     * SeIncreaseQuotaPrivilege
     * SeIncreaseWorkingSetPrivilege
     * SeLoadDriverPrivilege
     * SeLockMemoryPrivilege
     * SeMachineAccountPrivilege
     * SeManageVolumePrivilege
     * SeProfileSingleProcessPrivilege
     * SeRelabelPrivilege
     * SeRemoteInteractiveLogonRight
     * SeRemoteShutdownPrivilege
     * SeRestorePrivilege
     * SeSecurityPrivilege
     * SeShutdownPrivilege
     * SeSyncAgentPrivilege
     * SeSystemEnvironmentPrivilege
     * SeSystemProfilePrivilege
     * SeSystemtimePrivilege
     * SeTakeOwnershipPrivilege
     * SeTcbPrivilege
     * SeTimeZonePrivilege
     * SeTrustedCredManAccessPrivilege
     * SeUndockPrivilege
     * SeUnsolicitedInputPrivilege

    [Account Right Constants](https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants):

     * SeBatchLogonRight
     * SeDenyBatchLogonRight
     * SeDenyInteractiveLogonRight
     * SeDenyNetworkLogonRight
     * SeDenyRemoteInteractiveLogonRight
     * SeDenyServiceLogonRight
     * SeInteractiveLogonRight
     * SeNetworkLogonRight
     * SeServiceLogonRight

    .LINK
    Get-CPrivilege

    .LINK
    Grant-CPrivilege

    .LINK
    Test-CPrivilege

    .LINK
    Test-CPrivilegeName

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants

    .EXAMPLE
    Revoke-CPrivilege -Identity Batcomputer -Privilege SeServiceLogonRight

    Revokes the Batcomputer account's ability to logon as a service.  Don't restart that thing!
    #>
    [CmdletBinding()]
    param(
        # The identity to grant a privilege.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The rights/privileges to grant.
        #
        # [Privilege names are documented on the "Privilege Constants"
        # page.](https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants)
        #
        # [Rights names are documented on the "Account Rights Constants"
        # page.](https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants)
        [Parameter(Mandatory)]
        [String[]] $Privilege
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = Resolve-CPrincipal -Name $Identity
    if( -not $account )
    {
        return
    }

    $unknownPrivileges = $Privilege | Where-Object { -not (Test-CPrivilegeName -Name $_) }
    if ($unknownPrivileges)
    {
        $privileges = 'privilege'
        $thatThose = 'that'
        $isAre = 'is'
        if (($unknownPrivileges | Measure-Object).Count -gt 1)
        {
            $privileges = 'privileges'
            $thatThose = 'those'
            $isAre = 'are'
        }
        $msg = "Failed to revoke the $($account.FullName) account's $($unknownPrivileges -join ', ') ${privileges} " +
               "because ${thatThose} ${privileges} ${isAre} unknown."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
    }

    $privilegesToRevoke = $Privilege | Where-Object { (Test-CPrivilege -Identity $account.FullName -Privilege $_) }
    if (-not $privilegesToRevoke)
    {
        return
    }

    # Privilege names are case-sensitive when granting, so get the actual value of the privilege names.
    $privilegesToRevoke = $privilegesToRevoke | Test-CPrivilegeName -PassThru | Where-Object { $_ }
    if (-not $privilegesToRevoke)
    {
        return
    }

    $pHandle = Invoke-AdvApiLsaOpenPolicy -DesiredAccess CreateAccount,LookupNames
    if (-not $pHandle)
    {
        return
    }

    try
    {
        Write-Information "$($account.FullName)  - $($privilegesToRevoke -join ',')"
        Invoke-AdvApiLsaRemoveAccountRights -PolicyHandle $pHandle -Sid $account.Sid -Privilege $privilegesToRevoke |
            Out-Null
    }
    finally
    {
        Invoke-AdvApiLsaClose -PolicyHandle $pHandle | Out-Null
    }
}




function Test-CPermission
{
    <#
    .SYNOPSIS
    Tests permissions on a file, directory, or registry key

    .DESCRIPTION
    The `Test-CPermission` function tests if permissions are granted to a user or group on a file, directory, or
    registry key. Using this function and module are not recommended. Instead,

    * for file directory permissions, use `Test-CNtfsPermission` in the `Carbon.FileSystem` module.
    * for registry permissions, use `Test-CRegistryPermission` in the `Carbon.Registry` module.
    * for private key and/or key container permissions, use `Test-CPrivateKeyPermission` in the `Carbon.Cryptography`
      module.

    Pass the path to the item to the `Path` parameter. Pass the user/group name to the `Identity` parameter. Pass the
    permissions to check for to the `Permission` parameter. If the user has all those permissions on that item, the
    function returns `true`. Otherwise it returns `false`.

    The `Permissions` attribute should be a list of
    [FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx) or
    [RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx). These
    commands will show you the values for the appropriate permissions for your object:

        [Enum]::GetValues([Security.AccessControl.FileSystemRights])
        [Enum]::GetValues([Security.AccessControl.RegistryRights])

    Extra/additional permissions on the item are ignored. To check that the user/group has the exact permissions passed
    to the `Permission` parameter, use the `Strict` switch.

    You can also test how the item's permissions are applied and inherited, use the `ApplyTo` and `OnlyApplyToChildren`
    parameters. These match the "Applies to" and "Only apply these permissions to objects and/or containers within this
    container" fields in the Windows Permission user interface. The following table shows how these parameters are
    converted to `[Security.AccesControl.InheritanceFlags]` and `[Security.AccessControl.PropagationFlags]` values:

    | ApplyTo                         | OnlyApplyToChildren | InheritanceFlags                | PropagationFlags
    | ------------------------------- | ------------------- | ------------------------------- | ----------------
    | ContainerOnly                   | false               | None                            | None
    | ContainerSubcontainersAndLeaves | false               | ContainerInherit, ObjectInherit | None
    | ContainerAndSubcontainers       | false               | ContainerInherit                | None
    | ContainerAndLeaves              | false               | ObjectInherit                   | None
    | SubcontainersAndLeavesOnly      | false               | ContainerInherit, ObjectInherit | InheritOnly
    | SubcontainersOnly               | false               | ContainerInherit                | InheritOnly
    | LeavesOnly                      | false               | ObjectInherit                   | InheritOnly
    | ContainerOnly                   | true                | None                            | None
    | ContainerSubcontainersAndLeaves | true                | ContainerInherit, ObjectInherit | NoPropagateInherit
    | ContainerAndSubcontainers       | true                | ContainerInherit                | NoPropagateInherit
    | ContainerAndLeaves              | true                | ObjectInherit                   | NoPropagateInherit
    | SubcontainersAndLeavesOnly      | true                | ContainerInherit, ObjectInherit | NoPropagateInherit, InheritOnly
    | SubcontainersOnly               | true                | ContainerInherit                | NoPropagateInherit, InheritOnly
    | LeavesOnly                      | true                | ObjectInherit                   | NoPropagateInherit, InheritOnly

    By default, inherited permissions are ignored. To check inherited permission, use the `-Inherited` switch.

    .OUTPUTS
    System.Boolean.

    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Revoke-CPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx

    .EXAMPLE
    Test-CPermission -Identity 'STARFLEET\JLPicard' -Permission 'FullControl' -Path 'C:\Enterprise\Bridge'

    Demonstrates how to check that Jean-Luc Picard has `FullControl` permission on the `C:\Enterprise\Bridge`.

    .EXAMPLE
    Test-CPermission -Identity 'STARFLEET\GLaForge' -Permission 'WriteKey' -Path 'HKLM:\Software\Enterprise\Engineering'

    Demonstrates how to check that Geordi LaForge can write registry keys at `HKLM:\Software\Enterprise\Engineering`.

    .EXAMPLE
    Test-CPermission -Identity 'STARFLEET\Worf' -Permission 'Write' -ApplyTo 'Container' -Path 'C:\Enterprise\Brig'

    Demonstrates how to test for inheritance/propogation flags, in addition to permissions.
    #>
    [CmdletBinding(DefaultParameterSetName='ExcludeApplyTo')]
    param(
        # The path on which the permissions should be checked.  Can be a file system or registry path.
        [Parameter(Mandatory)]
        [String] $Path,

        # The user or group whose permissions to check.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The permission to test for: e.g. FullControl, Read, etc.  For file system items, use values from
        # [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).
        # For registry items, use values from
        # [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        [Parameter(Mandatory)]
        [String[]] $Permission,

        # How the permissions should be applied recursively to subcontainers and leaves. Default is
        # `ContainerSubcontainersAndLeaves`.
        [Parameter(Mandatory, ParameterSetName='IncludeApplyTo')]
        [ValidateSet('ContainerOnly', 'ContainerSubcontainersAndLeaves', 'ContainerAndSubcontainers',
            'ContainerAndLeaves', 'SubcontainersAndLeavesOnly', 'SubcontainersOnly', 'LeavesOnly')]
        [String] $ApplyTo,

        # Inherited permissions should only apply to the children of the container, i.e. only one level deep.
        [Parameter(ParameterSetName='IncludeApplyTo')]
        [switch] $OnlyApplyToChildren,

        # Include inherited permissions in the check.
        [switch] $Inherited,

        # Check for the exact permissions, inheritance flags, and propagation flags, i.e. make sure the identity has
        # *only* the permissions you specify.
        [switch] $Strict
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $rArgs = Resolve-Arg -Path $Path `
                         -Identity $Identity `
                         -Permission $Permission `
                         -ApplyTo $ApplyTo `
                         -OnlyApplyToChildren:$OnlyApplyToChildren `
                         -Action 'test'
    if (-not $rArgs)
    {
        return
    }

    $providerName = $rArgs.ProviderName
    $rights = $rArgs.Rights
    $inheritanceFlags = $rArgs.InheritanceFlags
    $propagationFlags = $rArgs.PropagationFlags

    if ($providerName -eq 'FileSystem' -and $Strict)
    {
        # Synchronize is always on and can't be turned off.
        $rights = $rights -bor [FileSystemRights]::Synchronize
    }

    foreach ($currentPath in $rArgs.Paths)
    {
        $isLeaf = (Test-Path -LiteralPath $currentPath -PathType Leaf)
        $testFlags = $PSCmdlet.ParameterSetName -eq 'IncludeApplyTo'

        if ($isLeaf -and $testFlags)
        {
            $msg = "Failed to test ""applies to"" flags on path ""${currentPath}"" because it is a file. Please omit " +
                   '"ApplyTo" and "OnlyApplyToChildren" parameters when testing permissions on a file.'
            Write-Warning $msg
        }

        $rightsPropertyName = "${providerName}Rights"
        $acl =
            Get-CPermission -Path $currentPath -Identity $Identity -Inherited:$Inherited |
            Where-Object 'AccessControlType' -eq 'Allow' |
            Where-Object 'IsInherited' -eq $Inherited |
            Where-Object {
                if ($Strict)
                {
                    return ($_.$rightsPropertyName -eq $rights)
                }

                return ($_.$rightsPropertyName -band $rights) -eq $rights
            } |
            Where-Object {
                if ($isLeaf -or -not $testFlags)
                {
                    return $true
                }

                return $_.InheritanceFlags -eq $inheritanceFlags -and $_.PropagationFlags -eq $propagationFlags
            }

        if ($acl)
        {
            $true | Write-Output
            continue
        }

        $false | Write-Output
    }
}




function Test-CPrivilege
{
    <#
    .SYNOPSIS
    Tests if an identity has a given privilege.

    .DESCRIPTION
    Returns `true` if an identity has a privilege.  `False` otherwise.

    .LINK
    Carbon_Privilege

    .LINK
    Get-CPrivilege

    .LINK
    Grant-CPrivilege

    .LINK
    Revoke-CPrivilege

    .LINK
    Test-CPrivilegeName

    .EXAMPLE
    Test-CPrivilege -Identity Forrester -Privilege SeServiceLogonRight

    Tests if `Forrester` has the `SeServiceLogonRight` privilege.
    #>
    [CmdletBinding()]
    param(
        # The identity whose privileges to check.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The privilege to check.
        [Parameter(Mandatory)]
        [String] $Privilege
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $matchingPrivilege = Get-CPrivilege -Identity $Identity | Where-Object { $_ -eq $Privilege }
    return ($null -ne $matchingPrivilege)
}




function Test-CPrivilegeName
{
    <#
    .SYNOPSIS
    Tests if a right/privilege name is valid.

    .DESCRIPTION
    The `Test-CPrivilegeName` tests if a right/privilege name is valid or not. Not all privileges are supported on all
    operating systems. Use this function to test which privileges are valid or not. Pass the name to test to the `Name`
    parameter. The function returns `$true` if the rights/privilege name is valid, `$false` otherwise.

    Privilege names are validated using Windows APIs. There is no Windows API for account rights, so they are validated
    against [a list of known rights](https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants).

    .EXAMPLE
    Test-CPrivilegeName -Name 'SeBatchLogonRight'

    Demonstrates how to use this function.
    #>
    [CmdletBinding()]
    param(
        # The right/privilege name to test.
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $Name,

        # Return the right/privilege's canonical name instead of `$true`.
        [switch] $PassThru
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $knownAccountRights = @(
            'SeBatchLogonRight',
            'SeDenyBatchLogonRight',
            'SeDenyInteractiveLogonRight',
            'SeDenyNetworkLogonRight',
            'SeDenyRemoteInteractiveLogonRight',
            'SeDenyServiceLogonRight',
            'SeInteractiveLogonRight',
            'SeNetworkLogonRight',
            'SeRemoteInteractiveLogonRight',
            'SeServiceLogonRight'
        )
    }

    process
    {
        $accountRight = $knownAccountRights | Where-Object { $_ -eq $Name }
        if ($accountRight)
        {
            if ($PassThru)
            {
                return $accountRight
            }
            return $true
        }

        $luid = Invoke-AdvApiLookupPrivilegeValue -Name $Name -ErrorAction Ignore
        if ($luid)
        {
            if ($PassThru)
            {
                return Invoke-AdvApiLookupPrivilegeName -LUID $luid
            }
            return $true
        }

        return $false
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