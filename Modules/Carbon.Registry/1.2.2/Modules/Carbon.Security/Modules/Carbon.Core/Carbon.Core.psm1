# Copyright Aaron Jensen and WebMD Health Services
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


function Add-CTypeData
{
    <#
    .SYNOPSIS
    Adds type data to a type only if the type data doesn't already exist.

    .DESCRIPTION
    The `Add-CTypeData` function uses PowerShell's `Update-TypeData` cmdlet to add type data to a type, but only if the
    given type data doesn't already exist. Pass the type to the `Type` parameter or the type name to the `TypeName`
    parameter, the new type data member type to the `MemberType` parameter (e.g. `AliasProperty`, `NoteProperty`, 
    `ScriptProperty`, or `ScriptMethod`), the member name to the `MemberName` parameter, and the member's
    value/implementation to the `Value` parameter.

    Note that the `Type` parameter should be the bare name of the type, e.g. `Diagnostics.Process`, *without* square
    brackets.

    If the type already has an equivalent member with the name given by the `MemberName` parameter, nothing happens, and
    the function returns.

    .EXAMPLE
    Add-CTypeData -Type Diagnostics.Process -MemberType ScriptProperty  -MemberName 'ParentID' -Value $scriptBlock

    Demonstrates how to create a script property on a type. In this example, the `System.Diagnostics.Process` type will
    be given a `ParentID` property that runs the code in the script block in the `$scriptBlock` variable.

    .EXAMPLE
    Add-CTypeData -Type Diagnostics.Process -MemberType ScriptMethod  -MemberName 'GetParentID()' -Value $scriptBlock

    Demonstrates how to create a script method on a type. In this example, the `System.Diagnostics.Process` type will
    be given a `GetParentID()` method that runs the code in the script block in the `$scriptBlock` variable.

    .EXAMPLE
    Add-CTypeData -Type Diagnostics.Process -MemberType AliasProperty  -MemberName 'ProcessId' -Value 'Id'

    Demonstrates how to create an alias script property on a type. In this example, the `System.Diagnostics.Process`
    type will be given a `ProcessId` property that is an alias to the 'Id' property.

    .EXAMPLE
    Add-CTypeData -Type Diagnostics.Process -MemberType NoteProperty  -MemberName 'ParentID' -Value $parentPid

    Demonstrates how to create a ntoe property on a type. In this example, the `System.Diagnostics.Process` type will
    be given a `ParentID` property that returns the value in the `$parentPid` variable.
    #>
    [CmdletBinding()]
    param(
        # The type on which to add the type data. This should be the bare type name, e.g. Diagnostics.Process, *not*
        # the type surrounded by square brackets, e.g. `[Diagnostics.Process]`.
        [Parameter(Mandatory, ParameterSetName='ByType')]
        [Type] $Type,

        # The name of the type on which to add the type data.
        [Parameter(Mandatory, ParameterSetName='ByTypeName')]
        [String] $TypeName,

        # The member type of the new type data. Only `AliasProperty`, `NoteProperty`, `ScriptProperty`, `ScriptMethod`
        # are supported.
        [Parameter(Mandatory)]
        [ValidateSet('AliasProperty', 'NoteProperty', 'ScriptProperty', 'ScriptMethod')]
        [Management.Automation.PSMemberTypes] $MemberType,

        # The type data's member name.
        [Parameter(Mandatory)]
        [String] $MemberName,

        # The value for the member. If `MemberName` is:
        #
        # * `AliasProperty`, this should be the name of the target property.
        # * `NoteProperty`, the literal value of the property.
        # * `ScriptProperty`, a script block that return's the property value.
        # * `ScriptMethod`, a script block that implements the method logic.
        [Parameter(Mandatory)]
        [Object] $Value
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $memberTypeMsg = '{0,-14}' -f $MemberType

    if( -not $TypeName )
    {
        $TypeName = $Type.FullName
    }

    if( $Type )
    {
        if( $MemberType -like '*Property' )
        {
            if( ($Type.GetProperties() | Where-Object Name -EQ $MemberName) )
            {
                Write-Debug ("Type        $($memberTypeMsg)  [$($TypeName)]  $($MemberName)")
                return
            }
        }
        elseif( $MemberType -like '*Method')
        {
            if( ($Type.GetMethods() | Where-Object Name -EQ $MemberName) )
            {
                Write-Debug ("Type        $($memberTypeMsg)  [$($TypeName)]  $($MemberName)")
                return
            }
        }
    }

    $typeData = Get-TypeData -TypeName $TypeName
    if( $typeData -and $typeData.Members.ContainsKey($MemberName) )
    {
        Write-Debug ("TypeData    $($memberTypeMsg)  [$($TypeName)]  $($MemberName)")
        return
    }

    Write-Debug ("TypeData  + $($memberTypeMsg)  [$($TypeName)]  $($MemberName)")
    Update-TypeData -TypeName $TypeName -MemberType $MemberType -MemberName $MemberName -Value $Value
}




function ConvertTo-CBase64
{
    <#
    .SYNOPSIS
    Base64 encodes things.
    
    .DESCRIPTION
    The `ConvertTo-CBase64` function base64 encodes things. Pipe what you want to encode to `ConvertTo-CBase64`. The
    function can encode:
    
    * [String]
    * [byte]
    * [char]
    * Signed integers: [int16], [int], [int64] (i.e. [long])
    * Unsigned integers: [uint16], [uint32], [uint64]
    * Floating point numbers: [float], [double]
    * [bool]

    For each item piped to `ConvertTo-CBase64`, the function returns that item base64 encoded.

    If you pipe all bytes or all chars to `ConvertTo-CBase64`, it will encode all the bytes and chars together. This
    allows you to do this:

        [IO.File]::ReadAllBytes('some file') | ConvertTo-CBase64

    and get back a single string for all the bytes/chars.

    By default, `ConvertTo-CBase64` uses Unicode/UTF-16 encoding when converting strings to base64 (this is the default
    encoding of strings by .NET and PowerShell). To use a different encoding, pass it to the `Encoding` parameter
    (`[Text.Encoding] | Get-Member -Static` will show all the default encodings).

    .EXAMPLE
    'Encode me, please!' | ConvertTo-CBase64
    
    Demonstrates how to encode a string in base64.
    
    .EXAMPLE
    'Encode me, please!' | ConvertTo-CBase64 -Encoding ([Text.Encoding]::ASCII)
    
    Demonstrates how to use a custom encoding when converting a string to base64. The parenthesis around the encoding
    is required by the PowerShell language.

    .EXAMPLE
    [IO.File]::ReadAllBytes('path to some file') | ConvertTo-CBase64

    Demonstrates that you can pipe an array of bytes to `ConvertTo-CBase64` and you'll get back a single string of all
    the bytes base64 encoded.

    .EXAMPLE
    [IO.File]::ReadAllText('path to some file').ToCharArray() | ConvertTo-CBase64

    Demonstrates that you can pipe an array of chars to `ConvertTo-CBase64` and you'll get back a single string of all
    the chars base64 encoded.

    .EXAMPLE
    @( $true, [int16]1, [int]2, [long]3, [uint16]4, [uint32]5, [uint64]6, [float]7.8, [double]9.0) | ConvertTo-CBase64

    Demonstrates that `ConvertTo-CBase64` can convert booleans, all sizes of signed and unsigned ints, floats, and 
    doubles to base64.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [AllowNull()]
        [AllowEmptyString()]
        # The value to base64 encode.
        [Object]$InputObject,
        
        # The encoding to use. Default is Unicode/UTF-16 (the default .NET encoding for strings). This parameter is only
        # used if encoding a string or char array.
        [Text.Encoding]$Encoding = ([Text.Encoding]::Unicode)
    )
    
    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        $collector = $null
        $collectingBytes = $false
        $collectingChars = $false
        $collecting = $false
        $stopProcessing = $false
        $inspectedFirstItem = $false
    }

    process
    {
        if( $stopProcessing )
        {
            return
        }

        if( $null -eq $InputObject )
        {
            return 
        }

        if( $InputObject -is [Collections.IEnumerable] -and $InputObject -isnot [String] )
        {
            Write-Debug "$($InputObject.GetType().FullName)"
            $InputObject | ConvertTo-CBase64 -Encoding $Encoding
            return
        }

        $isByte = $InputObject -is [byte]
        $isChar = $InputObject -is [char]

        if( $PSCmdlet.MyInvocation.ExpectingInput -and -not $inspectedFirstItem ) 
        {
            $inspectedFirstItem = $true

            if( $isByte )
            {
                $collecting = $true
                $collectingBytes = $true
                $collector = [Collections.Generic.List[byte]]::New()
                Write-Debug -Message ("Collecting bytes.")
            }
            elseif( $isChar )
            {
                $collecting = $true
                $collectingChars = $true
                $collector = [Collections.Generic.List[char]]::New()
                Write-Debug -Message ("Collecting chars.")
            }
        }

        if( $collecting )
        {
            # Looks like we didn't get passed an array of bytes or chars, but an array of mixed object types.
            if( (-not $isByte -and $collectingBytes) -or (-not $isChar -and $collectingChars) )
            {
                $collecting = $false

                # Since we are no longer collecting, we need to encode all the previous items we collected.
                foreach( $item in $collector )
                {
                    ConvertTo-CBase64 -InputObject $item -Encoding $Encoding
                }
                ConvertTo-CBase64 -InputObject $InputObject -Encoding $Encoding
                return
            }

            [void]$collector.Add($InputObject)
            return
        }

        if( $InputObject -is [String] )
        {
            return [Convert]::ToBase64String($Encoding.GetBytes($InputObject))
        }

        if( $isByte )
        {
            return [Convert]::ToBase64String([byte[]]$InputObject)
        }

        if( $InputObject -is [bool] -or $isChar -or $InputObject -is [int16] -or $InputObject -is [int] -or `
            $InputObject -is [long] -or $InputObject -is [uint16] -or $InputObject -is [uint32] -or `
            $InputObject -is [uint64] -or $InputObject -is [float] -or $InputObject -is [double] )
        {
            return [Convert]::ToBase64String([BitConverter]::GetBytes($InputObject))
        }

        $stopProcessing = $true
        $msg = "Failed to base64 encode ""$($InputObject.GetType().FullName)"" object. The " +
               'ConvertTo-CBase64 function can only convert strings, chars, bytes, bools, all signed and unsigned ' +
               'integers, floats, and doubles.'
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
    }

    end
    {
        if( $stopProcessing )
        {
            return
        }

        if( -not $collecting )
        {
            return
        }

        if( $collectingChars )
        {
            $bytes = $Encoding.GetBytes($collector.ToArray())
        }
        elseif( $collectingBytes )
        {
            $bytes = $collector.ToArray()
        }

        [Convert]::ToBase64String($bytes)
    }
}



function Get-CPathProvider
{
    <#
    .SYNOPSIS
    Returns a path's PowerShell provider.

    .DESCRIPTION
    When you want to do something with a path that depends on its provider, use this function.  The path doesn't have to
    exist.

    If you pass in a relative path, it is resolved relative to the current directory.  So make sure you're in the right
    place.

    .OUTPUTS
    System.Management.Automation.ProviderInfo.

    .EXAMPLE
    Get-CPathProvider -Path 'C:\Windows'

    Demonstrates how to get the path provider for an NTFS path.
    #>
    [CmdletBinding()]
    param(
        # The path whose provider to get.
        [Parameter(Mandatory)]
        [String] $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $driveName = $Path | Split-Path -Qualifier -ErrorAction Ignore
    if (-not $driveName)
    {
        $driveName = Get-Location | Split-Path -Qualifier -ErrorAction Ignore
        if (-not $driveName)
        {
            $driveName = (Get-Location).Path.Substring(0, 1)
        }
    }

    $driveName = $driveName.TrimEnd(':')

    $drive = Get-PSDrive -Name $driveName -ErrorAction Ignore
    if( -not $drive )
    {
        $drive = Get-PSDrive -PSProvider $driveName -ErrorAction Ignore
    }

    if (-not $drive)
    {
        $msg = "Failed to get provider for path ${Path} because there is no drive named ""${driveName}"" and no " +
               "that uses provider ""${driveName}""."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $drive | Select-Object -First 1 | Select-Object -ExpandProperty 'Provider'
}



function Get-CPowershellPath
{
    <#
    .SYNOPSIS
    Gets the path to powershell.exe.

    .DESCRIPTION
    Returns the path to the powershell.exe binary for the machine's default architecture (i.e. x86 or x64).  If you're
    on a x64 machine and want to get the path to x86 PowerShell, set the `x86` switch.
    
    Here are the possible combinations of operating system, PowerShell, and desired path architectures, and the path
    they map to.
    
        +-----+-----+------+--------------------------------------------------------------+
        | OS  | PS  | Path | Result                                                       |
        +-----+-----+------+--------------------------------------------------------------+
        | x64 | x64 | x64  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        | x64 | x64 | x86  | $env:windir\SysWOW64\Windows PowerShell\v1.0\powershell.exe  |
        | x64 | x86 | x64  | $env:windir\sysnative\Windows PowerShell\v1.0\powershell.exe |
        | x64 | x86 | x86  | $env:windir\SysWOW64\Windows PowerShell\v1.0\powershell.exe  |
        | x86 | x86 | x64  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        | x86 | x86 | x86  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        +-----+-----+------+--------------------------------------------------------------+
    
    .EXAMPLE
    Get-CPowerShellPath

    Returns the path to the version of PowerShell that matches the computer's architecture (i.e. x86 or x64).

    .EXAMPLE
    Get-CPowerShellPath -x86

    Returns the path to the x86 version of PowerShell. Only valid on Windows.
    #>
    [CmdletBinding()]
    param(
        # The architecture of the PowerShell executable to run. The default is the architecture of the current 
        # process.
        [switch]$x86
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Debug "[Carbon\Get-CPowerShellPath]"

    # Map the system directory name from the current PowerShell architecture to the requested architecture.
    $sysDirNames = @{
        # If PowerShell is 64-bit
        'x64' = @{
            # These are paths to PowerShell matching requested architecture.
            'x64' = 'System32';
            'x86' = 'SysWOW64';
        };
        # If PowerShell is 32-bit.
        'x86' = @{
            # These are the paths to get to the appropriate architecture.
            'x64' = 'sysnative';
            'x86' = 'System32';
        }
    }

    $executableName = 'powershell.exe'
    $edition = 'Desktop'
    if( (Test-CPowerShell -IsCore) )
    {
        $edition = 'Core'
        $executableName = 'pwsh'
        if( (Test-COperatingSystem -IsWindows) )
        {
            $executableName = "$($executableName).exe"
        }
    }
    Write-Debug -Message "  Edition                        $($edition)"

    # PowerShell is always in the same place on x86 Windows.
    $osArchitecture = 'x64'
    if( (Test-COperatingSystem -Is32Bit) )
    {
        $osArchitecture = 'x32'
        return Join-Path -Path $PSHOME -ChildPath $executableName
    }
    Write-Debug -Message "  Operating System Architecture  $($osArchitecture)"

    $architecture = 'x64'
    if( $x86 )
    {
        $architecture = 'x86'
    }

    $psArchitecture = 'x64'
    if( (Test-CPowerShell -Is32Bit) )
    {
        $psArchitecture = 'x86'
    }

    Write-Debug -Message "  PowerShell Architecture        $($psArchitecture)"
    Write-Debug -Message "  Requested Architecture         $($architecture)"
    $sysDirName = $sysDirNames[$psArchitecture][$architecture]
    Write-Debug -Message "  Architecture SysDirName        $($sysDirName)"

    $path = $PSHOME -replace '\b(System32|SysWOW64)\b', $sysDirName
    return Join-Path -Path $path -ChildPath $executableName
}



function Invoke-CPowerShell
{
    <#
    .SYNOPSIS
    Invokes a new `powershell.exe` process.
    
    .DESCRIPTION
    The `Invoke-CPowerShell` scripts executes a new PowerShell process. Pass the parameters to pass to the executable
    to the ArgumentList parameter. The function uses the `&` operator to run PowerShell. By default, the PowerShell
    executable in `$PSHOME` is used. In Windows PowerShell (i.e. powershell.exe), the PowerShell executable in "$PSHOME"
    that matches the architecture of the operating system. Use the `x86` switch to use 32-bit `powershell.exe`. Because
    this function uses the `&` operator to execute PowerShell, all the PowerShell streams from the invoked command are
    returned (e.g. stdout, verbose, warning, error, stderr, etc.).

    To use a different PowerShell executable, like PowerShell Core (i.e. pwsh), pass the path to the PowerShell
    executable to the `Path` parameter. If the PowerShell executable is in your PATH, you can pass just the executable
    name.

    If you want to run an encoded command, pass it to the `Command` parameter. The value of the Command parameter will
    be base64 encoded and added to the end of the arguments in the ArgumentList parameter, along with the 
    "-EncodedCommand" switch.
    
    You can run the PowerShell process as a different user by passing that user's credentials to the `Credential`
    parameter. `Invoke-CPowerShell` uses the Start-Job cmdlet to start a background job with those credentials. 
    `Start-Job` runs PowerShell with the `&` operator.
    
    There is a known issue on Linux and macOS that prevents the `Start-Job` cmdlet (what `Invoke-CPowerShell` uses to 
    run PowerShell as another user) from starting PowerShell as another user. See 
    https://github.com/PowerShell/PowerShell/issues/7172 for more information.

    .EXAMPLE
    Invoke-CPowerShell -ArgumentList '-NoProfile','-NonInteractive','-Command','$PID'
    
    Demonstrates how to start a new PowerShell process.
    
    .EXAMPLE
    Invoke-CPowerShell -Command $aLargePSScript -ArgumentList '-NoProfile','-NonInteractive'
    
    Demonstrates how to run an encoded command. In this example, `Invoke-CPowerShell` encodes the command in the 
    `Command` parameter, then runs PowerShell with `-NoProfile -NonInteractive -EncodedCommand $encodedCommand`
    parameters.
    
    .EXAMPLE
    Invoke-CPowerShell -Credential $cred -ArgumentList '-NoProfile','-NonInteractive','-Command','[Environment]::UserName'
    
    Demonstrates how to run PowerShell as a different user by passing that user's credentials to the `Credential`
    parameter. This credential is passed to the `Start-Job` cmdlet's `Credential` parameter, then PowerShell is
    executed using the `&` operator.
    
    .EXAMPLE
    Invoke-CPowerShell -x86 -ArgumentList '-Command','[Environment]::Is64BitProcess'
    
    Demonstrates how to run PowerShell in a 32-bit process. This switch only has an effect on 64-bit Windows operating
    systems. On other systems, use the `-Path` parameter to run PowerShell with a different architecture (which must
    be installed).

    .EXAMPLE
    Invoke-CPowerShell -Path 'pwsh' -ArgumentList '-Command','$PSVersionTable.Edition'

    Demonstrates how to use a custom PowerShell executable. In this case the first `pwsh` command found in your PATH
    environment variable is used.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        # Any arguments to pass to PowerShell. They are passed as-is, so you'll need to handle any necessary 
        # escaping.
        #
        # If you need to run an encoded command, use the `Command` parameter to pass the command and this parameter to
        # pass other parameters. The encoded command will be added to the end of the arguments.
        [Object[]]$ArgumentList,

        # The command to run, as a string. The command will be base64 encoded first and passed to PowerShell's 
        # `EncodedCommand` parameter.
        [String]$Command,
        
        # Run PowerShell as a specific user. Pass that user's credentials.
        #
        # There is a known issue on Linux and macOS that prevents the `Start-Job` cmdlet (what `Invoke-CPowerShell`
        # uses to run PowerShell as another user) from starting PowerShell as another user. See 
        # https://github.com/PowerShell/PowerShell/issues/7172 for more information.
        [pscredential]$Credential,

        # Run the x86 (32-bit) version of PowerShell. If not provided, the version which matches the OS architecture
        # is used, *regardless of the architecture of the currently running process*. I.e. this command is run under
        # a 32-bit PowerShell on a 64-bit operating system, without this switch, `Invoke-CPowerShell` will start a 
        # 64-bit "PowerShell".
        #
        # This switch is only used on Windows.
        [switch]$x86,

        # The path to the PowerShell executable to use. The default is to use the executable in "$PSHOME". On Windows,
        # the PowerShell executable in the "$PSHOME" that matches the operating system's architecture is used.
        #
        # If the PowerShell executable is in your `PATH`, you can pass the executable name instead.
        [String]$Path
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $Path )
    {
        $params = @{ }
        if( $x86 )
        {
            $params.x86 = $true
        }

        $Path = Get-CPowerShellPath @params
    }

    $ArgumentList = & {
        if( $ArgumentList )
        {
            $ArgumentList | Write-Output
        }

        if( $Command )
        {
            '-EncodedCommand' | Write-Output
            $Command | ConvertTo-CBase64 | Write-Output
        }
    }

    Write-Verbose -Message $Path
    $ArgumentList | ForEach-Object { Write-Verbose -Message "    $($_)" }
    if( $Credential )
    {
        $location = Get-Location
        $currentDir = [Environment]::CurrentDirectory
        $output = $null
        $WhatIfPreference = $false
        Start-Job -Credential $Credential -ScriptBlock {
                    Set-Location $using:location
                    [Environment]::CurrentDirectory = $using:currentDir
                    & $using:Path $using:ArgumentList
                    $LASTEXITCODE
                    exit $LASTEXITCODE
                } | 
            Receive-Job -Wait -AutoRemoveJob |
            Tee-Object 'output' |
            Select-Object -SkipLast 1

        $LASTEXITCODE = $output | Select-Object -Last 1
    }
    else
    {
        & $Path $ArgumentList
    }
    Write-Verbose -Message "  LASTEXITCODE  $($LASTEXITCODE)"
}




function Resolve-CFullPath
{
    <#
    .SYNOPSIS
    Converts a relative path to an absolute path.

    .DESCRIPTION
    Unlike `Resolve-Path`, this function does not check whether the path exists. It just converts relative paths to
    absolute paths using .NET's `[IO.Path]::GetFullPath()` method.

    Unrooted paths (e.g. `..\..\See\I\Do\Not\Have\A\Root`) are first joined with the current directory (as returned by
    `Get-Location`).

    .EXAMPLE
    Resolve-CFullPath -Path 'C:\Projects\Carbon\Test\..\Carbon\FileSystem.ps1'

    Returns `C:\Projects\Carbon\Carbon\FileSystem.ps1`.

    .EXAMPLE
    Resolve-CFullPath -Path 'C:\Projects\Carbon\..\I\Do\Not\Exist'

    Returns `C:\Projects\I\Do\Not\Exist`.

    .EXAMPLE
    Resolve-CFullPath -Path ..\..\Foo\..\Bar

    Because the `Path` isn't rooted, joins `Path` with the current directory (as returned by `Get-Location`), and
    returns the full path.  If the current directory is `C:\Projects\Carbon`, returns `C:\Bar`.
    #>
    [CmdletBinding()]
    param(
        # The path to resolve.
        [Parameter(Mandatory)]
        [String] $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not ([System.IO.Path]::IsPathRooted($Path)))
    {
        $Path = Join-Path -Path (Get-Location) -ChildPath $Path
    }
    return [IO.Path]::GetFullPath($Path)
}



function Test-COperatingSystem
{
    <#
    .SYNOPSIS
    Tests attributes of the current operating system.
    
    .DESCRIPTION
    The `Test-COperatingSystem` function tests atrributes of the current operating system, returning `$true` if they
    are `$true` and `$false` otherwise. It supports the following switches (only one can be given at at time) that 
    return the following attributes:

    * `Is32Bit`: is the architecture 32-bit? Uses `[Environment]::Is64BitOperatingSystem`.
    * `Is64Bit`: is the architecture 64-bit? Uses `[Environment]::Is64BitOperatingSystem`.
    * `IsWindows`: is the operating system Windows? Uses the `$IsWindows` built-in variable, it it exists. If it doesn't,
      returns `$true` (only Windows operating systems don't have this variable).
    * `IsLinux`: is the operating system Linux? Uses the `$IsLinux` built-in variable, if it exists. If it doesn't,
      returns `$false` (all Linux systems have the `IsLinux` variable).
    * `IsMacOS`: is the operating system macOS? Uses the `$IsMacOS` built-in variable, if it exists. If it doesn't,
      returns `$false` (all macOS systems have the `IsMacOS` variable).


    .OUTPUTS
    System.Boolean.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.environment.is64bitoperatingsystem.aspx
    
    .EXAMPLE
    Test-COperatingSystem -Is32Bit
    
    Demonstrates how to test if the current operating system is 32-bit/x86.

    .EXAMPLE
    Test-COperatingSystem -Is64Bit
    
    Demonstrates how to test if the current operating system is 64-bit/x64.

    .EXAMPLE
    Test-COperatingSystem -IsWindows
    
    Demonstrates how to test if the current operating system is Windows.

    .EXAMPLE
    Test-COperatingSystem -IsLinux
    
    Demonstrates how to test if the current operating system is Linux.

    .EXAMPLE
    Test-COperatingSystem -IsMacOS
    
    Demonstrates how to test if the current operating system is macOS.

    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory,ParameterSetName='Is32Bit')]
        [switch]$Is32Bit,

        [Parameter(Mandatory,ParameterSetName='Is64Bit')]
        [switch]$Is64Bit,

        [Parameter(Mandatory,ParameterSetName='IsWindows')]
        [Alias('IsWindows')]
        [switch]$Windows,

        [Parameter(Mandatory,ParameterSetName='IsLinux')]
        [Alias('IsLinux')]
        [switch]$Linux,

        [Parameter(Mandatory,ParameterSetName='IsMacOS')]
        [Alias('IsMacOS')]
        [switch]$MacOS
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    switch( $PSCmdlet.ParameterSetName )
    {
        'Is32Bit' { return -not [Environment]::Is64BitOperatingSystem }
        'Is64Bit' { return [Environment]::Is64BitOperatingSystem }
        'IsWindows' {
            if( (Test-Path -Path 'variable:IsWindows') )
            {
                return $IsWindows
            }
            return $true
        }
        'IsLinux' { return (Test-Path -Path 'variable:IsLinux') -and $IsLinux }
        'IsMacOS' { return (Test-Path -Path 'variable:IsMacOS') -and $IsMacOS }
    }
}




function Test-CPowerShell
{
    <#
    .SYNOPSIS
    Tests attributes of the current PowerShell process.

    .DESCRIPTION
    The `Test-CPowerShell` function tests attributes of the current PowerShell process (or process hosting the 
    current PowerShell runspace). It uses the following switches to test the following conditions:

    * `Is32Bit`: if the process architecture is 32-bit/x86 (uses `[Environment]::Is64BitProcess`).
    * `Is64Bit`: if the process architecture is 64-bit/x64 (uses `[Environment]::Is64BitProcess`).
    * `IsDesktop`: if the process is running on Windows PowerShell (uses `$PSVersionTable.Edition`; if this property 
       doesn't exist, always returns `$true`).
    * `IsCore`: if the process is running PowerShell Core (uses `$PSVersionTable.Edition`).

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Test-CPowerShell -Is32Bit

    Demonstrates how to test if the current PowerShell process architecture is 32-bit/x86.

    .EXAMPLE
    Test-CPowerShell -Is64Bit

    Demonstrates how to test if the current PowerShell process architecture is 64-bit/x64.

    .EXAMPLE
    Test-CPowerShell -IsDesktop

    Demonstrates how to test if the current PowerShell process is Windows PowerShell.

    .EXAMPLE
    Test-CPowerShell -IsCore

    Demonstrates how to test if the current PowerShell process is Windows Core.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory,ParameterSetName='Is32Bit')]
        [switch]$Is32Bit,

        [Parameter(Mandatory,ParameterSetName='Is64Bit')]
        [switch]$Is64Bit,

        [Parameter(Mandatory,ParameterSetName='IsDesktop')]
        [switch]$IsDesktop,

        [Parameter(Mandatory,ParameterSetName='IsCore')]
        [switch]$IsCore
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    switch( $PSCmdlet.ParameterSetName )
    {
        'Is32Bit' { return -not [Environment]::Is64BitProcess }
        'Is64Bit' { return [Environment]::Is64BitProcess }
        'IsDesktop' { return -not $PSVersionTable['PSEdition'] -or $PSVersionTable['PSEdition'] -eq 'Desktop' }
        'IsCore' { return $PSVersionTable['PSEdition'] -eq 'Core' }
    }
}



function Test-CType
{
    <#
    .SYNOPSIS
    Tests if a .NET type exists.

    .DESCRIPTION
    The `Test-CType` function tests if a .NET type exists. Pass the namespace-qualified type name to the `Name`
    parameter. For the quickest and most unambiguous type resolution, pass the [assembly-qualifed type
    name](https://learn.microsoft.com/en-us/dotnet/api/system.type.assemblyqualifiedname#system-type-assemblyqualifiedname)
    to the `Name` parameter. Otherwise, the function checks each loaded assembly for the type. If the named type is
    found, returns `$true`. Otherwise, returns `$false`. It stops searching as soon as it finds a type.

    By default, searches are case-insensitive. To perform a case-sensitive search, use the `CaseSenstive` switch.

    By default, returns `$true` if at least one type exists. Otherwise, returns `$false`. Use the `$PassThru` switch to
    get `[Type]` objects returned for all types whose names match.

    .EXAMPLE
    Test-CType -Name 'System.String'

    Demonstrates that you must call `Test-CType` with at least the namespace-qualified type name, not just the type's
    base name.

    .EXAMPLE
    Test-CType -Name 'Carbon.Core.ExampleType' -CaseSensitive

    Demonstrates how to perform a case-sensitive search.

    .EXAMPLE
    Test-CType -Name 'Carbon.Core.DuplicateType' -PassThru

    Demonstrates how to get `[Type]` object returned for all loaded types that match the passed in type name.
    #>
    [CmdletBinding()]
    param(
        # The namespace-qualified type name of the type whose existence to test. Assmbly-qualified type names are also
        # supported and result in the fastest and least ambiguous lookup and results.
        [Parameter(Mandatory, Position=0)]
        [String] $Name,

        # By default, searches are case-insensitive. Use this switch to make the search case-sensitive.
        [switch] $CaseSensitive,

        # By default, the function returns `$true` if at least one type exists whose name equals the name passed in. Use
        # this switch to instead get `[Type]` objects returns for all types whose name is equal to the value of the
        # `Name` parameter.
        [switch] $PassThru
    )

    Set-STrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $ignoreCase = -not $CaseSensitive

    $type = [Type]::GetType($Name, $false, $ignoreCase)
    if ($type)
    {
        if ($PassThru)
        {
            $found = $true
            $type | Write-Output
        }
        else
        {
            return $true
        }
    }

    foreach ($assembly in [AppDomain]::CurrentDomain.GetAssemblies())
    {
        $type = $assembly.GetType($Name, $false, $ignoreCase)
        if (-not $type)
        {
            continue
        }

        if ($PassThru)
        {
            $found = $true
            $type | Write-Output
            continue
        }

        return $true
    }

    if ($PassThru)
    {
        return
    }

    return $false
}



function Test-CTypeDataMember
{
    <#
    .SYNOPSIS
    Tests if a type has an extended type member defined.

    .DESCRIPTION
    `Test-CTypeDataMember` tests if a type has an extended type member defined. If the type isn't found, you'll get an
    error.

    Returns `$true` if the type is found and the member is defined. Otherwise, returns `$false`.

    .EXAMPLE
    Test-CTypeDataMember -TypeName 'Microsoft.Web.Administration.Site' -MemberName 'PhysicalPath'

    Tests if the `Microsoft.Web.Administration.Site` type has a `PhysicalPath` extended type member defined.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # The type name to check.
        [Parameter(Mandatory)]
        [String] $TypeName,

        # The name of the member to check.
        [Parameter(Mandatory)]
        [String] $MemberName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $typeData = Get-TypeData -TypeName $TypeName
    if( -not $typeData )
    {
        # The type isn't defined or there is no extended type data on it.
        return $false
    }

    return $typeData.Members.ContainsKey( $MemberName )
}




# Copyright 2012 Aaron Jensen
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
# limitations under the License.

function Use-CallerPreference
{
    <#
    .SYNOPSIS
    Sets the PowerShell preference variables in a module's function based on the callers preferences.

    .DESCRIPTION
    Script module functions do not automatically inherit their caller's variables, including preferences set by common parameters. This means if you call a script with switches like `-Verbose` or `-WhatIf`, those that parameter don't get passed into any function that belongs to a module. 

    When used in a module function, `Use-CallerPreference` will grab the value of these common parameters used by the function's caller:

     * ErrorAction
     * Debug
     * Confirm
     * InformationAction
     * Verbose
     * WarningAction
     * WhatIf
    
    This function should be used in a module's function to grab the caller's preference variables so the caller doesn't have to explicitly pass common parameters to the module function.

    This function is adapted from the [`Get-CallerPreference` function written by David Wyatt](https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d).

    There is currently a [bug in PowerShell](https://connect.microsoft.com/PowerShell/Feedback/Details/763621) that causes an error when `ErrorAction` is implicitly set to `Ignore`. If you use this function, you'll need to add explicit `-ErrorAction $ErrorActionPreference` to every function/cmdlet call in your function. Please vote up this issue so it can get fixed.

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
        [Parameter(Mandatory = $true)]
        #[Management.Automation.PSScriptCmdlet]
        # The module function's `$PSCmdlet` object. Requires the function be decorated with the `[CmdletBinding()]` attribute.
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [Management.Automation.SessionState]
        # The module function's `$ExecutionContext.SessionState` object.  Requires the function be decorated with the `[CmdletBinding()]` attribute. 
        #
        # Used to set variables in its callers' scope, even if that caller is in a different script module.
        $SessionState
    )

    Set-StrictMode -Version 'Latest'

    # List of preference variables taken from the about_Preference_Variables and their common parameter name (taken from about_CommonParameters).
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