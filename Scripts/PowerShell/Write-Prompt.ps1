function private:Write-Prompt {
    param([Parameter(Mandatory = $true, Position = 0)]
        [string]$Caption,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Message,
        [Parameter(Mandatory = $true, Position = 2)]
        [string]$LabelA,
        [Parameter(Mandatory = $false, Position = 3)]
        [string]$HelpA,
        [Parameter(Mandatory = $true, Position = 4)]
        [string]$LabelB,
        [Parameter(Mandatory = $false, Position = 5)]
        [string]$HelpB,
        [Parameter(Mandatory = $false, Position = 6)]
        [int]$DefaultChoice = (-1))

    $private:Choices = [Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]]@(
        [Management.Automation.Host.ChoiceDescription]::new([string]"&$Label1", [string]"$Help1")
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label2", [string]"$Help2"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label3", [string]"$Help3"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label4", [string]"$Help4"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label5", [string]"$Help5"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label6", [string]"$Help6"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label7", [string]"$Help7"));
        [Management.Automation.Host.ChoiceDescription]::new([string]"&$Label8", [string]"$Help8")
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label9", [string]"$Help9"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label10", [string]"$Help10"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label11", [string]"$Help11"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label12", [string]"$Help12"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label13", [string]"$Help13"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label14", [string]"$Help14"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label15", [string]"$Help15"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label16", [string]"$Help16"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label17", [string]"$Help17"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label18", [string]"$Help18"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label19", [string]"$Help19"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label20", [string]"$Help20"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label21", [string]"$Help21"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label22", [string]"$Help22"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label23", [string]"$Help23"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label24", [string]"$Help24"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label25", [string]"$Help25"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label26", [string]"$Help26"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label27", [string]"$Help27"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label28", [string]"$Help28"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label29", [string]"$Help29"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label30", [string]"$Help30"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label31", [string]"$Help31"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label32", [string]"$Help32"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label33", [string]"$Help33"));
	[Management.Automation.Host.ChoiceDescription]::new([string]"&$Label34", [string]"$Help34"));

    $Host.UI.PromptForChoice($Caption, $Message, $Choices, $DefaultChoice);
}
