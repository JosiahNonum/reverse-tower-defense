Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$godot = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $godot

Write-Host "Parsing project with Godot $version"
& $godot --headless --path $repoRoot --editor --quit
if ($LASTEXITCODE -ne 0) {
    throw "Godot project parse failed with exit code $LASTEXITCODE"
}

Write-Host 'Running project smoke test'
& $godot --headless --path $repoRoot --script 'res://tests/smoke_test.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Godot smoke test failed with exit code $LASTEXITCODE"
}

& (Join-Path $PSScriptRoot 'test.ps1')

Write-Host 'VERIFY PASS: project parse, smoke test, and project tests succeeded'
