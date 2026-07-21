Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$editor = Get-GodotExecutable
$console = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $console
$templateDirectory = Join-Path $env:APPDATA 'Godot\export_templates\4.7.1.stable'
$debugTemplate = Join-Path $templateDirectory 'windows_debug_x86_64.exe'
$releaseTemplate = Join-Path $templateDirectory 'windows_release_x86_64.exe'

if (-not (Test-Path -LiteralPath $debugTemplate -PathType Leaf)) {
    throw "Missing Windows debug export template: $debugTemplate"
}

if (-not (Test-Path -LiteralPath $releaseTemplate -PathType Leaf)) {
    throw "Missing Windows release export template: $releaseTemplate"
}

[pscustomobject]@{
    Repository = $repoRoot
    GodotVersion = $version
    Editor = $editor
    Console = $console
    ExportTemplates = $templateDirectory
    WindowsDebugTemplate = 'Present'
    WindowsReleaseTemplate = 'Present'
} | Format-List
