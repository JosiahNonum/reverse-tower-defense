param(
    [string]$OutputDirectory = 'res://build/visual_checks/m3_1',
    [switch]$Authoring
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$godot = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $godot
$arguments = @(
    '--path', $repoRoot,
    '--script', 'res://tests/visual/defense_inspection_capture.gd',
    '--',
    '--output-dir', $OutputDirectory
)
if ($Authoring) {
    $arguments += '--authoring'
}

Write-Host "Capturing defense inspection checks with Godot $version"
& $godot @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Defense inspection visual capture failed with exit code $LASTEXITCODE"
}
