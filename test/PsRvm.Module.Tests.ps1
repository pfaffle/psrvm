$TEST_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$TEST_DIR\TestHelper.ps1"
Import-Module "$ROOT_DIR\psrvm.psd1"

Describe "PsRvm.Module" {
    It 'should exist' {
        Get-Module psrvm | Should Not BeNullOrEmpty
    }
    It 'should load PsRvm.Core commands' {
        (Get-Module psrvm).NestedModules | Select -Expand Name |
            HasValues @('PsRvm.Core') | Should Be $true
    }
}
