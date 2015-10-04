﻿$TEST_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
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

Describe '_get_web_client' {
    It 'returns a new System.Net.WebClient object' {
        (_get_web_client).GetType().FullName | Should Be 'System.Net.WebClient'
    }
}

Describe '_get_available_ruby_versions' {
    Context 'With Ruby installers for 1.9.2-p0, 1.9.2-p290, 1.9.3-p551, and 2.2.3' {
        Mock _get_web_client -MockWith {GetMockWebClient}

        It 'returns all available versions' {
            _get_available_ruby_versions | HasValues @('1.9.2-p0', '1.9.2-p290', '1.9.3-p551', '2.2.3') | Should Be $true
        }
    }
}

Describe '_get_latest_ruby' {
    Context 'With Ruby installers for 1.9.2-p0, 1.9.2-p290, 1.9.3-p551, and 2.2.3' {
        Mock _get_web_client -MockWith {GetMockWebClient}

        It 'returns 2.2.3' {
            _get_latest_ruby | Should Be '2.2.3'
        }
    }
}
