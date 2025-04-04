<#
.SYNOPSIS
    Installs the OSDCloudCustomBuilder module from local folder or remote source.
.DESCRIPTION
    Use this script to register the DevReady module locally or deploy it to a PowerShell module path.
#>

param(
    [string]$SourcePath = "$PSScriptRoot",
    [switch]$RegisterOnly
)

$targetModulePath = Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\OSDCloudCustomBuilder"

if (-not $RegisterOnly) {
    Write-Host "Copying module to $targetModulePath..."
    if (Test-Path $targetModulePath) {
        Remove-Item $targetModulePath -Recurse -Force
    }
    Copy-Item -Path $SourcePath -Destination $targetModulePath -Recurse
}

Write-Host "Importing module..."
Import-Module "$SourcePath\OSDCloudCustomBuilder.psd1" -Force -Verbose