Function Pop-Msg
{
    <#
    DESCRIPTION:
      This function will pop up a message box. This will be really helpful while debugging.

    Usage: Pop-Msg "Text"
    #>
    param([string]$msg ="message",
    [string]$ttl = "Title",
    [int]$type = 64)

    $popwin = New-Object -ComObject WScript.Shell
    $null = $popwin.Popup($msg,0,$ttl,$type)
    Remove-Variable popwin
}

function Pop-Msg {
	 param([string]$msg ="message",
	 [string]$ttl = "Title",
	 [int]$type = 64) 
	 $popwin = New-Object -ComObject WScript.Shell
	 $null = $popwin.Popup($msg,0,$ttl,$type)
	 Remove-Variable popwin
}
