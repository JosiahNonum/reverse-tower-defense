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

Write-Host 'Running checked diagnostic replay'
& (Join-Path $PSScriptRoot 'scenario.ps1')

Write-Host 'Running checked combat scenario suite'
& (Join-Path $PSScriptRoot 'scenario.ps1') -CombatSuite

Write-Host 'Proving incompatible replay rejection'
& (Join-Path $PSScriptRoot 'scenario.ps1') `
    -ReplayPath 'tests\fixtures\replays\incompatible_schema_replay.json' `
    -ExpectedFailureCode 'schema_mismatch'

Write-Host 'VERIFY PASS: parse, smoke, tests, combat scenarios, and replay checks succeeded'
