<#
---
Name: Source module template
Version: 0.4
Modified: 2024-01-31 18:30:20
---
#>

$modulePath = $PSCommandPath
$moduleName = Split-Path $modulePath -Leaf

Write-Verbose "Loading $moduleName from $modulePath"

$sourceDirectories = @(
    'classes'
    'enum',
    'private',
    'public'
)

$importOptions = @{
    Path        = $PSScriptRoot
    Filter      = '*.ps1'
    Recurse     = $true
    ErrorAction = 'Stop'
}

$prefixFile = (Join-Path $PSScriptRoot 'prefix.ps1')
$suffixFile = (Join-Path $PSScriptRoot 'suffix.ps1')

if (Test-Path $prefixFile) {
    Write-Verbose "Loading Prefix file $prefixFile"
    . $prefixFile
}

if (Test-Path "$PSScriptRoot\LoadOrder.txt") {
    Write-Verbose 'Using custom load order'
    $custom = Get-Content "$PSScriptRoot\LoadOrder.txt"
    Get-ChildItem @importOptions -Recurse | ForEach-Object {
        $rel = $_.FullName -replace [regex]::Escape("$PSScriptRoot\") , ''
        if ($rel -notin $custom) {
            Write-Warning "$rel is not listed in custom"
        }
    }
    try {
        Get-Content "$PSScriptRoot\LoadOrder.txt" | ForEach-Object {
            switch -Regex ($_) {
                '^\s*$' {
                    # blank line, skip
                    continue
                }
                '^\s*#$' {
                    # Comment line, skip
                    continue
                }
                '^.*\.ps1' {
                    # load these
                    Write-Verbose "- Loading $_"
                    . "$PSScriptRoot\$_"
                    continue
                }
                default {
                    #unrecognized, skip
                    continue
                }
            }
        }
    } catch {
        Write-Error "Custom load order $_"
    }
} else {
    try {
        foreach ($dir in $sourceDirectories) {
            $importOptions.Path = (Join-Path $PSScriptRoot $dir)

            Get-ChildItem @importOptions | ForEach-Object {
                $currentFile = $_.FullName
                Write-Verbose "- Loading $($_.Name)"
                . $currentFile
            }
        }
    } catch {
        throw "An error occured during the dot-sourcing of module .ps1 file '$currentFile':`n$_"
    }
}

if (Test-Path $suffixFile) {
    Write-Verbose "Loading suffix file $suffixFile"
    . $suffixFile
}

$formatDirectory = (Join-Path $PSScriptRoot 'formats')

if (Test-Path $formatDirectory) {
    foreach ($format in (Get-ChildItem $formatDirectory -Filter "*.Format.ps1xml")) {
        Write-Verbose "Adding Formats from $($format.Name)"
        Update-FormatData -AppendPath $format.FullName -ErrorAction SilentlyContinue
    }
}
$typeDirectory = (Join-Path $PSScriptRoot 'types')

if (Test-Path $typeDirectory) {
    foreach ($type in (Get-ChildItem $typeDirectory -Filter "*.Type.ps1xml")) {
        Write-Verbose "Adding Types from $($type.Name)"
        Update-FormatData -AppendPath $type.FullName -ErrorAction SilentlyContinue
    }
}

Write-Verbose "Cleaning up variables"
Remove-Variable -Name @(
    'sourceDirectories',
    'importOptions',
    'dir',
    'prefixFile',
    'suffixFile',
    'custom',
    'rel',
    'currentFile',
    'formatDirectory',
    'format',
    'typeDirectory',
    'type'
) -ErrorAction SilentlyContinue
Write-Verbose "Done"
