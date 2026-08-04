Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$godot = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $godot

Write-Host "Running deterministic balance matrix with Godot $version"
& $godot --headless --path $repoRoot --script 'res://scripts/balance_matrix_cli.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Balance matrix failed with exit code $LASTEXITCODE"
}
