function Reset-ModuleConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch] $NoSave
    )
    
    $script:Config = $script:DefaultConfig.Clone()
    
    # Update global variable if EnableVerboseLogging is defined
    if ($null -ne $script:Config.EnableVerboseLogging) {
        $global:EnableVerboseLogging = $script:Config.EnableVerboseLogging
    }
    
    Write-Verbose "Configuration reset to defaults."
    
    # Save configuration if not using NoSave switch
    if (-not $NoSave) {
        $configDir = Split-Path -Path $script:ConfigPath -Parent
        if (-not (Test-Path -Path $configDir)) {
            try {
                New-Item -Path $configDir -ItemType Directory -Force | Out-Null
                Write-Verbose "Created configuration directory: $configDir"
            }
            catch {
                Write-Error "Failed to create configuration directory: $configDir. $_"
                return
            }
        }
        
        try {
            $script:Config | ConvertTo-Json -Depth 4 | Set-Content -Path $script:ConfigPath -Force
            Write-Verbose "Default configuration saved to $script:ConfigPath"
        }
        catch {
            Write-Error "Failed to save configuration to $script:ConfigPath. $_"
        }
    }
}