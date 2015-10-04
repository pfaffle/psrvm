if (Get-Module psrvm) { Remove-Module psrvm }
$rootDir = Split-Path -Resolve "$($MyInvocation.MyCommand.Path)\.."
$srcFile = $MyInvocation.MyCommand.Path `
        -replace 'psrvm\\test\\(.*)\.Tests\.ps1', `
                 'psrvm\src\$1.ps1'
. $srcFile

Describe 'PsRvm.Core' {
    It 'should provide the Install-Ruby command' {
        Get-Command Install-Ruby | Should Not BeNullOrEmpty
    }
    It 'should install to a default path if one is not specified' {
        Install-Ruby | Should Be "$env:userprofile\.psrvm"
    }
}
