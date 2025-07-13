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
using namespace System.Text

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

# Functions should use $script:moduleRoot as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$script:moduleRoot = $PSScriptRoot

# We add the assembly ourselves instead of in the .psd1 file so that this module can be nested and imported from its
# .psm1, which creates one fewer nested scope levels.
Add-Type -Path (Join-Path -Path $script:moduleRoot -ChildPath 'bin\PureInvoke.dll' -Resolve)

# Constants
[IntPtr] $script:invalidHandle = -1
$script:maxPath = 65535

enum PureInvoke_ErrorCode
{
    Ok                       = 0x000
    NERR_Success             = 0x000
    Success                  = 0x000
    InvalidFunction          = 0x001
    FileNotFound             = 0x002
    AccessDenied             = 0x005
    InvalidHandle            = 0x006
    HandleEof                = 0x026    #   38
    InvalidParameter         = 0x057    #   87
    InsufficientBuffer       = 0x07A    #  122
    AlreadyExists            = 0x0B7    #  183
    EnvVarNotFound           = 0x0cb    #  203
    MoreData                 = 0x0ea    #  234
    NoMoreItems              = 0x103    #  259
    InvalidFlags             = 0x3EC    # 1004
    ServiceMarkedForDelete   = 0x430    # 1072
    NoneMapped               = 0x534    # 1332
    NoSuchAlias              = 0x560    # 1376
    MemberNotInAlias         = 0x561    # 1377
    MemberInAlias            = 0x562    # 1378
    NoSuchMember             = 0x56B    # 1387
    InvalidMember            = 0x56C    # 1388
    NERR_GroupNotFound       = 0x8AC    # 2220
    NERR_InvalidComputer     = 0x92f    # 2351
}

[Flags()]
enum PureInvoke_LsaLookup_PolicyAccessRights
{
    LocalInformation = 0x1
    AuditInformation = 0x2
    GetPrivateInformation = 0x4
    TrustAdmin = 0x8
    CreateAccount = 0x10
    CreateSecret = 0x20
    CreatePrivilege = 0x40
    SetQuotaDefaultLimits = 0x80
    SetAuditRequirements = 0x100
    AuditLogAdmin = 0x200
    ServerAdmin = 0x400
    LookupNames = 0x800
    Notification = 0x1000
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



function Assert-NTStatusSuccess
{
    [CmdletBinding()]
    param(
        [UInt32] $Status,

        [String] $Message
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # https://learn.microsoft.com/en-us/windows-hardware/drivers/kernel/using-ntstatus-values
    if ($Status -le 0x3FFFFFFF -or ($Status -ge 0x40000000 -and $Status -le 0x7FFFFFFF))
    {
        return $true
    }

    $win32Err = Invoke-AdvApiLsaNtStatusToWinError -Status $ntstatus
    Write-Win32Error -ErrorCode $win32Err -Message $Message
    return $false
}


function Assert-Win32Error
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int] $ErrorCode,

        [String] $Message
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($ErrorCode -eq [PureInvoke_ErrorCode]::Ok)
    {
        return $true
    }

    Write-Win32Error -ErrorCode $ErrorCode -Message $Message
    return $false
}


function ConvertTo-IntPtr
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='SecurityIdentifier')]
        [SecurityIdentifier] $Sid,

        [Parameter(Mandatory, ParameterSetName='LUID')]
        [PureInvoke.WinNT.LUID] $LUID
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($Sid)
    {
        $sidBytes = [byte[]]::New($Sid.BinaryLength)
        $sid.GetBinaryForm($sidBytes, 0);
        $sidPtr = [Marshal]::AllocHGlobal($sidBytes.Length)
        [Marshal]::Copy($sidBytes, 0, $sidPtr, $sidBytes.Length)
        return $sidPtr
    }

    if ($LUID)
    {
        $size = [Marshal]::SizeOf($LUID)
        $luidPtr = [Marshal]::AllocHGlobal($size)

        $lowBytes = [BitConverter]::GetBytes($LUID.LowPart)
        [Marshal]::Copy($lowBytes, 0, $luidPtr, $lowBytes.Length)

        $highBytes = [BitConverter]::GetBytes($LUID.HighPart)
        [Marshal]::Copy($highBytes, 0, [IntPtr]::Add($luidPtr, $lowBytes.Length), $highBytes.Length)

        return $luidPtr
    }
}


function ConvertTo-LsaUnicodeString
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [String] $InputObject
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        [PureInvoke.LsaLookup.LSA_UNICODE_STRING]::New($InputObject) | Write-Output
    }
}


function Invoke-AdvApiLookupAccountName
{
    <#
    .SYNOPSIS
    Calls the Advanced Windows 32 Base API (advapi32.dll) `LookupAccountName` function.

    .DESCRIPTION
    The `Invoke-AdvApiLookupAccountName` function calls the advapi32.dll API's `LookupAccountName` function, which looks
    up an account name and returns its domain, SID, and use. Pass the account name to the `AccountName` parameter and
    the system name to the `ComputerName` parameter, which are passed to `LookupAccountName` as the `lpAccountName` and
    `lpSystemName` arguments, respectively. The function returns an object with properties for each of the
    `LookupAccountName` function's out parameters: `DomainName`, `Sid`, and `Use`.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountnamea

    .EXAMPLE
    Invoke-AdvApiLookupAccountName -AccountName ([Environment]::UserName)

    Demonstrates how to call this function by passing a username to the `AccountName` parameter.
    #>
    [CmdletBinding()]
    param(
        # The account name to lookup.
        [Parameter(Mandatory)]
        [String] $AccountName,

        # The name of the system.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [byte[]] $sid = [byte[]]::New(0);

    # cb = count of bytes
    [UInt32] $cbSid = 0;
    [StringBuilder] $sbDomainName = [StringBuilder]::New()
    # cch = count of chars
    [UInt32] $cchDomainName = $sbDomainName.Capacity;
    [PureInvoke.WinNT.SidNameUse] $sidNameUse = [PureInvoke.WinNT.SidNameUse]::Unknown;

    $result = [PureInvoke.AdvApi32]::LookupAccountName($ComputerName, $AccountName, $sid, [ref] $cbSid, $sbDomainName,
                                                       [ref] $cchDomainName, [ref]$sidNameUse)
    $errCode = [Marshal]::GetLastWin32Error()

    if (-not $result)
    {
        if ($errCode -eq [PureInvoke_ErrorCode]::InsufficientBuffer -or `
            $errCode -eq [PureInvoke_ErrorCode]::InvalidFlags)
        {
            $sid = [byte[]]::New($cbSid);
            [void]$sbDomainName.EnsureCapacity([int]$cchDomainName);
            $result = [PureInvoke.AdvApi32]::LookupAccountName($ComputerName, $AccountName, $sid, [ref] $cbSid,
                                                               $sbDomainName, [ref] $cchDomainName, [ref] $sidNameUse)
            $errCode = [Marshal]::GetLastWin32Error()
        }

        if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
        {
            return
        }
    }

    return [pscustomobject]@{
        DomainName = $sbDomainName.ToString();
        Sid = $sid
        Use = $sidNameUse
    }
}



function Invoke-AdvApiLookupAccountSid
{
    <#
    .SYNOPSIS
    Calls the Advanced Windows 32 Base API (advapi32.dll) `LookupAccountSid` function.

    .DESCRIPTION
    The `Invoke-AdvApiLookupAccountSid` function calls the advapi32.dll API's `LookupAccountSid` function, which looks
    up a SID and returns its account name, domain name, and use. Pass the SID as a byte array to the `Sid` parameter and
    the system name to the `ComputerName` parameter, which are passed to `LookupAccountSid` as the `Sid` and
    `lpSystemName` arguments, respectively. The function returns an object with properties for each of the
    `LookupAccountSid` function's out parameters: `Name`, `ReferencedDomainName`, and `Use`.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountsida

    .EXAMPLE
    Invoke-AdvApiLookupAccountSid -Sid $sid

    Demonstrates how to call this function by passing a sid to the `Sid` parameter.
    #>
    [CmdletBinding()]
    param(
        # The security identifier whose account to lookup.
        [Parameter(Mandatory)]
        [byte[]] $Sid,

        # The computer's name on which to lookup the SID. Defaults to the current computer. Passed to the
        # `LookupAccountSid` method's `SystemName` parameter.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [StringBuilder] $name = [StringBuilder]::New()
    # cch = count of chars
    [UInt32] $cchName = $name.Capacity;

    [StringBuilder] $domainName = [StringBuilder]::New()
    [UInt32] $cchDomainName = $domainName.Capacity;

    [PureInvoke.WinNT.SidNameUse] $sidNameUse = [PureInvoke.WinNT.SidNameUse]::Unknown;

    $result = [PureInvoke.AdvApi32]::LookupAccountSid($ComputerName, $sid, $name, [ref] $cchName, $domainName,
                                                      [ref] $cchDomainName, [ref] $sidNameUse)
    $errCode = [Marshal]::GetLastWin32Error()

    if (-not $result)
    {
        if ($errCode -eq [PureInvoke_ErrorCode]::InsufficientBuffer)
        {
            [void]$name.EnsureCapacity($cchName);
            [void]$domainName.EnsureCapacity($cchName);
            $result = [PureInvoke.AdvApi32]::LookupAccountSid($ComputerName, $sid,  $name, [ref] $cchName, $domainName,
                                                       [ref] $cchDomainName, [ref] $sidNameUse)
            $errCode = [Marshal]::GetLastWin32Error()
        }

        if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
        {
            return
        }
    }

    return [pscustomobject]@{
        Name = $name.ToString();
        DomainName = $domainName.ToString();
        Use = $sidNameUse;
    }
}


function Invoke-AdvApiLookupPrivilegeName
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LookupPrivilegeName` function to lookup a privilege name from its local unique
    identifier.

    .DESCRIPTION
    The `Invoke-AdvApiLookupPrivilegeName` function calls the advapi32.dll library's `LookupPrivilegeName` function to
    lookup a privilege name from its local unique identifier (i.e. LUID). Pass the privilege's LUID to the `LUID`
    parameter. If the privilege exists, its name is returned. Otherwise nothing is returned and an error is written.

    To run the lookup on a different computer, pass its name to the `ComputerName` parameter, which is passed to the
    `LookupPrivilegeName` function's `SystemName` parameter, i.e. the lookup on the remote computer is done by
    `LookupPrivilegeName`, not PowerShell.

    .EXAMPLE
    Invoke-AdvapiLookupPrivilegeName -Luid $luid

    Demonstrates how to call this function.
    #>
    [CmdletBinding()]
    param(
        # The privilege value whose name to lookup.
        [Parameter(Mandatory)]
        [PureInvoke.WinNT.LUID] $LUID,

        # The computer name on which to lookup the value. This parameter is passed to the `LookupPrivilegeValue`
        # function's `SystemName` parameter, i.e. the lookup on the remote computer is done by `LookupPrivilegeValue`
        # not PowerShell.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sbName = [StringBuilder]::New(1)
    $nameLength = $sbName.Capacity

    $ptrLuid = ConvertTo-IntPtr -LUID $LUID

    try
    {
        $result = [PureInvoke.AdvApi32]::LookupPrivilegeName($ComputerName, $ptrLuid, $sbName, [ref] $nameLength)
        $errCode = [Marshal]::GetLastWin32Error()

        if (-not $result)
        {
            if ($errCode -eq [PureInvoke_ErrorCode]::InsufficientBuffer)
            {
                [void]$sbName.EnsureCapacity($nameLength)
                $result = [PureInvoke.AdvApi32]::LookupPrivilegeName($ComputerName, $ptrLuid, $sbName, [ref] $nameLength)
                $errCode = [Marshal]::GetLastWin32Error()
            }

            if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
            {
                return
            }
        }

        return $sbName.ToString()
    }
    finally
    {
        [Marshal]::FreeHGlobal($ptrLuid)
    }
}


function Invoke-AdvApiLookupPrivilegeValue
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LookupPrivilegeValue` function to lookup a privilege's local unique identifier.

    .DESCRIPTION
    The `Invoke-AdvApiLookupPrivilegeValue` function calls the advapi32.dll library's `LookupPrivilegeValue` function to
    lookup a privilege's LUID from its name. Pass the privilege's name to the `Name` parameter. If the privilege exists,
    its LUID is returned. Otherwise nothing is returned and an error is written.

    To run the lookup on a different computer, pass its name to the `ComputerName` parameter, which is passed to the
    `LookupPrivilegeValue` function's `SystemName` parameter, i.e. the lookup on the remote computer is done by
    `LookupPrivilegeValue`, not PowerShell.

    Privilege names *do not* include account rights, even though the names look similar. The following [known account
    rights](https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants) are not supported by
    `LookupPrivilegeValue`:

    * SeBatchLogonRight
    * SeDenyBatchLogonRight
    * SeDenyInteractiveLogonRight
    * SeDenyNetworkLogonRight
    * SeDenyRemoteInteractiveLogonRight
    * SeDenyServiceLogonRight
    * SeInteractiveLogonRight
    * SeNetworkLogonRight
    * SeRemoteInteractiveLogonRight
    * SeServiceLogonRight

    .EXAMPLE
    Invoke-AdvapiLookupPrivilegeName -Name SeDebugPrivilege

    Demonstrates how to call this function.
    #>
    [CmdletBinding()]
    param(
        # The privilege name whose value to lookup.
        [Parameter(Mandatory)]
        [String] $Name,

        # The computer name on which to lookup the value. This parameter is passed to the `LookupPrivilegeValue`
        # function's `SystemName` parameter, i.e. the lookup on the remote computer is done by `LookupPrivilegeValue`
        # not PowerShell.
        [String] $ComputerName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [PureInvoke.WinNT.LUID] $luid = [PureInvoke.WinNT.LUID]::New()
    $result = [PureInvoke.AdvApi32]::LookupPrivilegeValue($ComputerName, $Name, [ref] $luid)
    $errCode = [Marshal]::GetLastWin32Error()

    if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
    {
        return
    }

    return $luid
}


function Invoke-AdvApiLsaAddAccountRights
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaAddAccountRights` function.

    .DESCRIPTION
    The `Invoke-AdvApiLsaAddAccountRights` function calls the advapi32.dll `LsaAddAccountRights` function. Pass a policy
    handle to the `PolicyHandle` parameter (use `Invoke-AdvApiLsaOpenPolicy` to create a policy handle), the security
    identifier for the account receiving rights to the `Sid` parameter, and a list of privileges/rights to add to the
    `Privilege` parameter. The account is granted the given rights.

    If the call succeeds, returns `$true`. Otherwise, returns `$false` and an error is written.

    .EXAMPLE
    Invoke-AdvApiLsaAddAccountRights -PolicyHandle $handle -Sid $sid -Privilege 'SeBatchLogonRight'

    Demonstrates how to call `Invoke-AdvApiLsaAddAccountRights`.
    #>
    [CmdletBinding()]
    param(
        # A handle to the policy. Use `Invoke-AdvApiLsaOpenPolicy` to get a handle. When opening the handle to add
        # account rights, you must use `LookupNames` and `CreateAccount` to the desired access.
        [Parameter(Mandatory)]
        [IntPtr] $PolicyHandle,

        # The account security identifier receiving the rights/privileges.
        [Parameter(Mandatory)]
        [SecurityIdentifier] $Sid,

        # The list of privileges to add.
        [Parameter(Mandatory)]
        [String[]] $Privilege
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sidPtr = ConvertTo-IntPtr -Sid $Sid

    [PureInvoke.LsaLookup.LSA_UNICODE_STRING[]] $lsaPrivs = $Privilege | ConvertTo-LsaUnicodeString

    try
    {
        $ntstatus = [PureInvoke.AdvApi32]::LsaAddAccountRights($PolicyHandle, $sidPtr, $lsaPrivs, $lsaPrivs.Length)

        Assert-NTStatusSuccess -Status $ntstatus -Message 'LsaAddAccountRights failed'
    }
    finally
    {
        [Marshal]::FreeHGlobal($sidPtr)
    }
}



function Invoke-AdvApiLsaClose
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaClose` method to close an LSA policy handle.

    .DESCRIPTION
    The `Invoke-AdvApiLsaClose` function calls the advapi32.dll library's `LsaClose` method to close an LSA policy
    handle that was created with `Invoke-AdvApiLsaOpenPolicy`. Pass the policy handle to the `PolicyHandle` parameter.
    The function closes the policy and returns `$true` if the close succeeded. If the close fails, returns `$false` and
    writes an error.

    Closing a handle more than once may result in a process crash. After closing a handle, it is recommended to set it
    to `[IntPtr]::Zero` as a precaution. This function will ignore a policy handle set to `[IntPtr]::Zero`.

    .EXAMPLE
    Invoke-AdvApiLsaClose -PolicyHandle $handle

    Demonstrates how to call `Invoke-AdvApiLsaClose`.
    #>
    [CmdletBinding()]
    param(
        # The policy handle to close. Use `Invoke-AdvApiLsaOpenPolicy` to create policy handles.
        [Parameter(Mandatory)]
        [IntPtr] $PolicyHandle
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($PolicyHandle -eq [IntPtr]::Zero)
    {
        return $true
    }

    $ntstatus = [PureInvoke.AdvApi32]::LsaClose($PolicyHandle)
    Assert-NTStatusSuccess -Status $ntstatus -Message 'Invoke-AdvApiLsaClose failed'
}



function Invoke-AdvApiLsaEnumerateAccountRights
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll assembly's `LsaEnumerateAccountRights` function to get the list of an account's
    rights/privileges.

    .DESCRIPTION
    The `Invoke-AdvApiLsaEnumerateAccountRights` function calls the advapi32.dll assembly's `LsaEnumerateAccountRights`
    function to get the list of an account's rights/privileges. Pass a handle to the LSA policy to the `PolicyHandle`
    parameter (use `Invoke-AdvApiLsaOpenPolicy` to create a policy handle). Pass the security identifier for the account
    to the `Sid` parameter. The account's rights are returned. If the account has no rights, then nothing is returned.
    If getting the account's rights fails, nothing is returned and the function writes an error.

    In order to read an account's rights, the policy must be opened with the `LookupNames` access right.

    .EXAMPLE
    Invoke-AdvApiLsaEnumerateAccountRights -PolicyHandle $handle -Sid $sid

    Demonstrates how to call `Invoke-AdvApiLsaEnumerateAccountRights`
    #>
    [CmdletBinding()]
    param(
        # A policy handle. Use `Invoke-AdvApiLsaOpenPolicy` to get a handle. When opening the handle to get account
        # rights, you must request `LookupNames` access.
        [Parameter(Mandatory)]
        [IntPtr] $PolicyHandle,

        # The security identifier of the account whose rights/privileges to get.
        [Parameter(Mandatory)]
        [SecurityIdentifier] $Sid
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sidPtr = ConvertTo-IntPtr -Sid $Sid

    [IntPtr] $rightsPtr = [IntPtr]::Zero

    try
    {
        [UInt32] $rightsCount = 0
        $ntstatus = [PureInvoke.AdvApi32]::LsaEnumerateAccountRights($PolicyHandle, $sidPtr, [ref] $rightsPtr,
                                                                     [ref] $rightsCount)

        $win32Err = Invoke-AdvApiLsaNtStatusToWinError -Status $ntstatus
        if ($win32Err -eq [PureInvoke_ErrorCode]::FileNotFound)
        {
            return
        }

        if (-not (Assert-NtStatusSuccess -Status $ntstatus -Message 'Invoke-AdvApiLsaEnumerateAccountRights failed'))
        {
            return
        }

        [PureInvoke.LsaLookup.LSA_UNICODE_STRING[]] $lsaPrivs =
            [PureInvoke.LsaLookup.LSA_UNICODE_STRING]::PtrToLsaUnicodeStrings($rightsPtr, $rightsCount)
        foreach ($lsaPriv in $lsaPrivs)
        {
            $lsaPrivLength = $lsaPriv.Length/[Text.UnicodeEncoding]::CharSize
            $cvt = [char[]]::New($lsaPrivLength)
            [Marshal]::Copy($lsaPriv.Buffer, $cvt, 0, $lsaPrivLength);
            [String]::New($cvt) | Write-Output
        }
    }
    finally
    {
        Invoke-AdvApiLsaFreeMemory -Handle $rightsPtr | Out-Null
        [Marshal]::FreeHGlobal($sidPtr)
    }
}


function Invoke-AdvApiLsaFreeMemory
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaFreeMemory` function.

    .DESCRIPTION
    The `Invoke-AdvApiLsaFreeMemory` function calls the advapi32.dll library's `LsaFreeMemory` function. Pass the
    pointer whose memory to free to the `Handle` parameter. If the operation succeeds, the function returns `$true`,
    otherwise it returns `$false` and writes an error.

    .EXAMPLE
    Invoke-AdvApiLsaFreeMemory -Handle $rightsPtr

    Demonstrates how to call `Invoke-AdvApiLsaFreeMemory`.
    #>
    [CmdletBinding()]
    param(
        # The handle whose memory should be freed.
        [Parameter(Mandatory)]
        [IntPtr] $Handle
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $ntstatus = [PureInvoke.AdvApi32]::LsaFreeMemory($Handle)
    Assert-NTStatusSuccess -Status $ntstatus -Message 'Invoke-AdvApiLsaFreeMemory failed'
}


function Invoke-AdvApiLsaNtStatusToWinError
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaNtStatusToWinError` function to convert an NTSTATUS error code into a Win32
    error code.

    .DESCRIPTION
    The `Invoke-AdvApiLsaNtStatusToWinError` function calls the advapi32.dll library's `LsaNtStatusToWinError` function
    to convert an NTSTATUS error code into a Win32 error code. Pass the NTSTATUS code to the `Status` parameter. The
    equivalent Win32 error code is returned.

    .EXAMPLE
    Invoke-AdvApiLsaNtStatusToWinError -Status $ntstatus
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [UInt32] $Status
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return [PureInvoke.AdvApi32]::LsaNtStatusToWinError($Status)
}


function Invoke-AdvApiLsaOpenPolicy
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaOpenPolicy` function to open a handle to a computer's LSA policy.

    .DESCRIPTION
    The `Invoke-AdvApiLsaOpenPolicy` function calls the advapi32.dll library's `LsaOpenPolicy` function to open a handle
    to a computer's LSA policy. Pass the desired access to the `DesiredAccess` parameter. The function returns a handle
    to the policy if opening succeeds or, if opening fails, returns nothing and writes an error.

    You can open the LSA policy on a different computer by passing the computer's name to the `ComputerName` parameter.

    .EXAMPLE
    Invoke-AdvApiLsaOpenPolicy -DesiredAccess LookupNames,CreateAccount

    Demonstrates how to open a policy handle that allows reading and setting privileges.
    #>
    [CmdletBinding()]
    param(
        # The desired access for the policy handle. See the documentation for the LSA function/method the policy will
        # be used with to discover what rights are needed.
        [Parameter(Mandatory)]
        [PureInvoke_LsaLookup_PolicyAccessRights[]] $DesiredAccess,

        # The optional computer name whose LSA policy to open. The default is the local computer.
        [String] $ComputerName,

        # The value of the `LsaOpenPolicy` method's `ObjectAttribute` parameter.
        [PureInvoke.LsaLookup.LSA_OBJECT_ATTRIBUTES] $ObjectAttribute
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $lsaSystemName = [PureInvoke.LsaLookup.LSA_UNICODE_STRING]::New([Environment]::MachineName)
    if ($ComputerName)
    {
        $lsaSystemName = [PureInvoke.LsaLookup.LSA_UNICODE_STRING]::New($ComputerName)
    }

    if (-not $ObjectAttribute)
    {
        $ObjectAttribute = [PureInvoke.LsaLookup.LSA_OBJECT_ATTRIBUTES]::New()
        $ObjectAttribute.Length = 0
        $ObjectAttribute.RootDirectory = [IntPtr]::Zero
        $ObjectAttribute.Attributes = 0
        $ObjectAttribute.SecurityDescriptor = [IntPtr]::Zero
        $ObjectAttribute.SecurityQualityOfService = [IntPtr]::Zero
    }

    $policyHandle = [IntPtr]::Zero
    $accessMask = 0x0
    $DesiredAccess | ForEach-Object { $accessMask = $accessMask -bor $_ }

    $ntstatus = [PureInvoke.AdvApi32]::LsaOpenPolicy([ref] $lsaSystemName, [ref] $ObjectAttribute, $accessMask,
                                                     [ref] $policyHandle)

    if (-not (Assert-NtStatusSuccess -Status $ntstatus -Message "Invoke-AdvApiLsaOpenPolicy failed"))
    {
        return
    }

    return $policyHandle
}


function Invoke-AdvApiLsaRemoveAccountRights
{
    <#
    .SYNOPSIS
    Calls the advapi32.dll library's `LsaRemoveAccountRights` method which removes rights/privileges for an account.

    .DESCRIPTION
    The `Invoke-AdvApiLsaRemoveAccountRights` function calls the advapi32.dll library's `LsaRemoveAccountRights` method
    which removes rights/privileges for an account. Pass the LSA policy handle to the `PolicyHandle` parameter. Pass the
    security identifier for the account to the `Sid` parameter. To remove *all* of the account's rights, use the `All`
    switch. Otherwise, pass the specific rights to remove to the `Privilege` parameter. If the removal succeeds, the
    function returns `$true`, otherwise it returns `$false` and writes an error.

    In order to remove rights, the policy must be opened with the `LookupNames` access right.

    .EXAMPLE
    Invoke-AdvApiLsaRemoveAccountRights -PolicyHandle $handle -Sid $sid -All

    Demonstrates how to remove all of an account's privileges.

    .EXAMPLE
    Invoke-AdvApiLsaRemoveAccountRights -PolicyHandle $handle -Sid $sid -Privilege 'SeBatchLogonRight'

    Demonstrates how to remove a specific prilevege for an account.
    #>
    [CmdletBinding()]
    param(
        # A policy handle. Use `Invoke-AdvApiLsaOpenPolicy` to get a handle. When opening the handle to remove account
        # rights, you must request `LookupNames` access.
        [Parameter(Mandatory)]
        [IntPtr] $PolicyHandle,

        # The security identifier of the account whose rights/privileges to remove.
        [Parameter(Mandatory)]
        [SecurityIdentifier] $Sid,

        # If set, removes all of the account's privileges.
        [Parameter(Mandatory, ParameterSetName='All')]
        [switch] $All,

        # A list of the account's specific privileges to remove.
        [Parameter(Mandatory, ParameterSetName='Specific')]
        [String[]] $Privilege
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sidPtr = ConvertTo-IntPtr -Sid $Sid

    try
    {
        if ($All)
        {
            $ntstatus = [PureInvoke.AdvApi32]::LsaRemoveAccountRights($PolicyHandle,
                                                                 $sidPtr,
                                                                 $true,
                                                                 [PureInvoke.LsaLookup.LSA_UNICODE_STRING[]]::New(0),
                                                                 0)
        }
        else
        {
            [PureInvoke.LsaLookup.LSA_UNICODE_STRING[]] $lsaPrivs = $Privilege | ConvertTo-LsaUnicodeString
            $ntstatus =
                [PureInvoke.AdvApi32]::LsaRemoveAccountRights($PolicyHandle, $sidPtr, $false, $lsaPrivs, $lsaPrivs.Length)
        }

        $winErr = Invoke-AdvApiLsaNtStatusToWinError -Status $ntstatus
        if ($winErr -eq [PureInvoke_ErrorCode]::FileNotFound)
        {
            return $true
        }

        Assert-NTStatusSuccess -Status $ntstatus -Message 'LsaRemoveAccountRights failed'
    }
    finally
    {
        [Marshal]::FreeHGlobal($sidPtr)
    }
}


function Invoke-KernelFindFileName
{
    <#
    .SYNOPSIS
    Calls the Win32 `FindFirstFileNameW` and `FindNextFileNameW` functions to get the hardlinks to a file.

    .DESCRIPTION
    The `Invoke-KernelFindFileName` function finds all the hardlinks to a file. It calls the Win32 `FindFirstFileNameW`
    and `FindNextFileNameW` functions to get the paths. It returns the path to each hardlink, which includes the path
    to the file itself. The paths are returned *without* drive qualifiers at the beginning. Since hardlinks can't cross
    physical file systems, their drives will be the same as the source path.

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findfirstfilenamew

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-findnextfilenamew

    .EXAMPLE
    Invoke-KernelFindFileName -Path 'C:\link.txt'

    Demonstrates how to get the hardlinks to a file by passing its path to the `Invoke-KernelFindFileName` function's
    `Path` parameter.
    #>
    [CmdletBinding()]
    param(
        # The path to the file.
        [Parameter(Mandatory)]
        [String] $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    [PureInvoke_ErrorCode] $errCode = [PureInvoke_ErrorCode]::Ok

    # Loop over and collect all hard links as their full paths.
    [IntPtr]$findHandle = [IntPtr]::Zero

    [StringBuilder] $sbLinkName = [Text.StringBuilder]::New()
    [UInt32] $cchLinkName = $sbLinkName.Capacity
    $findHandle = [PureInvoke.Kernel32]::FindFirstFileNameW($Path, 0, [ref]$cchLinkName, $sbLinkName)
    $errCode = [Marshal]::GetLastWin32Error()
    Write-Debug "[Kernel32]::FindFirstFileNameW(""${Path}"", 0, ${cchLinkName}, ""${sbLinkName}"")  return ${findHandle}  GetLastError() ${errCode}"
    if ($script:invalidHandle -eq $findHandle)
    {
        if ($errCode -eq [PureInvoke_ErrorCode]::MoreData)
        {
            [void]$sbLinkName.EnsureCapacity($cchLinkName)
            $findHandle = [PureInvoke.Kernel32]::FindFirstFileNameW($Path, 0, [ref]$cchLinkName, $sbLinkName)
            $errCode = [Marshal]::GetLastWin32Error()
            Write-Debug "[Kernel32]::FindFirstFileNameW(""${Path}"", 0, ${cchLinkName}, ""${sbLinkName}""))  return ${findHandle}  GetLastError() ${errCode}"
            if ($script:invalidHandle -eq $findHandle)
            {
                Write-Win32Error -ErrorCode $errCode
                return
            }
        }
        else
        {
            Write-Win32Error -ErrorCode $errCode
            return
        }
    }

    $linkName = $sbLinkName.ToString()
    if (-not $linkName)
    {
        Write-Win32Error -ErrorCode $errCode
        return
    }

    $linkName | Write-Output

    try
    {
        do
        {
            [void]$sbLinkName.Clear()

            $result = [PureInvoke.Kernel32]::FindNextFileNameW($findHandle, [ref]$cchLinkName, $sbLinkName)
            $errCode = [Marshal]::GetLastWin32Error()
            Write-Debug "[Kernel32]::FindNextFileNameW(${findHandle}, ${cchLinkName}, ""${sbLinkName}""))  return ${result}  GetLastError() ${errCode}"
            if (-not $result -and $errCode -eq [PureInvoke_ErrorCode]::MoreData)
            {
                [void]$sbLinkName.EnsureCapacity($cchLinkName)
                $result = [PureInvoke.Kernel32]::FindNextFileNameW($findHandle, [ref]$cchLinkName, $sbLinkName)
                $errCode = [Marshal]::GetLastWin32Error()
                Write-Debug "[Kernel32]::FindNextFileNameW(${findHandle}, ${cchLinkName}, ""${sbLinkName}""))  return ${result}  GetLastError() ${errCode}"
            }

            if ($result)
            {
                $linkName = $sbLinkName.ToString()
                if (-not $linkName)
                {
                    Write-Win32Error -ErrorCode $errCode
                    return
                }

                $linkName | Write-Output
                continue
            }

            if ($errCode -eq [PureInvoke_ErrorCode]::HandleEof)
            {
                return
            }

            if($errCode -eq [PureInvoke_ErrorCode]::InvalidHandle)
            {
                $msg = 'No matching files found.'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            Write-Win32Error -ErrorCode $errCode
            return
        }
        while ($true)
    }
    finally
    {
        [void][PureInvoke.Kernel32]::FindClose($findHandle);
    }
}



function Invoke-KernelGetVolumePathName
{
    <#
    .SYNOPSIS
    Calls the kernel32.dll libary's `GetVolumePathName` function.

    .DESCRIPTION
    The `Invoke-KernelGetVolumePathName` function calls the kernel32.dll libary's `GetVolumePathName` function which
    gets the volume mount point of the path. Pass the path to the `Path` parameter.

    .EXAMPLE
    Invoke-KernelGetVolumePathName -Path $path

    Demonstrates how to call this function.
    #>
    [CmdletBinding()]
    param(
        # The path whose volume mount point to get.
        [Parameter(Mandatory)]
        [String] $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $sbPath = [StringBuilder]::New($script:maxPath)
    $cchPath = [UInt32]$sbPath.Capacity # in/out character-count variable for the WinAPI calls.
    $result = [PureInvoke.Kernel32]::GetVolumePathName($Path, $sbPath, $cchPath)
    $errCode = [Marshal]::GetLastWin32Error()
    $msg = "[Kernel32]::GetVolumePathName(""${Path}"", [out] ""${sbPath}"", ${cchPath})  return ${result}  " +
           "GetLastError() ${errCode}"
    Write-Debug $msg
    if (-not $result -and -not (Assert-Win32Error -ErrorCode $errCode))
    {
        return
    }

    return $sbPath.ToString()
}


function Invoke-NetApiNetLocalGroupGetMembers
{
    <#
    .SYNOPSIS
    Calls the Win32 netapi32.dll library's `NetLocalGroupGetMembers` method, which gets the members of a local group.

    .DESCRIPTION
    The `Invoke-NetApiNetLocalGroupGetMembers` calls the Win32 netapi32.dll library's `NetLocalGroupGetMembers` method,
    which gets the members of a local group. Pass the name of the local group to the `LocalGroupName` parameter. The
    function will return an object with `SidPtr`, `SidUsage`, and `DomainAndName` properties.

    You can control what information to return with the `Level` parameter, which must be a value between 0 and 3. (The
    default is `2`.) Level 0 will return objects with just `SidPtr` properties. Level 1 will return objects with
    `SidPtr`, `SidUsage`, and `Name` properties. Level 2 (the default) will return objects with `SidPtr`, `SidUsage`,
    and `DomainAndName` properties. Level 3 will return object with just `DomainAndName` properties.

    All `SidPtr` properties are `IntPtr` instances that point to security identifier bytes. To convert the SID pointers
    to actual security identifiers, `[Security.Principal.SecurityIdentifier]::New($_.SidPtr)`.

    The `Name` property is just the sAMAccountName of the principal with no domain or computer information.

    .EXAMPLE
    Invoke-NetApiNetLocalGroupGetMembers -LocalGroupName 'Administrators'

    Demonstrates the simplest way to call this function to get a pointer to the SID, SID usage, and domain and username
    information about all the members of a group. In this example, all the members of the administrators group will be
    returned.

    .EXAMPLE
    Invoke-NetApiNetLocalGroupGetMembers -LocalGroupName 'Administrators' -Level 1

    Demonstrates how to customzie the object and object properties returned by using the `Level` parameter.
    #>
    [CmdletBinding()]
    param(
        [String] $ComputerName,

        [Parameter(Mandatory)]
        [String] $LocalGroupName,

        [ValidateRange(0,3)]
        [int] $Level = 2
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function New-InfoObject
    {
        switch ($Level)
        {
            0
            {
                return [PureInvoke.Lmaccess.LOCALGROUP_MEMBERS_INFO_0]::New()
            }

            1
            {
                return [PureInvoke.Lmaccess.LOCALGROUP_MEMBERS_INFO_1]::New()
            }

            2
            {
                return [PureInvoke.Lmaccess.LOCALGROUP_MEMBERS_INFO_2]::New()
            }

            3
            {
                return [PureInvoke.Lmaccess.LOCALGROUP_MEMBERS_INFO_3]::New()
            }
        }
    }

    [int] $entriesRead = 0
    [int] $totalEntries = 0
    [IntPtr] $resume  = [IntPtr]::Zero
    [IntPtr] $buffer = [IntPtr]::Zero

    do
    {
        $status = [PureInvoke.NetApi32]::NetLocalGroupGetMembers($ComputerName,
                                                                 $LocalGroupName,
                                                                 $Level,
                                                                 [ref] $buffer,
                                                                 -1,
                                                                 [ref] $entriesRead,
                                                                 [ref] $totalEntries,
                                                                 [ref] $resume)
        if ($status -ne [PureInvoke_ErrorCode]::NERR_Success)
        {
            $msg = "Failed getting members of group ""${LocalGroupName}"""
            Assert-Win32Error -ErrorCode $status -Message $msg | Out-Null
            return
        }

        if ($entriesRead -gt 0)
        {
            [IntPtr] $itemAddr = $buffer
            for($i = 0; $i -lt $entriesRead; $i++)
            {
                $member = New-InfoObject
                [Marshal]::PtrToSTructure($itemAddr, [Type]$member.GetType()) |
                    Write-Output
                $itemAddr = [IntPtr]::New($itemAddr.ToInt64() + [Int64][Marshal]::SizeOf($member))
            }
            $status = [PureInvoke.NetApi32]::NetApiBufferFree($buffer)
            Assert-Win32Error -ErrorCode $status | Out-Null
        }
    }
    while ($resume -ne [IntPtr]::Zero)
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


function Write-Win32Error
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int] $ErrorCode,

        [String] $Message
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if ($Message)
    {
        $Message = $Message.TrimEnd('.')
        $Message = "${Message}: "
    }

    $win32Ex = [Win32Exception]::New($ErrorCode)

    $period = '.'
    if ($win32ex.Message.EndsWith('.'))
    {
        $period = ''
    }

    $msg = "${Message}$($win32Ex.Message)${period} (0x$($win32Ex.ErrorCode.ToString('x'))/$($win32Ex.NativeErrorCode))"
    Write-Error -Message $msg -ErrorAction $ErrorActionPreference
}