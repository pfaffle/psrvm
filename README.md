# PsRvm
A Ruby version manager written in PowerShell.

Written by Craig Meinschein (pfaffle).

## Usage
PsRvm provides the following commands for installing Ruby and getting information
about Ruby installations [that it knows about] on your system.

### Install-Ruby
Download a Ruby installer for a particular version/system architecture from the
internet and silently install it on your machine. The default behavior places it
in `$env:userprofile\psrvm\ruby$version` directory, but this can be overridden by
explicitly setting the `Path` parameter.

A minimal example:
```powershell
Install-Ruby 2.2.3
```
A complete example:
```powershell
Install-Ruby -Version 2.2.3 -Path 'C:\ruby2.2.3'
```

### Add-Ruby
Add a Ruby installation to PsRvm's config file so that it "knows" about it and
can manage it. Note that this is automatically done for Rubies that have been
installed by `Install-Ruby`. You can use `Add-Ruby` to let PsRvm manage Rubies
that have been installed through other means.

```powershell
Add-Ruby -Version 2.2.3 -Path 'C:\ruby2.2.3' -Arch i386
```

### Get-Ruby
List Ruby installations in PsRvm's config file.

## Tests
Unit tests are written using Pester (https://github.com/pester/Pester). To run
them, install the Pester PowerShell module, load it into your current
PowerShell session, then run `Invoke-Pester` in the psrvm root directory.
