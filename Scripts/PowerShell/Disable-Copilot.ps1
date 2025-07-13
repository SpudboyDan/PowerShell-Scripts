# Turns off Copilot
New-Item -Path HKCU:\Software\Policies\Microsoft\Windows\ -Name WindowsCopilot;
New-ItemProperty -Path HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot\ -Name TurnOffWindowsCopilot -PropertyType DWord -Value 1 -Force;
