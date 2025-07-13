
using namespace System.Collections
using namespace System.Security.AccessControl

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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

# Functions should use $moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$moduleRoot = $PSScriptRoot

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Modules\Carbon.Security' -Resolve) `
              -Function @('Get-CPermission', 'Grant-CPermission', 'Revoke-CPermission', 'Test-CPermission') `
              -Verbose:$false

# Store each of your module's functions in its own file in the Functions
# directory. On the build server, your module's functions will be appended to
# this file, so only dot-source files that exist on the file system. This allows
# developers to work on a module without having to build it first. Grab all the
# functions that are in their own files.
$functionsPath = Join-Path -Path $moduleRoot -ChildPath 'Functions\*.ps1'
if( (Test-Path -Path $functionsPath) )
{
    foreach( $functionPath in (Get-Item $functionsPath) )
    {
        . $functionPath.FullName
    }
}



function ConvertTo-CarbonSecurityApplyTo
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [ValidateSet('KeyOnly', 'KeyAndSubkeys', 'SubkeysOnly')]
        [String] $ApplyTo
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $map = @{
            'KeyOnly' = 'ContainerOnly';
            'KeyAndSubkeys' = 'ContainerAndSubcontainers';
            'SubkeysOnly' = 'SubcontainersOnly';
        }
    }

    process
    {
        if (-not $ApplyTo)
        {
            return
        }

        return $map[$ApplyTo]
    }
}



function Get-CRegistryKeyValue
{
    <#
    .SYNOPSIS
    Gets the value from a registry key.

    .DESCRIPTION
    PowerShell's `Get-ItemProperty` cmdlet is a pain to use.  It doesn't actually return an object representing a
    registry key's value, but some other weird object that requires painful gyrations to get values from. This function
    returns just the value of a key.

    .EXAMPLE
    Get-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'

    Returns the value of the 'hklm:\Software\Carbon\Test' key's `Title` value.
    #>
    [CmdletBinding()]
    param(
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        [Parameter(Mandatory)]
        [String] $Path,

        # The name of the value being set.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-CRegistryKeyValue -Path $Path -Name $Name))
    {
        return $null
    }

    $itemProperties = Get-ItemProperty -Path $Path -Name *
    $value = $itemProperties.$Name
    Write-Debug -Message ('[{0}@{1}: {2} -is {3}' -f $Path,$Name,$value,$value.GetType())
    return $value
}




function Get-CRegistryPermission
{
    <#
    .SYNOPSIS
    Gets the permissions (access control rules) for a registry key.

    .DESCRIPTION
    The `Get-CRegistryPermission` function gets the permissions on a registry key. Pass the path to the registry key
    whose permissions to get to the `Path` parameter. By default, all non-inherited permissions are returned. To also
    get inherited permissions, use the `Inherited` switch.

    Permissions for a specific identity can also be returned. Pass the user/group name to the `Identity` parameter. If
    the identity doesn't exist or it doesn't have permissions on the registry key, not error is written and nothing is
    returned.
s
    .OUTPUTS
    System.Security.AccessControl.AccessRule.

    .LINK
    Get-CRegistryPermission

    .LINK
    Grant-CRegistryPermission

    .LINK
    Revoke-CRegistryPermission

    .LINK
    Test-CRegistryPermission

    .EXAMPLE
    Get-CRegistryPermission -Path 'hklm:\Software'

    Demonstrates how to get all non-inherited permissions on a registry key by passing the key's path to the `Path`
    parameter.

    .EXAMPLE
    Get-CRegistryPermission -Path 'hklm:\Software' -Inherited

    Demonstrates how to get inherited permissions by using the `Inherited` switch.

    .EXAMPLE
    Get-CRegistryPermission -Path 'hklm:\Software\Microsoft' -Idenity Administrators

    Demonstrates how to get the permissions for a specific user/group by passing its name to the `Identity` paramter.
    #>
    [CmdletBinding()]
    [OutputType([Security.AccessControl.RegistryAccessRule])]
    param(
        # The registry key path whose permissions (i.e. access control rules) to return. Wildcards supported.
        [Parameter(Mandatory)]
        [String] $Path,

        # The identity whose permissiosn (i.e. access control rules) to return. By default, all non-inherited permissions
        # are returned.
        [String] $Identity,

        # Return inherited permissions in addition to explicit permissions. By default, inherited permissions are not
        # returned.
        [switch] $Inherited
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-CPermission @PSBoundParameters
}




function Grant-CRegistryPermission
{
    <#
    .SYNOPSIS
    Grants permission on a registry key to a user or group.

    .DESCRIPTION
    The `Grant-CRegistryPermission` functions grants permissions to registry keys. Pass the path to the registry key to
    the `Path` parameter, the user/group name to the `Identity` parameter, and the permission to grant to the
    `Permission` parameter. If that user/group doesn't have any permissions on the registry key, the requested
    permissions are granted. If the user/group does have permissions on the registry key, and the permissions are
    different than the requested permissions, permissions are updated to be the requested permissions. If the user/group
    already has the requested permissions, no error is written and nothing happens.

    To control how the permission is applied to descendent registry keys, use the `ApplyTo` and
    `OnlyApplyToChildRegistryKeys` parameters. By default, permissions are applied to all keys and subkeys.

    Set the `Type` to `Deny` to create a deny permission.

    To clear all other permissions on the registry key, even permissions on other identities, use the `Clear` switch.

    To return the permission as an object, use the `PassThru` switch.

    To always apply the new permission, regardless if it is present or not, use the `Force` switch.

    To allow the user/group to have multiple permissions on the registry key, use the `Append` switch.

    .OUTPUTS
    System.Security.AccessControl.RegistryAccessRule

    .LINK
    Get-CRegistryPermission

    .LINK
    Revoke-CRegistryPermission

    .LINK
    Test-CRegistryPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx

    .LINK
    http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3

    .EXAMPLE
    Grant-CRegistryPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path 'hklm:\EngineRoom'

    Grants the Enterprise's engineering group full control on the engine room. Very important if you want to get
    anywhere.

    .EXAMPLE
    Grant-CRegistryPermission -Identity ENTERPRISE\Interns -Permission ReadKey,QueryValues,EnumerateSubKeys -Path hklm:\system\WarpDrive

    Grants the Enterprise's interns access to read about the warp drive. They need to learn someday, but at least they
    can't change anything.

    .EXAMPLE
    Grant-CRegistryPermission -Identity ENTERPRISE\Engineers -Permission FullControl -Path hklm:\EngineRoom -Clear

    Grants the Enterprise's engineering group full control on the engine room. Any non-inherited, existing access rules
    are removed from `C:\EngineRoom`.

    .EXAMPLE
    Grant-CRegistryPermission -Identity BORG\Locutus -Permission FullControl -Path 'hklm:\EngineRoom' -Type Deny

    Demonstrates how to grant deny permissions on an objecy with the `Type` parameter.

    .EXAMPLE
    Grant-CRegistryPermission -Path hklm:\Bridge -Identity ENTERPRISE\Wesley -Permission 'Read' -ApplyTo KeysAndSubkeys -Append
    Grant-CRegistryPermission -Path hklm:\Bridge -Identity ENTERPRISE\Wesley -Permission 'Write' -ApplyTo KeyOnly -Append

    Demonstrates how to grant multiple access rules to a single identity with the `Append` switch. In this case,
    `ENTERPRISE\Wesley` will be able to read everything in `hklm:\Bridge` and write only in the `hklm:\Bridge` directory, not
    to any sub-directory.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='DefaultAppliesToFlags')]
    [OutputType([Security.AccessControl.RegistryAccessRule])]
    param(
        # The registry key path on which the permissions should be granted.
        [Parameter(Mandatory)]
        [String] $Path,

        # The user or group getting the permissions.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The permission: e.g. FullControl, Read, etc. Use values from
        # [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        [Parameter(Mandatory)]
        [RegistryRights[]] $Permission,

        # How to apply permissions to descendants. This controls the inheritance and propagation flags. Default is full
        # inheritance, e.g. `KeyAndSubkeys`.
        [Parameter(Mandatory, ParameterSetName='SetsAppliesToFlags')]
        [ValidateSet('KeyOnly', 'KeyAndSubkeys', 'SubkeysOnly')]
        [String] $ApplyTo,

        # Only apply the permissions to child keys.
        [Parameter(ParameterSetName='SetsAppliesToFlags')]
        [switch] $OnlyApplyToChildKeys,

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

        # Add the permissions as a new access rule instead of replacing any existing access rules.
        [switch] $Append
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not $ApplyTo)
    {
        $ApplyTo = 'KeyAndSubkeys'
    }

    $PSBoundParameters['ApplyTo'] = $ApplyTo | ConvertTo-CarbonSecurityApplyTo

    $PSBoundParameters.Remove('OnlyApplyToChildKeys') | Out-Null
    if ($OnlyApplyToChildKeys)
    {
        $PSBoundParameters['OnlyApplyToChildren'] = $true
    }

    Grant-CPermission @PSBoundParameters

}



function Install-CRegistryKey
{
    <#
    .SYNOPSIS
    Creates a registry key.  If it already exists, does nothing.

    .DESCRIPTION
    Given the path to a registry key, creates the key and all its parents.  If the key already exists, nothing happens.

    .EXAMPLE
    Install-CRegistryKey -Path 'hklm:\Software\Carbon\Test'

    Creates the `hklm:\Software\Carbon\Temp` registry key if it doesn't already exist.
    #>
    [CmdletBinding(SupportsShouldPRocess)]
    param(
        # The path to the registry key to create.
        [Parameter(Mandatory)]
        [String] $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-Path -Path $Path -PathType Container))
    {
        Write-Information " + ${Path}"
        New-Item -Path $Path -ItemType RegistryKey -Force | Out-String | Write-Verbose
    }
}



function Remove-CRegistryKeyValue
{
    <#
    .SYNOPSIS
    Removes a value from a registry key, if it exists.

    .DESCRIPTION
    If the given key doesn't exist, nothing happens.

    .EXAMPLE
    Remove-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'InstallPath'

    Removes the `InstallPath` value from the `hklm:\Software\Carbon\Test` registry key.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the registry key where the value should be removed.
        [Parameter(Mandatory)]
        [String] $Path,

        # The name of the value to remove.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-CRegistryKeyValue -Path $Path -Name $Name))
    {
        return
    }

    if (-not $PSCmdlet.ShouldProcess(("Item: ${Path} Property: ${Name}"), 'Remove Property'))
    {
        return
    }

    Write-Information "   ${Path}  - ${Name}"
    Remove-ItemProperty -Path $Path -Name $Name
}



function Revoke-CRegistryPermission
{
    <#
    .SYNOPSIS
    Revokes *explicit* registry key permissions

    .DESCRIPTION
    The `Revoke-CRegistryPermission` function removes all of a user or group's *explicit* permission on a registry key.
    Inherited permissions are ignored. Pass the registry key path to the `Path` parameter. Pass the identity whose
    permissions to remove to the `Identity` parameter. If the identity doesn't exist, or the user doesn't have any
    permissions on the registry key, no error is written and nothing happens.

    .LINK
    Get-CRegistryPermission

    .LINK
    Grant-CRegistryPermission

    .LINK
    Test-CRegistryPermission

    .EXAMPLE
    Revoke-CRegistryPermission -Identity ENTERPRISE\Engineers -Path 'hklm:\EngineRoom'

    Demonstrates how to revoke all of the 'Engineers' permissions on the `hklm:\EngineRoom` registry key.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The registry key path on which the permissions should be revoked.
        [Parameter(Mandatory)]
        [String] $Path,

        # The user/group name losing permissions.
        [Parameter(Mandatory)]
        [String] $Identity
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Revoke-CPermission @PSBoundParameters
}



function Set-CRegistryKeyValue
{
    <#
    .SYNOPSIS
    Sets a value in a registry key.

    .DESCRIPTION
    The `Set-CRegistryKeyValue` function sets the value of a registry key. If the key doesn't exist, it is created
    first. Uses PowerShell's `New-ItemPropery` to create the value if doesn't exist. Otherwise uses `Set-ItemProperty`
    to set the value.

    `DWord` and `QWord` values are stored in the registry as unsigned integers. If you pass a negative integer for the
    `DWord` and `QWord` parameters, PowerShell will convert it to an unsigned integer before storing. You won't get the
    same negative number back.

    To store integer values greater than `[Int32]::MaxValue` or `[Int64]::MaxValue`, use the `UDWord` and `UQWord`
    parameters, respectively, which are unsigned integers. These parameters were in Carbon 2.0.

    In versions of Carbon before 2.0, you'll need to convert these large unsigned integers into signed integers. You
    can't do this with casting. Casting preservers the value, not the bits underneath. You need to re-interpret the
    bits. Here's some sample code:

        # Carbon 1.0
        $bytes = [BitConverter]::GetBytes( $unsignedInt )
        $signedInt = [BitConverter]::ToInt32( $bytes, 0 )  # Or use `ToInt64` if you're working with 64-bit/QWord values
        Set-CRegistryKeyValue -Path $Path -Name 'MyUnsignedDWord' -DWord $signedInt

        # Carbon 2.0
        Set-CRegistryKeyValue -Path $Path -Name 'MyUnsignedDWord' -UDWord $unsignedInt

    .LINK
    Get-CRegistryKeyValue

    .LINK
    Test-CRegistryKeyValue

    .EXAMPLE
    Set-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name Status -String foobar

    Creates the `Status` string value under the `hklm:\Software\Carbon\Test` key and sets its value to `foobar`.

    .EXAMPLE
    Set-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name ComputerName -String '%ComputerName%' -Expand

    Creates an expandable string.  When retrieving this value, environment variables will be expanded.

    .EXAMPLE
    Set-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test -Name Movies -String ('Signs','Star Wars','Raiders of the Lost Ark')

    Sets a multi-string (i.e. array) value.

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'SomeBytes' -Binary ([byte[]]@( 1, 2, 3, 4))

    Sets a binary value (i.e. `REG_BINARY`).

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnInt' -DWord 48043

    Sets a binary value (i.e. `REG_DWORD`).

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnInt64' -QWord 9223372036854775807

    Sets a binary value (i.e. `REG_QWORD`).

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnUnsignedInt' -UDWord [uint32]::MaxValue

    Demonstrates how to set a registry value with an unsigned integer or an integer bigger than `[int]::MaxValue`.

    The `UDWord` parameter was added in Carbon 2.0. In earlier versions of Carbon, you have to convert the unsigned
    int's bits to a signed integer:

        $bytes = [BitConverter]::GetBytes( $unsignedInt )
        $signedInt = [BitConverter]::ToInt32( $bytes, 0 )
        Set-CRegistryKeyValue -Path $Path -Name 'MyUnsignedDWord' -DWord $signedInt

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'AnUnsignedInt64' -UQWord [uint64]::MaxValue

    Demonstrates how to set a registry value with an unsigned 64-bit integer or a 64-bit integer bigger than
    `[long]::MaxValue`.

    The `UQWord parameter was added in Carbon 2.0. In earlier versions of Carbon, you have to convert the unsigned int's
    bits to a signed integer:

        $bytes = [BitConverter]::GetBytes( $unsignedInt )
        $signedInt = [BitConverter]::ToInt64( $bytes, 0 )
        Set-CRegistryKeyValue -Path $Path -Name 'MyUnsignedDWord' -DWord $signedInt

    .EXAMPLE
    Set-CRegistryKeyValue -Path hklm:\Software\Carbon\Test -Name 'UsedToBeAStringNowShouldBeDWord' -DWord 1 -Force

    Uses the `Force` parameter to delete the existing `UsedToBeAStringNowShouldBeDWord` before re-creating it.  This
    flag is useful if you need to change the type of a registry value.
    #>
    [CmdletBinding(SupportsShouldPRocess, DefaultParameterSetName='String')]
    param(
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        [Parameter(Mandatory)]
        [String] $Path,

        # The name of the value being set.
        [Parameter(Mandatory)]
        [String] $Name,

        # The value's data.  Creates a value for holding string data (i.e. `REG_SZ`). If `$null`, the value will be
        # saved as an empty string.
        [Parameter(Mandatory, ParameterSetName='String')]
        [AllowEmptyString()]
        [AllowNull()]
        [String] $String,

        # The string should be expanded when retrieved.  Creates a value for holding expanded string data (i.e.
        # `REG_EXPAND_SZ`).
        [Parameter(ParameterSetName='String')]
        [switch] $Expand,

        # The value's data.  Creates a value for holding binary data (i.e. `REG_BINARY`).
        [Parameter(Mandatory, ParameterSetName='Binary')]
        [byte[]] $Binary,

        # The value's data.  Creates a value for holding a 32-bit integer (i.e. `REG_DWORD`).
        [Parameter(Mandatory, ParameterSetName='DWord')]
        [int] $DWord,

        # The value's data as an unsigned integer (i.e. `UInt32`).  Creates a value for holding a 32-bit integer (i.e.
        # `REG_DWORD`).
        [Parameter(Mandatory, ParameterSetName='DWordAsUnsignedInt')]
        [UInt32] $UDWord,

        # The value's data.  Creates a value for holding a 64-bit integer (i.e. `REG_QWORD`).
        [Parameter(Mandatory, ParameterSetName='QWord')]
        [long] $QWord,

        # The value's data as an unsigned long (i.e. `UInt64`).  Creates a value for holding a 64-bit integer (i.e.
        # `REG_QWORD`).
        [Parameter(Mandatory, ParameterSetName='QWordAsUnsignedInt')]
        [UInt64] $UQWord,

        # The value's data.  Creates a value for holding an array of strings (i.e. `REG_MULTI_SZ`). Pass an empty array
        # or `$null` to set the value to an empty list.
        [Parameter(Mandatory, ParameterSetName='MultiString')]
        [AllowEmptyCollection()]
        [AllowNull()]
        [String[]] $Strings,

        # Removes and re-creates the value.  Useful for changing a value's type.
        [switch] $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $value = $null
    $type = $pscmdlet.ParameterSetName
    switch -Exact ($PSCmdlet.ParameterSetName)
    {
        'String'
        {
            $value = $String
            if( $Expand )
            {
                $type = 'ExpandString'
            }
        }
        'Binary' { $value = $Binary }
        'DWord' { $value = $DWord }
        'QWord' { $value = $QWord }
        'DWordAsUnsignedInt'
        {
            $value = $UDWord
            $type = 'DWord'
        }
        'QWordAsUnsignedInt'
        {
            $value = $UQWord
            $type = 'QWord'
        }
        'MultiString'
        {
            if ($null -eq $Strings)
            {
                $Strings = [String[]]::New(0)
            }
            $value = $Strings
        }
    }

    Install-CRegistryKey -Path $Path

    if ($Force)
    {
        Remove-CRegistryKeyValue -Path $Path -Name $Name
    }

    if (Test-CRegistryKeyValue -Path $Path -Name $Name)
    {
        $updateValue = $false
        $currentValue = Get-CRegistryKeyValue -Path $Path -Name $Name
        if ($PSCmdlet.ParameterSetName -eq 'MultiString')
        {
            [String[]] $currentValues = $currentValue
            if ($null -eq $currentValues)
            {
                $currentValues = @()
            }

            $firstLineWritten = $false
            $msgPrefix = "   ${Path}    ${Name}"
            for ($idx = 0 ; $idx -lt ([Math]::Max($currentValues.Length, $value.Length)) ; ++$idx)
            {
                $fromValue = $null
                $noFromValue = $true
                $toValue = $null
                $noToValue = $true

                $changeMsg = ''
                if ($idx -lt $currentValues.Length)
                {
                    $fromValue = $currentValues[$idx]
                    $noFromValue = $false
                }

                if ($idx -lt $value.Length)
                {
                    $toValue = $value[$idx]
                    $noToValue = $false
                }

                if ($fromValue -eq $toValue)
                {
                    continue
                }

                $changeMsg = "  ${fromValue} -> ${toValue}"
                if ($noFromValue)
                {
                    $changeMsg = "+ ${toValue}"
                }
                elseif ($noToValue)
                {
                    $changeMsg = "- ${fromValue}"
                }

                $updateValue = $true
                $msg = "${msgPrefix}[${idx}]  ${changeMsg}"
                Write-Information $msg

                if (-not $firstLineWritten)
                {
                    $msgPrefix = ' ' * $msgPrefix.Length
                    $firstLineWritten = $true
                }
            }
        }
        else
        {
            $updateValue = ($currentValue -ne $value)
            if ($updateValue)
            {
                Write-Information -Message "   ${Path}    ${Name}  ${currentValue} -> ${value}"
            }
        }

        if ($updateValue)
        {
            Set-ItemProperty -Path $Path -Name $Name -Value $value
        }
    }
    else
    {
        if ($PSCmdlet.ParameterSetName -eq 'MultiString')
        {
            $msgPrefix = "   ${Path}  + ${Name}"
            $firstLineWritten = $false
            for ($idx = 0 ; $idx -lt $value.Length ; ++$idx)
            {
                Write-Information "${msgPrefix}[${idx}]  $($value[$idx])"
                if (-not $firstLineWritten)
                {
                    $firstLineWritten = $true
                    $msgPrefix = ' ' * $msgPrefix.Length
                }
            }
        }
        else
        {
            Write-Information -Message "   ${Path}  + ${Name}  ${value}"
        }
        $null = New-ItemProperty -Path $Path -Name $Name -Value $value -PropertyType $type
    }
}



function Test-CRegistryKeyValue
{
    <#
    .SYNOPSIS
    Tests if a registry value exists.

    .DESCRIPTION
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value.
    This function actually checks if a key has a value with a given name.

    .EXAMPLE
    Test-CRegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'

    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        [Parameter(Mandatory)]
        [String] $Path,

        # The name of the value being set.
        [Parameter(Mandatory)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-Path -Path $Path -PathType Container))
    {
        return $false
    }

    $properties = Get-ItemProperty -Path $Path
    if (-not $properties)
    {
        return $false
    }

    $member = Get-Member -InputObject $properties -Name $Name
    if ($member)
    {
        return $true
    }

    return $false
}



function Test-CRegistryPermission
{
    <#
    .SYNOPSIS
    Tests if a user/group has permissions on a registry key.

    .DESCRIPTION
    The `Test-CRegistryPermission` function tests if a user/gropu has permissions on a registry key. Pass the path to
    the registry key to the `Path` parameter, the user/group name to the `Identity` parameter, and the permission to
    check to the `Permission` parameter. If the user has those permissions, returns `$true`, otherwise returns `$false`.

    By default, the permission check is not exact. For example, if the user/group has `FullControl` access, and
    `ReadKey` is passed as the permission to check, the function would return `$true` because `FullControl` includes the
    `ReadKey` permission. If you want to test if the user/group has the exact permissions passed, use the `Strict`
    switch.

    Inherited permissions on *not* checked by default. To check inherited permission, use the `-Inherited` switch.

    By default, how the permissions are applied to descendent registry keys is ignored. If you also want to check the
    key's "applies to" flags, use tthe `ApplyTo` and `OnlyApplyToChildKeys` parameters.
    .OUTPUTS
    System.Boolean.

    .LINK
    Get-CRegistryPermission

    .LINK
    Grant-CRegistryPermission

    .LINK
    Revoke-CPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx

    .EXAMPLE
    Test-CRegistryPermission -Identity 'STARFLEET\JLPicard' -Permission 'FullControl' -Path 'hklm:\Enterprise\Bridge'

    Demonstrates how to check that Jean-Luc Picard has `FullControl` permission on the `C:\Enterprise\Bridge`.

    .EXAMPLE
    Test-CRegistryPermission -Identity 'STARFLEET\Worf' -Permission 'Write' -ApplyTo 'KeyOnly' -Path 'hlkm:\Enterprise\Brig'

    Demonstrates how to test the "applies to" flags on a registry key by using the `ApplyTo` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='IgnoreAppliesToFlags')]
    param(
        # The registry key path on which the permissions should be checked.
        [Parameter(Mandatory)]
        [String] $Path,

        # The user or group name whose permissions to check.
        [Parameter(Mandatory)]
        [String] $Identity,

        # The permission to test for: e.g. FullControl, ReadKey, etc. Use values from
        # [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        [Parameter(Mandatory)]
        [String[]] $Permission,

        # The "applies to" flags to check for. By default, these flags are ignored.
        [Parameter(Mandatory, ParameterSetName='TestAppliesToFlags')]
        [ValidateSet('KeyOnly', 'KeyAndSubkeys', 'SubkeysOnly')]
        [String] $ApplyTo,

        # Check that the permission is applied only to child keys and no further descendants.
        [Parameter(ParameterSetName='TestAppliesToFlags')]
        [switch] $OnlyApplyToChildKeys,

        # Include inherited permissions in the check.
        [switch] $Inherited,

        # Check for the exact permissions, i.e. make sure the identity has *only* the permissions specified.
        [switch] $Strict
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PSCmdlet.ParameterSetName -eq 'TestAppliesToFlags')
    {
        $PSBoundParameters['ApplyTo'] = $ApplyTo | ConvertTo-CarbonSecurityApplyTo

        $PSBoundParameters.Remove('OnlyApplyToChildKeys') | Out-Null
        if ($OnlyApplyToChildKeys)
        {
            $PSBoundParameters['OnlyApplyToChildren'] = $true
        }
    }

    Test-CPermission @PSBoundParameters
}



function Uninstall-CRegistryKey
{
    <#
    .SYNOPSIS
    Deletes a registry key.

    .DESCRIPTION
    The `Uninstall-CRegistryKey` function deletes a registry key. If the key doesn't exist, nothing happens and no
    errors are written. Pass the path to the registry key to the `Path` parameter. To delete the key and all subkeys,
    use the `Recurse` switch.

    .EXAMPLE
    Uninstall-CRegistryKey -Path 'hklm:\Software\Carbon\Test'

    Demonstrates how to delete a registry key. In this example, the 'hklm:\Software\Carbon\Test' key is deleted if it
    exists.

    .EXAMPLE
    Uninstall-CRegistryKey -Path 'hklm:\Software\Carbon\Test' -Recurse

    Demonstrates how to delete a registry key and all its subkeys. In this example, the 'hklm:\Software\Carbon\Test' key
    is deleted if it exists, along with its subkeys.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the registry key to delete.
        [Parameter(Mandatory)]
        [String] $Path,

        # Use to delete the key and all its subkeys. This switch is required if the key has any subkeys.
        [switch] $Recurse
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Test-Path -Path $Path))
    {
        return
    }

    $confirmArg = @{}
    if ($PSBoundParameters.ContainsKey('Confirm'))
    {
        $confirmArg['Confirm'] = $PSBoundParameters['Confirm']
    }

    Write-Information " - ${Path}"
    Remove-Item -Path $Path -Recurse:$Recurse -Force @confirmArg
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