if (Get-Module psrvm) { Remove-Module psrvm }
$srcFile = $MyInvocation.MyCommand.Path `
        -replace 'psrvm\\test\\(.*)\.Tests\.ps1', `
                 'psrvm\src\$1.ps1'
. $srcFile

Describe 'PsRvm.Core' {
    It 'should provide the psrvm command' {
        Get-Command psrvm | Should Not BeNullOrEmpty
    }
}
