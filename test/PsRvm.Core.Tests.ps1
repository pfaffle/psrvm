$TEST_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$TEST_DIR\TestHelper.ps1"
. $SRC_FILE

# Tests
Describe 'PsRvm.Core' {
    It 'should provide the Install-Ruby command' {
        Get-Command Install-Ruby | Should Not BeNullOrEmpty
    }
    It 'should install to a default path if one is not specified' {
        Install-Ruby | Should Be "$env:userprofile\.psrvm"
    }
}

Describe '_get_native_arch' {
    AfterEach {
        UndoMockArch
        Assert-VerifiableMocks
    }
    It 'returns i386 on a 32-bit system' {
        Mock32BitArch
        _get_native_arch | Should Be 'i386'
        Assert-VerifiableMocks
    }
    It 'returns x64 on a 64-bit system' {
        Mock64BitArch
        _get_native_arch | Should Be 'x64'
        Assert-VerifiableMocks
    }
}

Describe '_get_web_client' {
    It 'returns a new System.Net.WebClient object' {
        (_get_web_client).GetType().FullName | Should Be 'System.Net.WebClient'
    }
}

Describe '_get_available_ruby_versions' {
    Context 'With Ruby installers for 1.9.2-p0, 1.9.2-p290, 1.9.3-p551, and 2.2.3' {
        Mock _get_web_client -MockWith {GetMockWebClient} -Verifiable

        It 'returns all available versions' {
            _get_available_ruby_versions | HasValues @('1.9.2-p0', '1.9.2-p290', '1.9.3-p551', '2.2.3') | Should Be $true
            Assert-VerifiableMocks
        }
    }
}

Describe '_get_latest_ruby_version' {
    Context 'With Ruby installers for 1.9.2-p0, 1.9.2-p290, 1.9.3-p551, and 2.2.3' {
        Mock _get_web_client -MockWith {GetMockWebClient} -Verifiable

        It 'returns 2.2.3' {
            _get_latest_ruby_version | Should Be '2.2.3'
            Assert-VerifiableMocks
        }
    }
}
