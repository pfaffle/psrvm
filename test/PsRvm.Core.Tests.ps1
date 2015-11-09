$TEST_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$TEST_DIR\TestHelper.ps1"
. $SRC_FILE

# Tests
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

    Context "when attempting to download to a directory that doesn't exist" {
        It 'creates the directory and downloads the installer to it' {
            _download_ruby -Path "TestDrive:\newdir" -Version 2.2.3
            Test-Path "TestDrive:\newdir\rubyinstaller-2.2.3.exe" | Should Be $true
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

        It 'does not throw if passed i386' {
            {_verify_compatible_arch 'i386'} | Should Not Throw
            Assert-VerifiableMocks
        }
        It 'does not throw if passed x64' {
            {_verify_compatible_arch 'x64'} | Should Not Throw
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

        It 'does not throw if passed i386' {
            {_verify_compatible_arch 'i386'} | Should Not Throw
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
            ($ArgumentList -contains "/dir=`"TestDrive:\psrvm`"")
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

Describe '_ensure_directory_exists' {
    It 'does not throw if the directory exists' {
        {_ensure_directory_exists 'TestDrive:\'} | Should Not Throw
    }
    It 'does not throw if the directory does not exist and it creates it' {
        {_ensure_directory_exists 'TestDrive:\newdir'} | Should Not Throw
    }
    It 'throws if the directory does not exist and it is unable to create it' {
        Mock -Verifiable `
            -CommandName Test-Path `
            -ParameterFilter {$Path -eq 'TestDrive:\newdir'} `
            -MockWith { $false }
        {_ensure_directory_exists 'TestDrive:\newdir'} | Should Throw
        Assert-VerifiableMocks
    }
}

Describe 'Install-Ruby' {
    BeforeEach {
        Mock -Verifiable -CommandName _get_psrvm_root -MockWith {'TestDrive:\user\psrvm'}
        mkdir 'TestDrive:\user'
        Mock -Verifiable -CommandName _get_temp_dir -MockWith {'TestDrive:\temp'}
        mkdir 'TestDrive:\temp'
        MockWebClient
        Mock -Verifiable `
         -CommandName _run_ruby_installer `
         -MockWith { mkdir 'TestDrive:\user\psrvm\ruby2.2.3' } `
         -ParameterFilter {
            ($Installer -eq 'TestDrive:\temp\rubyinstaller-2.2.3.exe') -and
            ($TargetDir -eq 'TestDrive:\user\psrvm\ruby2.2.3')
        }
        Install-Ruby -Version 2.2.3
    }
    AfterEach {
        Assert-VerifiableMocks
        rmdir -Recurse -Force 'TestDrive:\user'
        rmdir -Recurse -Force 'TestDrive:\temp'
        UndoMockWebClient
    }

    It 'should install 32-bit Ruby 2.2.3 to the psrvm root directory by default' {
        Test-Path "TestDrive:\user\psrvm\ruby2.2.3" | Should Be True
    }
    It 'should add the Ruby installation to the psrvm.xml file' {
        $Ruby = Import-Clixml 'TestDrive:\user\psrvm\psrvm.xml'
        $Ruby.Version | Should Be 2.2.3
    }
}

Describe '_new_ruby_object' {
    BeforeEach {
        $Ruby = _new_ruby_object -Version 2.2.3 -Arch i386 -Path 'TestDrive:\user\psrvm\ruby2.2.3'
    }
    AfterEach {
        $Ruby = $null
    }

    It 'should have a version property' {
        $Ruby.Version | Should Be 2.2.3
    }
    It 'should have an arch property' {
        $Ruby.Arch | Should Be i386
    }
    It 'should have a path property' {
        $Ruby.Path | Should Be 'TestDrive:\user\psrvm\ruby2.2.3'
    }
    It 'should calculate the uninstaller property' {
        $Ruby.Uninstaller | Should Be 'TestDrive:\user\psrvm\ruby2.2.3\unins000.exe'
    }
}

Describe 'Add-Ruby' {
    BeforeEach {
        Mock -Verifiable -CommandName _get_psrvm_root -MockWith {'TestDrive:\user\psrvm'}
        mkdir 'TestDrive:\user\psrvm'
    }
    AfterEach {
        Assert-VerifiableMocks
        del -Recurse -Force 'TestDrive:\user\psrvm'
    }

    Context 'adding one Ruby installation with no existing installation' {
        BeforeEach {
            copy "$ROOT_DIR\res\test\psrvm_no_ruby.xml" 'TestDrive:\user\psrvm\psrvm.xml'
            Add-Ruby -Version 2.2.3 -Arch i386 -Path 'TestDrive:\user\psrvm\ruby2.2.3'
            $InstalledRuby = Import-Clixml 'TestDrive:\user\psrvm\psrvm.xml'
        }
        AfterEach {
            $InstalledRuby = $null
        }

        It 'retains the version' {
            $InstalledRuby.Version | Should Be 2.2.3
        }
        It 'retains the arch' {
            $InstalledRuby.Arch| Should Be i386
        }
        It 'retains the path' {
            $InstalledRuby.Path | Should Be 'TestDrive:\user\psrvm\ruby2.2.3'
        }
        It 'retains the uninstaller path' {
            $InstalledRuby.Uninstaller | Should Be 'TestDrive:\user\psrvm\ruby2.2.3\unins000.exe'
        }
    }

    Context 'adding a Ruby installation with an existing installation' {
        BeforeEach {
            copy "$ROOT_DIR\res\test\psrvm_one_ruby.xml" 'TestDrive:\user\psrvm\psrvm.xml'
            Add-Ruby -Version 1.9.3-p551 -Arch i386 -Path 'TestDrive:\user\psrvm\ruby1.9.3-p551'
            $InstalledRubies = @(Import-Clixml 'TestDrive:\user\psrvm\psrvm.xml')
            $InstalledRubies.Length | Should Be 2
        }
        AfterEach {
            $InstalledRubies = $null
        }

        It 'should have a version for both Ruby installations' {
            $InstalledRubies | Select -Expand Version |
                HasValues @('1.9.3-p551','2.2.3') | Should Be $true
        }
        It 'should have an arch for both Ruby installations' {
            $InstalledRubies | Select -Expand Arch |
                HasValues @('i386','i386') | Should Be $true
        }
        It 'should have a path for both Ruby installations' {
            $InstalledRubies | Select -Expand Path |
                HasValues @(
                    'TestDrive:\user\psrvm\ruby1.9.3-p551',
                    'TestDrive:\user\psrvm\ruby2.2.3') | Should Be $true
        }
        It 'should have an uninstaller path for both Ruby installations' {
            $InstalledRubies | Select -Expand Uninstaller |
                HasValues @(
                    'TestDrive:\user\psrvm\ruby1.9.3-p551\unins000.exe',
                    'TestDrive:\user\psrvm\ruby2.2.3\unins000.exe') | Should Be $true
        }
    }

    Context 'adding one Ruby installation with no config file' {
        BeforeEach {
            $InstalledRubies = @(Get-Ruby)
            $InstalledRubies.Length | Should Be 0
        }
        AfterEach {
            $InstalledRubies = $null
        }

        It 'returns nothing' {
            $InstalledRubies | Should BeNullOrEmpty
        }
    }
}

Describe 'Get-Ruby' {
    BeforeEach {
        Mock -Verifiable -CommandName _get_psrvm_root -MockWith {'TestDrive:\user\psrvm'}
        mkdir 'TestDrive:\user\psrvm'
    }
    AfterEach {
        Assert-VerifiableMocks
        del -Recurse -Force 'TestDrive:\user\psrvm'
    }

    Context 'with one Ruby installation' {
        BeforeEach {
            copy "$ROOT_DIR\res\test\psrvm_one_ruby.xml" 'TestDrive:\user\psrvm\psrvm.xml'
            $InstalledRuby = @(Get-Ruby)
            $InstalledRuby.Length | Should Be 1
        }
        AfterEach {
            $InstalledRuby = $null
        }

        It 'has a version' {
            $InstalledRuby.Version | Should Be 2.2.3
        }
        It 'has an arch' {
            $InstalledRuby.Arch| Should Be i386
        }
        It 'has a path' {
            $InstalledRuby.Path | Should Be 'TestDrive:\user\psrvm\ruby2.2.3'
        }
        It 'has an uninstaller path' {
            $InstalledRuby.Uninstaller | Should Be 'TestDrive:\user\psrvm\ruby2.2.3\unins000.exe'
        }
    }

    Context 'with multiple Ruby installations' {
        BeforeEach {
            copy "$ROOT_DIR\res\test\psrvm_multiple_ruby.xml" 'TestDrive:\user\psrvm\psrvm.xml'
            $InstalledRubies = @(Get-Ruby)
            $InstalledRubies.Length | Should Be 2
        }
        AfterEach {
            $InstalledRubies = $null
        }

        It 'has a version for each object' {
            foreach ($InstalledRuby in $InstalledRubies) {
                $InstalledRuby.Version | Should Not BeNullOrEmpty
            }
        }
        It 'has an arch for each object' {
            foreach ($InstalledRuby in $InstalledRubies) {
                $InstalledRuby.Arch | Should Not BeNullOrEmpty
            }
        }
        It 'has a path for each object' {
            foreach ($InstalledRuby in $InstalledRubies) {
                $InstalledRuby.Path | Should Not BeNullOrEmpty
            }
        }
        It 'has an uninstaller path for each object' {
            foreach ($InstalledRuby in $InstalledRubies) {
                $InstalledRuby.Uninstaller | Should Not BeNullOrEmpty
            }
        }
    }

    Context 'with no Ruby installations' {
        BeforeEach {
            copy "$ROOT_DIR\res\test\psrvm_no_ruby.xml" 'TestDrive:\user\psrvm\psrvm.xml'
            $InstalledRubies = @(Get-Ruby)
            $InstalledRubies.Length | Should Be 0
        }
        AfterEach {
            $InstalledRubies = $null
        }

        It 'returns nothing' {
            $InstalledRubies | Should BeNullOrEmpty
        }
    }

    Context 'with no config file' {
        BeforeEach {
            $InstalledRubies = @(Get-Ruby)
            $InstalledRubies.Length | Should Be 0
        }
        AfterEach {
            $InstalledRubies = $null
        }

        It 'returns nothing' {
            $InstalledRubies | Should BeNullOrEmpty
        }
    }
}

Describe 'Uninstall-Ruby' {
    BeforeEach {
        Mock -Verifiable -CommandName _get_psrvm_root -MockWith {'TestDrive:\user\psrvm'}
        mkdir 'TestDrive:\user\psrvm'
    }
    AfterEach {
        Assert-VerifiableMocks
        del -Recurse -Force 'TestDrive:\user\psrvm'
    }

    Context 'with no config file' {
        It 'throws an exception when trying to remove a Ruby installation' {
            {Uninstall-Ruby -Version 2.2.3} | Should Throw
        }
    }

    Context 'with a single Ruby 2.2.3 installation' {
        BeforeEach {
            copy "$ROOT_DIR\res\test\psrvm_one_ruby.xml" 'TestDrive:\user\psrvm\psrvm.xml'
        }
        AfterEach {
            del 'TestDrive:\user\psrvm\psrvm.xml'
        }

        It 'throws an exception when trying to remove a nonexistent installation' {
            {Uninstall-Ruby -Version 1.9.3-p551} | Should Throw
        }

        It 'runs the uninstaller for an installed Ruby' {
            MockRuby223Uninstaller
            Uninstall-Ruby -Version 2.2.3
            Assert-VerifiableMocks
        }

        It 'removes the Ruby installation from the config file' {
            MockRuby223Uninstaller
            Uninstall-Ruby -Version 2.2.3
            Get-Ruby | Select -Expand Version | DoesNotHaveValues @('2.2.3') | Should Be $true
        }

        It 'leaves no Rubies installed' {
            MockRuby223Uninstaller
            Uninstall-Ruby -Version 2.2.3
            Get-Ruby | Should BeNullOrEmpty
        }
    }

    Context 'with several Rubies' {
        BeforeEach {
            copy "$ROOT_DIR\res\test\psrvm_multiple_ruby.xml" 'TestDrive:\user\psrvm\psrvm.xml'
        }
        AfterEach {
            del 'TestDrive:\user\psrvm\psrvm.xml'
        }

        It 'throws an exception when trying to remove a nonexistent installation' {
            {Uninstall-Ruby -Version 1.9.2} | Should Throw
        }

        It 'runs the uninstaller for an installed Ruby' {
            MockRuby223Uninstaller
            Uninstall-Ruby -Version 2.2.3
            Assert-VerifiableMocks
        }
        It 'removes the Ruby installation from the config file' {
            MockRuby223Uninstaller
            Uninstall-Ruby -Version 2.2.3
            Get-Ruby | Select -Expand Version | DoesNotHaveValues @('2.2.3') | Should Be $true
        }
        It 'leaves other installed Rubies alone' {
            MockRuby223Uninstaller
            Uninstall-Ruby -Version 2.2.3
            Get-Ruby | Select -Expand Version | HasValues @('1.9.3-p551') | Should Be $true
        }
    }
}
