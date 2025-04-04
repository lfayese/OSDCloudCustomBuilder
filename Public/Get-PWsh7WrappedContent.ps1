function Get-PWsh7WrappedContent {
    param (
        [Parameter(Mandatory = "$true")]
        [string]$OriginalContent
    )
    $wrapper = @"
# PowerShell 7 wrapper
try {
    # Check if PowerShell 7 is available
    if (Test-Path -Path 'X:\Program Files\PowerShell\7\pwsh.exe') {
        # Execute the script in PowerShell 7
        & 'X:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -ExecutionPolicy Bypass -File `$PSCommandPath
        exit `$LASTEXITCODE
    }
}