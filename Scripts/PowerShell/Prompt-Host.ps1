using namespace System.Collections;
using namespace System.Management.Automation;

function private:Prompt-Host
{
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

		$private:Choices = [ObjectModel.Collection[Host.ChoiceDescription]]@(
				[Host.ChoiceDescription]::new([string]"&$LabelA", [string]"$HelpA")
				[Host.ChoiceDescription]::new([string]"&$LabelB", [string]"$HelpB"));

	$Host.UI.PromptForChoice($Caption, $Message, $Choices, $DefaultChoice);
}
