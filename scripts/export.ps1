param(
    [switch]$SkipLaunchCheck,
    [string]$Version = 'v0.1.0',
    [switch]$Debug
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$godot = Get-GodotExecutable -Console
$godotVersion = Assert-GodotVersion -Executable $godot
$artifactVersion = $Version
if ($Debug) {
    $artifactVersion = "$Version-debug"
}
$outputDirectory = Join-Path $repoRoot (Join-Path 'build\windows' $artifactVersion)
$outputPath = Join-Path $outputDirectory 'reverse-tower-defense.exe'
$packagePath = Join-Path $outputDirectory 'reverse-tower-defense.pck'

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$exportMode = '--export-release'
if ($Debug) {
    $exportMode = '--export-debug'
}
Write-Host "Exporting Windows Desktop $artifactVersion with Godot $godotVersion"
& $godot --headless --path $repoRoot $exportMode 'Windows Desktop' $outputPath
if ($LASTEXITCODE -ne 0) {
    throw "Godot export failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "Godot reported success but the export is missing: $outputPath"
}

if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf)) {
    throw "Godot reported success but the export package is missing: $packagePath"
}

if (-not $SkipLaunchCheck) {
    Write-Host 'Launching exported build for a bounded headless smoke check'
    $launch = Start-Process `
        -FilePath $outputPath `
        -ArgumentList @('--headless', '--quit-after', '2') `
        -WorkingDirectory $outputDirectory `
        -WindowStyle Hidden `
        -Wait `
        -PassThru
    if ($launch.ExitCode -ne 0) {
        throw "Exported build launch failed with exit code $($launch.ExitCode)"
    }
    Write-Host 'EXPORT LAUNCH PASS: generated Windows build started and exited cleanly'
}

$executableHash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
$packageHash = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash
Write-Host "EXPORT PASS: $outputPath"
Write-Host "EXPORT SHA256: exe=$executableHash pck=$packageHash"
