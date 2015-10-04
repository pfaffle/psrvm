if (Get-Module psrvm) { Remove-Module psrvm }
$rootDir = Split-Path -Resolve "$($MyInvocation.MyCommand.Path)\.."
$srcFile = $MyInvocation.MyCommand.Path `
        -replace 'psrvm\\test\\(.*)\.Tests\.ps1', `
                 'psrvm\src\$1.ps1'
. $srcFile

# Helper functions
function Mock64BitArch {
    Mock -Verifiable `
         -CommandName Test-Path `
         -ParameterFilter { $Path -eq "$env:systemroot\syswow64" } `
         -MockWith { $true }
}
function Mock32BitArch {
    Mock -Verifiable `
         -CommandName Test-Path `
         -ParameterFilter { $Path -eq "$env:systemroot\syswow64" } `
         -MockWith { $false }
}
function UndoMockArch {
    # Undo the mock by making the mock return the actual result.
    Mock Test-Path -ParameterFilter {$Path -eq "$env:systemroot\syswow64"} `
                   -MockWith { Test-Path "$env:systemroot\syswow64" }
}

# Tests
Describe 'PsRvm.Core' {
    It 'should provide the Install-Ruby command' {
        Get-Command Install-Ruby | Should Not BeNullOrEmpty
    }
    It 'should install to a default path if one is not specified' {
        Install-Ruby | Should Be "$env:userprofile\.psrvm"
    }

    Context '_get_native_arch' {
        AfterEach {
            UndoMockArch
        }
        It 'returns i386 on a 32-bit system' {
            Mock32BitArch
            # I should really be asserting that these mocks are called, but
            # it isn't working and I can't figure out why.
            _get_native_arch | Should Be 'i386'
        }
        It 'returns x64 on a 64-bit system' {
            Mock64BitArch
            _get_native_arch | Should Be 'x64'
        }
    }
}
