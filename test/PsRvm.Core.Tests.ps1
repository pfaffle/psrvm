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
function GetMockWebClient {
    $MockWebClient = New-Object PSCustomObject
    $MockWebClient | Add-Member -MemberType ScriptMethod -Name DownloadString -Value {
        param([string]$address)
        return Get-Content "$rootDir\res\test\rubyinstaller_list.html" | Out-String
    }
    return $MockWebClient
}
function HasValues {
    param(
    [CmdletBinding()]
    [String[]]$ExpectedValues,
    [Parameter(ValueFromPipeline=$true)]
    [String]$Actual
    )
    PROCESS {
        $ActualValues += @($Actual)
    }
    END {
        foreach ($Expected in $ExpectedValues) {
            if ($ActualValues -notcontains $Expected) {
                Write-Error "{$Expected} expected but was not encountered.`nActual: {$ActualValues}"
                return $false
            }
        }
        return $true
    }
}

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
