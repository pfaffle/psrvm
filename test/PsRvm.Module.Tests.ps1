if (Get-Module psrvm) { Remove-Module psrvm }
$moduleDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\.."
Import-Module "$moduleDir\psrvm.psd1"

Describe "PsRvm.Module" {
    It 'should exist' {
        Get-Module psrvm | Should Not BeNullOrEmpty
    }
    It 'should load PsRvm.Core commands' {
        @((Get-Module psrvm).NestedModules | Select -Expand Name) `
            -contains 'PsRvm.Core' | Should Be $true
    }
}
