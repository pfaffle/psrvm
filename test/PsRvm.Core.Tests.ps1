$srcFile = $MyInvocation.MyCommand.Path `
        -replace 'psrvm\\test\\(.*)\.Tests\.ps1', `
                 'psrvm\src\$1.ps1'
    . $srcFile

Describe 'PsRvm.Core' {
    It 'should exist' {
        psrvm | Should Be (-not $null)
    }
}