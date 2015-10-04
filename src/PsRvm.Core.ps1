$PSRVM_ROOT = "$env:userprofile\.psrvm"
<#
    .SYNOPSIS
    Install a new Ruby.
#>
function Install-Ruby {
    param(
        [CmdletBinding()]
        [String]$Path = $PSRVM_ROOT
    )
    $Path
}

function _get_native_arch {
    if (Test-Path -Path "$env:systemroot\syswow64") {
        return 'x64'
    } else {
        return 'i386'
    }
}

function _get_latest_ruby_version {
    $versions = _get_available_ruby_versions | Sort -Descending
    return $versions[0]
}

function _get_available_ruby_versions {
    $html = (_get_web_client).DownloadString('http://dl.bintray.com/oneclick/rubyinstaller/') -split "`n"
    $versions = @()
    foreach ($line in $html) {
        if ($line -match '\<pre\>\<a onclick="navi\(event\)" href="\:rubyinstaller\-(\d\.\d\.\d(\-p\d+)?)\.exe') {
            $versions += $matches[1]
        }
    }
    return $versions | Sort -Unique
}

# For testing
function _get_web_client {
    return New-Object System.Net.WebClient
}
