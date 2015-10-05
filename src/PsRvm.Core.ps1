$PSRVM_ROOT = "$env:userprofile\.psrvm"
$MIRROR_URL = 'http://dl.bintray.com/oneclick/rubyinstaller'
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
    $html = (_get_web_client).DownloadString("$MIRROR_URL/") -split "`n"
    $versions = @()
    foreach ($line in $html) {
        if ($line -match '\<pre\>\<a onclick="navi\(event\)" href="\:rubyinstaller\-(\d\.\d\.\d(\-p\d+)?)\.exe') {
            $versions += $matches[1]
        }
    }
    return $versions | Sort -Unique
}

function _get_ruby_download_url {
    param(
        $Arch = 'i386',
        $Version = (_get_latest_ruby_version)
    )
    $Url = "$MIRROR_URL/rubyinstaller-${Version}.exe"
    switch ($Arch) {
        'x64' {
            $Url = $Url -Replace '\.exe', '-x64.exe'
            break
        } 'i386' {
            break
        } default {
            throw "Invalid Arch: $Arch. Acceptable values are x64, i386"
        }
    }
    return $Url
}

# For testing
function _get_web_client {
    return New-Object System.Net.WebClient
}
