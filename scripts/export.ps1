Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$godot = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $godot
$outputDirectory = Join-Path $repoRoot 'build\windows'
$outputPath = Join-Path $outputDirectory 'reverse-tower-defense.exe'

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

Write-Host "Exporting Windows Desktop with Godot $version"
& $godot --headless --path $repoRoot --export-release 'Windows Desktop' $outputPath
if ($LASTEXITCODE -ne 0) {
    throw "Godot export failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "Godot reported success but the export is missing: $outputPath"
}

Write-Host "EXPORT PASS: $outputPath"
