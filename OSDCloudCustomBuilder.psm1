<# 
.SYNOPSIS
    PowerShell module for creating custom OSDCloud ISOs with Windows Image (WIM) files and PowerShell 7 support.
.DESCRIPTION
    This module provides functions to create custom OSDCloud boot media with PowerShell 7 integration.
    It includes capabilities to import custom Windows images, optimize ISO size, and create bootable media.
.NOTES
    Version: 0.3.0
    Author: OSDCloud Team
    Copyright: (c) 2025 OSDCloud. All rights reserved.
#>
#region Module Setup
# Get module version from manifest to ensure consistency
$ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'OSDCloudCustomBuilder.psd1'
try {
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction Stop
    $script:ModuleVersion = $Manifest.ModuleVersion
}
catch {
    # Fallback version if manifest can't be read
    $script:ModuleVersion = "0.3.0"
    Write-Warning "Could not read module version from manifest: $_"
}

# Support for different PowerShell module paths
$PSModuleRoot = $PSScriptRoot
if (-not $PSModuleRoot) {
    if ($ExecutionContext.SessionState.Module.PrivateData.PSPath) {
        $PSModuleRoot = Split-Path -Path $ExecutionContext.SessionState.Module.PrivateData.PSPath
    }
    else {
        $PSModuleRoot = $PWD.Path
        Write-Warning "Could not determine module root path, using current directory: $PSModuleRoot"
    }
}
$script:ModuleRoot = $PSModuleRoot
Write-Verbose "Loading OSDCloudCustomBuilder module v$script:ModuleVersion from $script:ModuleRoot"

# Enforce TLS 1.2 for secure communications with PS edition awareness
if ($PSEdition -ne 'Core') {
    # Only needed for Windows PowerShell; PowerShell Core handles this automatically
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Verbose "TLS 1.2 protocol enforced: $([Net.ServicePointManager]::SecurityProtocol)"
}
else {
    Write-Verbose "Running on PowerShell Core - TLS configuration handled automatically"
}

# Set strict mode to catch common issues
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Make sure we're running on the required PowerShell version
$requiredPSVersion = [Version]'5.1'
if ($PSVersionTable.PSVersion -lt $requiredPSVersion) {
    $errorMsg = "PowerShell $($requiredPSVersion) or higher is required. Current version: $($PSVersionTable.PSVersion)"
    Write-Error $errorMsg
    throw $errorMsg
}

# Define path to PowerShell 7 package in the OSDCloud folder
$script:PowerShell7ZipPath = Join-Path -Path (Split-Path -Parent $script:ModuleRoot) -ChildPath "OSDCloud\PowerShell-7.5.0-win-x64.zip"
if ([System.IO.File]::Exists($script:PowerShell7ZipPath)) {
    Write-Verbose "PowerShell 7 package found at: $script:PowerShell7ZipPath"
}
else {
    Write-Warning "PowerShell 7 package not found at: $script:PowerShell7ZipPath"
}

# Check if running in PS7+ for faster methods
$script:IsPS7OrHigher = $PSVersionTable.PSVersion.Major -ge 7

# Initialize logging system
function Initialize-ModuleLogging {
    [OutputType([void])]
    [CmdletBinding()]
    param()
    
    if ($EnableVerboseLogging) { 
        Write-Verbose 'Verbose logging enabled.'
    }
    $script:LoggerExists = $false
    try {
        $loggerCommand = Get-Command -Name Invoke-OSDCloudLogger -ErrorAction Stop
        $script:LoggerExists = $true
        Write-Verbose "OSDCloud logger found: $($loggerCommand.Source)"
    }
    catch {
        Write-Verbose "OSDCloud logger not available, using standard logging"
    }
    
    # Create a fallback logging function if needed
    if (-not $script:LoggerExists) {
        if (-not (Get-Command -Name Write-OSDCloudLog -ErrorAction SilentlyContinue)) {
            function global:Write-OSDCloudLog {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory = $true, Position = 0)]
                    [string] $Message,
                    [Parameter()]
                    [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
                    [string] $Level = 'Info',
                    [Parameter()]
                    [string] $Component = 'OSDCloudCustomBuilder'
                )
                
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logMessage = "[$timestamp] [$Level] [$Component] $Message"
                
                switch ($Level) {
                    'Info'    { Write-Host $logMessage }
                    'Warning' { Write-Warning $Message }
                    'Error'   { Write-Error $Message }
                    'Debug'   { Write-Debug $logMessage }
                    default   { Write-Host $logMessage }
                }
            }
        }
    }
}

# Call the logging initialization
Initialize-ModuleLogging

#region Function Import
# Import Private Functions
$PrivateFunctions = @(Get-ChildItem -Path "$PSModuleRoot\Private" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue)
foreach ($Private in $PrivateFunctions) {
    try {
        . $Private.FullName
        Write-Verbose "Imported private function: $($Private.BaseName)"
    }
    catch {
        Write-Warning "Failed to import private function $($Private.FullName): $_"
    }
}

# Import Public Functions
$PublicFunctions = @(Get-ChildItem -Path "$PSModuleRoot\Public" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue)
foreach ($Public in $PublicFunctions) {
    try {
        . $Public.FullName
        Write-Verbose "Imported public function: $($Public.BaseName)"
    }
    catch {
        Write-Warning "Failed to import public function $($Public.FullName): $_"
    }
}

# Export public functions from manifest if available, otherwise export all public functions
if ($Manifest -and $Manifest.FunctionsToExport) {
    $FunctionsToExport = $Manifest.FunctionsToExport
}
else {
    $FunctionsToExport = $PublicFunctions.BaseName
}

# Export aliases if defined in manifest
if ($Manifest -and $Manifest.AliasesToExport) {
    Export-ModuleMember -Function $FunctionsToExport -Alias $Manifest.AliasesToExport
}
else {
    Export-ModuleMember -Function $FunctionsToExport
}
#endregion Function Import