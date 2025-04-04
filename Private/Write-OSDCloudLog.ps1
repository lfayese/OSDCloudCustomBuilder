function Write-OSDCloudLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Position = 1)]
        [LogLevel]$Level = [LogLevel]::Info,
        
        [Parameter()]
        [switch]$NoTimestamp,
        
        [Parameter()]
        [string]$Component = ""
    )
    
    # Initialize logging if not already done
    if (-not $script:LogFile) {
        Initialize-OSDCloudLogging
    }
    
    # Track log statistics
    $script:LogStats.IncrementCounter($Level)
    
    # Skip logging if below minimum level
    if ([int]$Level -lt [int]$script:MinimumLogLevel) {
        return
    }
    
    # Format message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $componentText = if ($Component) { "[$Component] " } else { "" }
    $formattedMessage = "[$timestamp] [$Level] $componentText$Message"
    $consoleMessage = if ($NoTimestamp) { "[$Level] $componentText$Message" } else { $formattedMessage }
    
    # Write to console if enabled
    if ($script:EnableConsoleLogging) {
        switch ($Level) {
            ([LogLevel]::Debug) { 
                Write-Verbose $consoleMessage 
            }
            ([LogLevel]::Info) { 
                Write-Host $consoleMessage 
            }
            ([LogLevel]::Warning) { 
                Write-Warning $Message 
            }
            ([LogLevel]::Error) { 
                $host.UI.WriteErrorLine($consoleMessage) 
            }
            ([LogLevel]::Critical) {
                $currentColor = $host.UI.RawUI.ForegroundColor
                $host.UI.RawUI.ForegroundColor = 'Red'
                Write-Host $consoleMessage -ForegroundColor Red -BackgroundColor Black
                $host.UI.RawUI.ForegroundColor = $currentColor
            }
        }
    }
    
    # Write to file if enabled
    if ($script:EnableFileLogging -and $script:LogWriter) {
        try {
            $script:LogWriter.WriteLine($formattedMessage)
            $script:LogWriter.Flush()
        }
        catch {
            Write-Warning "Failed to write to log file: $_"
            $script:EnableFileLogging = $false
        }
    }
    
    # Write to EventLog if enabled
    if ($script:EnableEventLogging) {
        try {
            $eventType = switch ($Level) {
                ([LogLevel]::Debug) { "Information" }
                ([LogLevel]::Info) { "Information" }
                ([LogLevel]::Warning) { "Warning" }
                ([LogLevel]::Error) { "Error" }
                ([LogLevel]::Critical) { "Error" }
            }
            
            $eventId = switch ($Level) {
                ([LogLevel]::Debug) { 100 }
                ([LogLevel]::Info) { 200 }
                ([LogLevel]::Warning) { 300 }
                ([LogLevel]::Error) { 400 }
                ([LogLevel]::Critical) { 500 }
            }
            
            Write-EventLog -LogName Application -Source "OSDCloudCustomBuilder" -EventId $eventId -EntryType $eventType -Message $Message
        }
        catch {
            Write-Warning "Failed to write to EventLog: $_"
            $script:EnableEventLogging = $false
        }
    }
}