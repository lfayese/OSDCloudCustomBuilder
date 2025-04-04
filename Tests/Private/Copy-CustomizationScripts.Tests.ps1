# File: Tests/Private/Copy-CustomizationScripts.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/Copy-CustomizationScripts.ps1"

Describe 'Copy-CustomizationScripts' {
    Context 'Basic behavior' {
        It 'Should run without throwing' {
            { Copy-CustomizationScripts } | Should -Not -Throw
        }
    }
}
