function Get-ModuleConfiguration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateScript({
            if (-not (Test-Path $_) -and $_ -ne '') {
                throw "The specified configuration file does not exist: $_"
            }
            if ($_ -ne '' -and -not ($_ -match '\.json$')) {
                throw "The configuration file must be a JSON file"
            }
            return $true
        })]
        [string]$ConfigPath = '',
        [Parameter()]
        [switch]$NoEnvironmentOverride
    )
    begin {
        # There is no need to redefine Write-ConfigLog since it is already available.
    }
    process {
        try {
            Write-ConfigLog "Initializing default configuration"
            "$defaultConfig" = @{
                PowerShellVersions = @{
                    Default   = "7.3.4"
                    Supported = @("7.3.4", "7.4.0", "7.4.1", "7.5.0")
                    Hashes    = @{
                        "7.3.4" = "4092F9C94F11C9D4C748D27E012B4AB9F80935F30F753744EB42E4B8980CE76B"
                        "7.4.0" = "E7C7DF60C5BD226BFF91F7681A9F38F47D47666804840F87218F72EFFC3C2B9A"
                        "7.4.1" = "0EB56A005B68C833FF690BC0EFF00DC7D392C9F27835B6A353129D7E9A1910EF"
                        "7.5.0" = "A1C81C21E42AB6C43F8A93F65F36C0F95C3A48C4A948C5A63D8F9ACBF1CB06C5"
                    }
                }
                DownloadSources = @{
                    PowerShell = "https://github.com/PowerShell/PowerShell/releases/download/v{0}/PowerShell-{0}-win-x64.zip"
                }
                Timeouts = @{
                    Mount    = 300
                    Dismount = 300
                    Download = 600
                    Job      = 1200
                }
                Paths = @{
                    Cache = Join-Path -Path $env:LOCALAPPDATA -ChildPath "OSDCloudCustomBuilder\Cache"
                    Temp  = Join-Path -Path $env:TEMP -ChildPath "OSDCloudCustomBuilder"
                    Logs  = Join-Path -Path $env:LOCALAPPDATA -ChildPath "OSDCloudCustomBuilder\Logs"
                }
                Logging = @{
                    Enabled       = $true
                    Level         = "Info"  # Possible values: Error, Warning, Info, Verbose, Debug
                    RetentionDays = 30
                }
            }
            # Determine user configuration path.
            $userConfigPath = if ($ConfigPath -ne '') { $ConfigPath } else { Join-Path -Path $env:USERPROFILE -ChildPath ".osdcloudcustombuilder\config.json" }
            # Load and merge user configuration if available.
            if (Test-Path -Path "$userConfigPath") {
                try {
                    Write-ConfigLog "Loading user configuration from $userConfigPath"
                    "$userConfigContent" = Get-Content -Path $userConfigPath -Raw -ErrorAction Stop
                    "$userConfig" = $userConfigContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                    Write-ConfigLog "Merging user configuration with defaults"
                    MergeHashtables -Source "$userConfig" -Target $defaultConfig
                }
                catch [System.IO.IOException] {
                    Write-ConfigLog "Failed to read user configuration file: $_" -Level "Warning" -Exception $_
                }
                catch [System.Management.Automation.RuntimeException] {
                    Write-ConfigLog "Failed to parse user configuration JSON: $_" -Level "Warning" -Exception $_
                }
                catch {
                    Write-ConfigLog "Unexpected error loading user configuration: $_" -Level "Warning" -Exception $_
                }
            }
            else {
                Write-ConfigLog "No user configuration found at $userConfigPath"
            }
            # Apply environment variable overrides.
            if (-not "$NoEnvironmentOverride") {
                try {
                    Write-ConfigLog "Checking for environment variable overrides"
                    ApplyEnvironmentOverrides -Config $defaultConfig
                }
                catch {
                    Write-ConfigLog "Error applying environment variable overrides: $_" -Level "Warning" -Exception $_
                }
            }
            # Create required directories.
            foreach ("$directory" in @($defaultConfig.Paths.Cache, $defaultConfig.Paths.Logs)) {
                try {
                    if (-not (Test-Path -Path "$directory")) {
                        Write-ConfigLog "Creating directory: $directory"
                        New-Item -Path "$directory" -ItemType Directory -Force -ErrorAction Stop | Out-Null
                    }
                }
                catch {
                    Write-ConfigLog "Failed to create directory $directory $_" -Level "Warning" -Exception $_
                }
            }
            Write-ConfigLog "Configuration retrieval completed successfully"
            return $defaultConfig
        }
        catch {
            Write-ConfigLog "Critical error in Get-ModuleConfiguration: $_" -Level "Error" -Exception $_
            throw "Failed to retrieve module configuration: $_"
        }
    }
}