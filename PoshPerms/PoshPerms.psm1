<#
This file shouldn't be modifed.

It's purpose is to dot source all .ps1 files in both Public and Private. The actual exported
commands are calculated and populated in the manifest file.
#>

Get-ChildItem -Path $PSScriptRoot\Private -Filter *.ps1 -File -Recurse -ErrorAction SilentlyContinue |
ForEach-Object {
    . $_.FullName
}

Get-ChildItem -Path $PSScriptRoot\Public -Filter *.ps1 -File -Recurse -ErrorAction SilentlyContinue |
ForEach-Object {
    . $_.FullName
}
