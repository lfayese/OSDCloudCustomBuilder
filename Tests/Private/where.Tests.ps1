# File: Tests/Private/where.Tests.ps1
# Requires -Modules Pester

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Resolve-Path "$here/../../"
. "$moduleRoot/Private/where.ps1"

Describe 'where' {

    Context 'Execution with mocked internals' {
        It 'Should run without throwing using default logic' {
            # Mock common cmdlets
            Mock -CommandName Test-Path { $true }
            Mock -CommandName Copy-Item { }

            { where } | Should -Not -Throw
        }

        It 'Should handle expected failure scenario gracefully' {
            Mock -CommandName Test-Path { $false }
            { where } | Should -Throw
        }
    }
}
