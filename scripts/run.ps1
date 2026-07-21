param(
    [switch]$Editor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$godot = Get-GodotExecutable
$null = Assert-GodotVersion -Executable $godot
$arguments = @('--path', $repoRoot)

if ($Editor) {
    $arguments += '--editor'
}

$process = Start-Process -FilePath $godot -ArgumentList $arguments -WorkingDirectory $repoRoot -PassThru
Write-Host "Started Godot process $($process.Id) for $repoRoot"
