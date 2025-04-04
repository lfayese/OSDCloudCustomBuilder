function Update-ModuleConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable] $Settings,
        
        [Parameter()]
        [switch] $NoSave
    )
    
    # Ensure configuration is initialized
    if (-not $script:Config) {
        Write-Verbose "Configuration not found, initializing..."
        Initialize-ModuleConfiguration
    }
    
    # Update settings
    foreach ($key in $Settings.Keys) {
        if ($key -eq "Timeouts" -and $Settings[$key] -is [hashtable]) {
            foreach ($timeoutKey in $Settings[$key].Keys) {
                $script:Config.Timeouts[$timeoutKey] = $Settings[$key][$timeoutKey]
            }
        }
        else {
            $script:Config[$key] = $Settings[$key]
            
            # Update global variable if this is EnableVerboseLogging
            if ($key -eq 'EnableVerboseLogging') {
                $global:EnableVerboseLogging = $Settings[$key]
            }
        }
    }
    
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
            Write-Verbose "Configuration saved to $script:ConfigPath"
        }
        catch {
            Write-Error "Failed to save configuration to $script:ConfigPath. $_"
        }
    }
}