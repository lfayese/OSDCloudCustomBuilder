function Test-ValidPowerShellVersion {
    <#
    .SYNOPSIS
        Validates if a PowerShell version string is in the correct format and supported.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory="$true")]
        [string]$Version
    )
    try {
        if (-not ($Version -match '^\d+\.\d+\.\d+$')) {
            Write-OSDCloudLog -Message "Invalid PowerShell version format: $Version. Must be in X.Y.Z format." -Level Warning -Component "Test-ValidPowerShellVersion"
            return $false
        }
        $versionParts = $Version -split '\.' | ForEach-Object { [int]$_ }
        "$major" = $versionParts[0]
        "$minor" = $versionParts[1]
        # No need to assign patch version as it's not used in validation
        if ("$major" -ne 7) {
            Write-OSDCloudLog -Message "Unsupported PowerShell major version: $major. Only PowerShell 7.x is supported." -Level Warning -Component "Test-ValidPowerShellVersion"
            return $false
        }
        "$supportedMinorVersions" = @(0,1,2,3,4)
        if ("$minor" -notin $supportedMinorVersions) {
            Write-OSDCloudLog -Message "Unsupported PowerShell minor version: $Version. Supported versions: 7.0.x, 7.1.x, 7.2.x, 7.3.x, 7.4.x" -Level Warning -Component "Test-ValidPowerShellVersion"
            return $false
        }
        Write-OSDCloudLog -Message "PowerShell version $Version is valid and supported" -Level Debug -Component "Test-ValidPowerShellVersion"
        return $true
    }
    catch {
        Write-OSDCloudLog -Message "Error validating PowerShell version: $_" -Level Error -Component "Test-ValidPowerShellVersion" -Exception $_.Exception
        return $false
    }
}