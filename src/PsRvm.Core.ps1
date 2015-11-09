$MIRROR_URL = 'http://dl.bintray.com/oneclick/rubyinstaller'
<#
    .SYNOPSIS
    Install a new Ruby.
#>
function Install-Ruby {
    param(
        [CmdletBinding()]
        [String]$Version,
        [String]$Path = $(Join-Path (_get_psrvm_root) "ruby$Version")
    )
    $AvailableVersions = _get_available_ruby_versions
    if ($AvailableVersions -notcontains $Version) {
        throw "Unable to find installer for Ruby version $Version"
    } else {
        Write-Output "Installing Ruby $Version..."
        _download_ruby -Path (_get_temp_dir) -Version $Version
        _run_ruby_installer `
            -Installer (Join-Path (_get_temp_dir) "rubyinstaller-$Version.exe") `
            -TargetDir $Path
        Add-Ruby -Version $Version -Arch i386 -Path $Path
        Write-Output "Ruby $Version was successfully installed."
    }
}

<#
    .SYNOPSIS
    Start keeping track of an installed Ruby.
#>
function Add-Ruby {
    param(
        [Parameter(Mandatory=$true)][String]$Version,
        [Parameter(Mandatory=$true)][String]$Arch,
        [Parameter(Mandatory=$true)][String]$Path,
        [String]$Uninstaller
    )
    _ensure_directory_exists (_get_psrvm_root)
    $Rubies = @(Get-Ruby)
    $Rubies += (_new_ruby_object -Version $Version -Arch $Arch -Path $Path -Uninstaller $Uninstaller)
    $Rubies | Export-Clixml -Force -Path (_get_config_path)
}

<#
    .SYNOPSIS
    Show the currently installed managed Rubies.
#>
function Get-Ruby {
    $Rubies = @()
    if (Test-Path (_get_config_path)) {
        $Rubies = @(Import-Clixml (_get_config_path) | Where-Object { $_ -ne $null })
    }
    return @($Rubies)
}

<#
    .SYNOPSIS
    Uninstall managed Rubies.
#>
function Uninstall-Ruby {
    param(
        $Version
    )
    $Rubies = @(Get-Ruby)
    if ($Rubies.Count -eq 0) {
        throw "There are no managed Ruby installations to uninstall!"
    }
    $RubiesToRemove = @()
    $RubiesRemaining = @()
    foreach ($Ruby in $Rubies) {
        if ($Ruby.Version -eq $Version) {
            $RubiesToRemove += $Ruby
        } else {
            $RubiesRemaining += $Ruby
        }
    }
    if ($RubiesToRemove.Count -eq 0) {
        throw "No Ruby installation that meets the specified criteria was found."
    }
    Write-Output "Uninstalling Ruby $Version..."
    foreach ($RubyToRemove in $RubiesToRemove) {
        _run_ruby_uninstaller ($RubyToRemove.Uninstaller)
    }
    $RubiesRemaining | Export-Clixml -Force -Path (_get_config_path)
    Write-Output "Ruby $Version was successfully uninstalled."
}

function _new_ruby_object {
    param(
        [Parameter(Mandatory=$true)][String]$Version,
        [Parameter(Mandatory=$true)][String]$Arch,
        [Parameter(Mandatory=$true)][String]$Path,
        [String]$Uninstaller
    )
    $Ruby = New-Object PSCustomObject
    $Ruby | Add-Member -Name Version -Type NoteProperty -Value $Version
    $Ruby | Add-Member -Name Arch -Type NoteProperty -Value $Arch
    $Ruby | Add-Member -Name Path -Type NoteProperty -Value $Path
    if ($Uninstaller -eq '') {
        $Uninstaller = "$Path\unins000.exe"
    }
    $Ruby | Add-Member -Name Uninstaller -Type NoteProperty -Value $Uninstaller
    return $Ruby
}

function _get_native_arch {
    if (Test-Path -Path "$env:systemroot\syswow64") {
        return 'x64'
    } else {
        return 'i386'
    }
}

function _verify_compatible_arch {
    param([String]$RubyArch)
    if (((_get_native_arch) -eq 'i386') -and ($RubyArch -eq 'x64')) {
        throw "Cannot install 64-bit Ruby on a 32-bit system!"
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

function _download_ruby {
    param(
        [Parameter(Mandatory=$true)][String]$Path,
        [Parameter(Mandatory=$true)][String]$Version,
        [String]$Arch = 'i386'
    )
    $InstallerUrl = _get_ruby_download_url -Arch $Arch -Version $Version
    $LocalInstaller = Join-Path $Path $(Split-Path -Leaf $InstallerUrl)
    _ensure_directory_exists $Path
    (_get_web_client).DownloadFile($InstallerUrl, $LocalInstaller)
}

function _run_ruby_installer {
    param(
        [String]$Installer,
        [String]$TargetDir
    )
    Start-Process `
        -Wait `
        -FilePath $Installer `
        -ArgumentList @('/verysilent',
                        '/tasks=addtk',
                        "/dir=`"$TargetDir`"")
}

function _run_ruby_uninstaller {
    param(
        [String]$Uninstaller
    )
    $Proc = Start-Process -Wait -FilePath $Uninstaller -ArgumentList @('/verysilent') -PassThru
    if ($Proc.ExitCode -ne 0) { throw "Ruby uninstall failed!" }
}

function _ensure_directory_exists {
    param([String]$Path)
    if (-not (Test-Path $Path)) {
        mkdir -Force -Path $Path
        if (-not (Test-Path $Path)) {
            throw "Unable to create directory $Path"
        }
    }
}

function _get_config_path {
    return (Join-Path (_get_psrvm_root) 'psrvm.xml')
}


# For testing
function _get_web_client {
    return New-Object System.Net.WebClient
}
function _get_psrvm_root {
    return Join-Path $env:userprofile 'psrvm'
}
function _get_temp_dir {
    return Join-Path $env:temp 'psrvm'
}
