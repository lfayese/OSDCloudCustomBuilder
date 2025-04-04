<#
.SYNOPSIS
    Sample usage to validate the module is working as expected.
#>

Import-Module OSDCloudCustomBuilder -Force

Write-Host "`n--- Running sample public function ---`n"
$result = Get-PWsh7WrappedContent -Content 'Write-Host "Hello from PowerShell 7"'
Write-Output $result