param(
    [switch]$SkipRender
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$godot = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $godot
$operatingSystem = Get-CimInstance Win32_OperatingSystem
$processor = Get-CimInstance Win32_Processor | Select-Object -First 1
$videoController = Get-CimInstance Win32_VideoController |
    Sort-Object -Property AdapterRAM -Descending |
    Select-Object -First 1
$memoryGiB = [Math]::Round($operatingSystem.TotalVisibleMemorySize / 1MB, 1)

Write-Host "BENCHMARK MACHINE: os=$($operatingSystem.Caption) cpu=$($processor.Name) ram_gib=$memoryGiB gpu=$($videoController.Name)"
Write-Host "Running headless fixed-defense benchmark with Godot $version"
& $godot `
    --headless `
    --path $repoRoot `
    --script 'res://scripts/simulation_benchmark_cli.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Simulation benchmark failed with exit code $LASTEXITCODE"
}

if ($SkipRender) {
    Write-Host 'BENCHMARK PASS: headless simulation passed; rendered measurement skipped'
    return
}

Write-Host 'Running rendered 1280x720 presentation-proxy benchmark'
& $godot `
    --path $repoRoot `
    --script 'res://scripts/render_benchmark_cli.gd'
if ($LASTEXITCODE -ne 0) {
    throw "Render benchmark failed with exit code $LASTEXITCODE"
}

Write-Host 'BENCHMARK PASS: headless simulation and rendered presentation proxy passed'
