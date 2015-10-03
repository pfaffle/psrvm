$moduleDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\.."
Import-Module "$moduleDir\psrvm.psd1"

Describe "PsRvm.Module" {
    It 'should exist' {
        Get-Module psrvm | Should Be (-not $null)
    }
}