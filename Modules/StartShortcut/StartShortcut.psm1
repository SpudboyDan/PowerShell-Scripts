function New-StartMenuShortcut {
# MUST BE RUN AS ADMIN
# Create initial com object
$Shell = New-Object -ComObject Wscript.Shell;

# Ask host for shortcut name
$NameAnswer = Read-Host -Prompt "Please provide the name for the shortcut";
$Shortcut = $Shell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\$NameAnswer.lnk");

# Ask host for shortcut target path of whatever folder or executable they want to link
$TargetAnswer = Read-Host -Prompt "Please provide the targeted path for the shortcut";
$Shortcut.TargetPath = "$TargetAnswer";

# Ask host for working directory
$WorkingDirectoryAnswer = Read-Host -Prompt "Please provide the working directory for your shortcut `nHint: this should be the same directory that contains the targeted path";
$Shortcut.WorkingDirectory = "$WorkingDirectoryAnswer";

# Save the shortcut
$Shortcut.Save();
}
