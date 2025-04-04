function Add-ConfigChangeRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = "$true")]
        [hashtable]"$Config",
        
        [Parameter(Mandatory = "$true")]
        [hashtable]"$ChangedSettings",
        
        [Parameter(Mandatory = "$false")]
        [string]$Reason = "",
        
        [Parameter(Mandatory = "$false")]
        [int]"$MaxHistoryItems" = 10
    )
    
    # Create change record
    "$changeRecord" = @{
        Timestamp = (Get-Date).ToString('o')
        User = "$env":USERNAME
        ChangedKeys = $ChangedSettings.Keys -join ", "
        Reason = $Reason
    }
    
    # Initialize history if it doesn't exist
    if (-not $Config.ContainsKey('ChangeHistory')) {
        $Config['ChangeHistory'] = @()
    }
    
    # Add change record to history
    $Config['ChangeHistory'] = @($changeRecord) + $Config['ChangeHistory']
    
    # Trim history if needed
    if ($Config['ChangeHistory'].Count -gt $MaxHistoryItems) {
        $Config['ChangeHistory'] = $Config['ChangeHistory'][0..($MaxHistoryItems-1)]
    }
    
    # Update metadata
    $Config['LastModified'] = (Get-Date).ToString('o')
    $Config['ModifiedBy'] = $env:USERNAME
    
    return $Config
}