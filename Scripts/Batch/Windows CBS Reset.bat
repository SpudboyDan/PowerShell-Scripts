DEL /F /S /Q /A "%USERPROFILE%/AppData\Local\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalState\Search"

DEL /F /S /Q /A "%USERPROFILE%/AppData\Local\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\Settings"

DEL /F /S /Q /A "%USERPROFILE%/AppData\Local\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\AppData\CacheStorage"

DEL /F /S /Q /A "%USERPROFILE%/AppData\Local\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\AppData\IndexedDB"

pwsh -NoExit -ExecutionPolicy Bypass -Command "& {$manifest = (Get-AppxPackage *MicrosoftWindows.Client.CBS*).InstallLocation + '\AppxManifest.xml' ; Add-AppxPackage -DisableDevelopmentMode -Register $manifest}"
