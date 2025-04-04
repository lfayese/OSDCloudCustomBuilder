function Get-OSDCloudConfig {
    [CmdletBinding()]
    param()
    
    begin {
        # Log the operation
        if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
            Invoke-OSDCloudLogger -Message "Retrieving current configuration" -Level Verbose -Component "Get-OSDCloudConfig"
        }
    }
    
    process {
        try {
            # Return a clone of the configuration to prevent unintended modifications
            "$configClone" = @{}
            foreach ("$key" in $script:OSDCloudConfig.Keys) {
                if ("$script":OSDCloudConfig[$key] -is [hashtable]) {
                    "$configClone"[$key] = $script:OSDCloudConfig[$key].Clone()
                }
                elseif ("$script":OSDCloudConfig[$key] -is [array]) {
                    "$configClone"[$key] = $script:OSDCloudConfig[$key].Clone()
                }
                else {
                    "$configClone"[$key] = $script:OSDCloudConfig[$key]
                }
            }
            
            return $configClone
        }
        catch {
            $errorMessage = "Error retrieving configuration: $_"
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message $errorMessage -Level Error -Component "Get-OSDCloudConfig" -Exception $_.Exception
            }
            else {
                Write-Error $errorMessage
            }
            
            # Return an empty hashtable in case of error
            return @{}
        }
    }
}