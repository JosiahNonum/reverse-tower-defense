param(
    [string]$Filter = '',
    [string]$TestPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$godot = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $godot
$runnerArguments = @(
    '--headless',
    '--path', $repoRoot,
    '--script', 'res://tests/test_runner.gd',
    '--'
)

if ($Filter) {
    $runnerArguments += @('--filter', $Filter)
}

if ($TestPath) {
    $runnerArguments += @('--test-path', $TestPath)
}

Write-Host "Running project tests with Godot $version"
& $godot @runnerArguments
if ($LASTEXITCODE -ne 0) {
    throw "Godot project tests failed with exit code $LASTEXITCODE"
}
