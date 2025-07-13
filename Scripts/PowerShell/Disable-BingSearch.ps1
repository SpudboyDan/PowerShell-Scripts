# Removes Bing/Web Search function from Windows Search Bar
New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\ -Name BingSearchEnabled -PropertyType DWord -Value 0 -Force;
