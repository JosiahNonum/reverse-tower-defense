param(
    [string]$ReplayPath = 'tests\fixtures\replays\foundation_phase_replay.json',
    [string]$ExpectedFailureCode = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$candidatePath = $ReplayPath
if (-not [IO.Path]::IsPathRooted($candidatePath)) {
    $candidatePath = Join-Path $repoRoot $candidatePath
}

$resolvedReplay = (Resolve-Path -LiteralPath $candidatePath).Path
$repositoryPrefix = $repoRoot.TrimEnd('\') + '\'
if (-not $resolvedReplay.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Replay artifacts must be inside the repository.'
}

$resourcePath = 'res://' + $resolvedReplay.Substring($repositoryPrefix.Length).Replace('\', '/')
$godot = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $godot
$arguments = @(
    '--headless',
    '--path', $repoRoot,
    '--script', 'res://scripts/diagnostic_replay_cli.gd',
    '--',
    '--replay', $resourcePath
)

if ($ExpectedFailureCode) {
    $arguments += @('--expect-failure-code', $ExpectedFailureCode)
}

Write-Host "Running diagnostic replay with Godot $version"
& $godot @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Diagnostic replay failed with exit code $LASTEXITCODE"
}
