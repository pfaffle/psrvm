$TEST_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$TEST_DIR\TestHelper.ps1"
. $SRC_FILE

# Tests
Describe 'PsRvm.Core' {
    It 'should provide the Install-Ruby command' {
        Get-Command Install-Ruby | Should Not BeNullOrEmpty
    }
}

Describe '_get_native_arch' {
    AfterEach {
        UndoMockArch
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
        It 'returns all available versions' {
            MockWebClient
            _get_available_ruby_versions | HasValues @('1.9.2-p0', '1.9.2-p290', '1.9.3-p551', '2.2.3') | Should Be $true
            Assert-VerifiableMocks
        }
    }
}

Describe '_get_latest_ruby_version' {
    Context 'With Ruby installers for 1.9.2-p0, 1.9.2-p290, 1.9.3-p551, and 2.2.3' {
        It 'returns 2.2.3' {
            MockWebClient
            _get_latest_ruby_version | Should Be '2.2.3'
            Assert-VerifiableMocks
        }
    }
}

Describe '_get_ruby_download_url' {
    BeforeEach {
        MockWebClient
    }
    AfterEach {
        UndoMockWebClient
    }

    # The cases that involve dynamically figuring out the most recent version
    # will use the webclient mock (to see what's available).
    Context 'without parameters' {
        It 'returns the url to the latest 32-bit installer' {
            _get_ruby_download_url |
                Should Be 'http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.2.3.exe'
            Assert-VerifiableMocks
        }
    }

    Context 'when requesting Ruby version 1.9.3-p551' {
        It 'returns the url to the 32-bit Ruby 1.9.3-p551 installer' {
            _get_ruby_download_url -Version '1.9.3-p551' |
                Should Be 'http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-1.9.3-p551.exe'
            Assert-MockNotCalled _get_web_client
        }
    }

    Context 'when requesting 64-bit Ruby but not a specific version' {
        It 'returns the url to the latest 64-bit installer' {
            _get_ruby_download_url -Arch x64 |
                Should Be 'http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.2.3-x64.exe'
            Assert-VerifiableMocks
        }
    }

    Context 'when requesting 64-bit Ruby version 2.2.3' {
        It 'returns the url to the the 64-bit Ruby 2.2.3 installer' {
            _get_ruby_download_url -Arch x64 -Version 2.2.3 |
                Should Be 'http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-2.2.3-x64.exe'
            Assert-MockNotCalled _get_web_client
        }
    }

    Context 'when called with an invalid arch' {
        It 'throws an exception' {
            {_get_ruby_download_url -Arch sparc -Version 2.2.3} | Should Throw
            Assert-MockNotCalled _get_web_client
        }
    }
}

Describe '_download_ruby' {
    BeforeEach {
        MockWebClient
    }
    AfterEach {
        UndoMockWebClient
    }

    Context 'when requesting 32-bit Ruby version 2.2.3' {
        It 'downloads the 32-bit installer to a temp directory' {
            _download_ruby -Path "TestDrive:\" -Version 2.2.3 -Arch i386
            Test-Path "TestDrive:\rubyinstaller-2.2.3.exe" | Should Be $true
            Assert-VerifiableMocks
        }
    }

    Context 'when requesting 64-bit Ruby version 2.2.3' {
        It 'downloads the 64-bit installer to a temp directory' {
            _download_ruby -Path "TestDrive:\" -Version 2.2.3 -Arch x64
            Test-Path "TestDrive:\rubyinstaller-2.2.3-x64.exe" | Should Be $true
            Assert-VerifiableMocks
        }
    }

    Context 'when requesting Ruby version 2.2.3' {
        It 'downloads the 32-bit installer to a temp directory' {
            _download_ruby -Path "TestDrive:\" -Version 2.2.3
            Test-Path "TestDrive:\rubyinstaller-2.2.3.exe" | Should Be $true
            Assert-VerifiableMocks
        }
    }
}

Describe '_verify_compatible_arch' {
    Context 'on a 64-bit system' {
        BeforeEach {
            Mock64BitArch
        }
        AfterEach {
            UndoMockArch
        }

        It 'returns true if passed i386' {
            _verify_compatible_arch 'i386' | Should Be $true
            Assert-VerifiableMocks
        }
        It 'returns true if passed x64' {
            _verify_compatible_arch 'x64' | Should Be $true
            Assert-VerifiableMocks
        }
    }

    Context 'on a 32-bit system' {
        BeforeEach {
            Mock32BitArch
        }
        AfterEach {
            UndoMockArch
        }

        It 'returns true if passed i386' {
            _verify_compatible_arch 'i386' | Should Be $true
            Assert-VerifiableMocks
        }
        It 'throws an exception if passed x64' {
            {_verify_compatible_arch 'x64'} | Should Throw
            Assert-VerifiableMocks
        }
    }
}

Describe '_run_ruby_installer' {
    It 'should call the installer with appropriate arguments' {
        # Mock the expected installer Start-Process call
        Mock -Verifiable `
         -CommandName Start-Process `
         -MockWith { $true } `
         -ParameterFilter {
            ($Wait -eq $true) -and
            ($FilePath -eq 'TestDrive:\rubyinstaller-2.2.3.exe') -and
            ($ArgumentList -contains '/verysilent') -and
            ($ArgumentList -contains '/tasks=addtk') -and
            ($ArgumentList -contains "/dir=`"TestDrive:\psrvm\ruby2.2.3`"")
        }
        # Call the installer
        try {
            _run_ruby_installer -Installer 'TestDrive:\rubyinstaller-2.2.3.exe' `
                                -TargetDir 'TestDrive:\psrvm'
        } catch {}
        # Assert that the mock was called, which proves 
        # that the right installer arguments were passed in.
        Assert-VerifiableMocks
    }
}
