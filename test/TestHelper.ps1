if (Get-Module psrvm) { Remove-Module psrvm }

# Useful variables
# ==========================
$TEST_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $TEST_DIR
$SRC_FILE = $MyInvocation.ScriptName `
    -Replace 'psrvm\\test\\(.*)\.Tests\.ps1', `
             'psrvm\src\$1.ps1'

# Mock helper functions
# ==========================
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
        return Get-Content "$ROOT_DIR\res\test\rubyinstaller_list.html" | Out-String
    }
    return $MockWebClient
}
function MockWebClient {
    Mock -Verifiable `
         -CommandName _get_web_client `
         -MockWith {GetMockWebClient}
}
function UndoMockWebClient {
    Mock _get_web_client {New-Object System.Net.WebClient}
}

# Assertion helper functions
# ==========================
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

function Assert-MockNotCalled {
    param([String]$CommandName)
    Assert-MockCalled -Times 0 -CommandName $CommandName
}
