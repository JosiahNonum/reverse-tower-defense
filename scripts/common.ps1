Set-StrictMode -Version Latest

$script:ExpectedGodotVersion = '4.7.1.stable'

function Get-GodotExecutable {
    param(
        [switch]$Console
    )

    $candidates = New-Object System.Collections.Generic.List[string]

    if ($env:REV_TOWER_GODOT) {
        $candidates.Add($env:REV_TOWER_GODOT)
    }

    foreach ($commandName in @('godot', 'godot4')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command -and $command.Source) {
            $candidates.Add($command.Source)
        }
    }

    $versionedEditor = Join-Path $env:LOCALAPPDATA 'Programs\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe'
    $candidates.Add($versionedEditor)

    foreach ($candidate in $candidates) {
        $expandedCandidate = [Environment]::ExpandEnvironmentVariables($candidate)

        if ($Console -and $expandedCandidate.EndsWith('.exe', [StringComparison]::OrdinalIgnoreCase)) {
            $consoleCandidate = $expandedCandidate.Substring(0, $expandedCandidate.Length - 4) + '_console.exe'
            if (Test-Path -LiteralPath $consoleCandidate -PathType Leaf) {
                return (Resolve-Path -LiteralPath $consoleCandidate).Path
            }
        }

        if (Test-Path -LiteralPath $expandedCandidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $expandedCandidate).Path
        }
    }

    throw 'Godot 4.7.1 was not found. Run .\scripts\doctor.ps1 for the expected setup.'
}

function Get-GodotVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable
    )

    $versionExecutable = $Executable
    if (-not $versionExecutable.EndsWith('_console.exe', [StringComparison]::OrdinalIgnoreCase)) {
        $consoleCandidate = $versionExecutable.Substring(0, $versionExecutable.Length - 4) + '_console.exe'
        if (Test-Path -LiteralPath $consoleCandidate -PathType Leaf) {
            $versionExecutable = $consoleCandidate
        }
    }

    $versionOutput = (& $versionExecutable --version 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $versionOutput) {
        throw "Godot version check failed for $versionExecutable"
    }

    return $versionOutput
}

function Assert-GodotVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable
    )

    $versionOutput = Get-GodotVersion -Executable $Executable
    if (-not $versionOutput.StartsWith($script:ExpectedGodotVersion, [StringComparison]::Ordinal)) {
        throw "Expected Godot $script:ExpectedGodotVersion but found $versionOutput at $Executable"
    }

    return $versionOutput
}
