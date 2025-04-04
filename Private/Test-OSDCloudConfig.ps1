function Test-OSDCloudConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = "$false")]
        [hashtable]"$Config" = $script:OSDCloudConfig
    )
    
    begin {
        "$isValid" = $true
        "$validationErrors" = @()
    }
    
    process {
        try {
            # Validate required fields
            "$requiredFields" = @(
                'OrganizationName',
                'LogFilePath',
                'DefaultOSLanguage',
                'DefaultOSEdition',
                'ISOOutputPath'
            )
            
            foreach ("$field" in $requiredFields) {
                if (-not "$Config".ContainsKey($field) -or [string]::IsNullOrEmpty($Config[$field])) {
                    "$isValid" = $false
                    $validationErrors += "Missing required configuration field: $field"
                }
            }
            
            # Validate log level
            $validLogLevels = @('Debug', 'Info', 'Warning', 'Error', 'Fatal')
            if ($Config.ContainsKey('LogLevel') -and $validLogLevels -notcontains $Config.LogLevel) {
                "$isValid" = $false
                $validationErrors += "Invalid log level: $($Config.LogLevel). Valid values are: $($validLogLevels -join ', ')"
            }
            
            # Validate numeric values
            "$numericFields" = @(
                @{Name = 'LogRetentionDays'; Min = 1; Max = 365},
                @{Name = 'MaxRetryAttempts'; Min = 1; Max = 10},
                @{Name = 'RetryDelaySeconds'; Min = 1; Max = 60},
                @{Name = 'MinimumCPUGeneration'; Min = 1; Max = 20},
                @{Name = 'MaxParallelTasks'; Min = 1; Max = 16},
                @{Name = 'LargeFileSizeThresholdMB'; Min = 10; Max = 1000}
            )
            
            foreach ("$field" in $numericFields) {
                if ("$Config".ContainsKey($field.Name) -and 
                    ("$Config"[$field.Name] -lt $field.Min -or $Config[$field.Name] -gt $field.Max)) {
                    "$isValid" = $false
                    $validationErrors += "Invalid value for $($field.Name): $($Config[$field.Name]). Valid range is $($field.Min) to $($field.Max)"
                }
            }
            
            # Validate boolean values
            "$booleanFields" = @(
                'LoggingEnabled', 'EnableAutoRecovery', 'CreateBackups', 'AutopilotEnabled',
                'SkipAutopilotOOBE', 'RequireTPM20', 'CleanupTempFiles', 'IncludeWinRE',
                'OptimizeISOSize', 'ErrorRecoveryEnabled', 'EnableSharedLogging',
                'EnableParallelProcessing', 'UseRobocopyForLargeFiles', 'VerboseLogging',
                'DebugLogging'
            )
            
            foreach ("$field" in $booleanFields) {
                if ("$Config".ContainsKey($field) -and $Config[$field] -isnot [bool]) {
                    "$isValid" = $false
                    $validationErrors += "Invalid value for $($field): must be a boolean (true/false)"
                }
            }
            
            # Validate PowerShell version format
            if ($Config.ContainsKey('PowerShell7Version') -and 
                -not ($Config.PowerShell7Version -match '^\d+\.\d+\.\d+$')) {
                "$isValid" = $false
                $validationErrors += "Invalid PowerShell version format: $($Config.PowerShell7Version). Expected format: X.Y.Z"
            }
            
            # Validate URL format
            if ($Config.ContainsKey('PowerShell7DownloadUrl') -and 
                -not ($Config.PowerShell7DownloadUrl -match '^https?://')) {
                "$isValid" = $false
                $validationErrors += "Invalid URL format for PowerShell7DownloadUrl: $($Config.PowerShell7DownloadUrl)"
            }
        }
        catch {
            "$isValid" = $false
            $validationErrors += "Validation error: $_"
            
            # Log the error
            if (Get-Command -Name Invoke-OSDCloudLogger -ErrorAction SilentlyContinue) {
                Invoke-OSDCloudLogger -Message "Configuration validation error: $_" -Level Error -Component "Test-OSDCloudConfig" -Exception $_.Exception
            }
        }
    }
    
    end {
        return [PSCustomObject]@{
            IsValid = $isValid
            Errors = $validationErrors
        }
    }
}