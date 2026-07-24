param(
    [string]$ReplayPath = '',
    [string]$ExpectedFailureCode = '',
    [string]$CombatScenarioPath = '',
    [switch]$CombatSuite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')


function Resolve-RepositoryArtifact {
    param(
        [string]$RepoRoot,
        [string]$CandidatePath
    )

    if (-not [IO.Path]::IsPathRooted($CandidatePath)) {
        $CandidatePath = Join-Path $RepoRoot $CandidatePath
    }
    $resolvedPath = (Resolve-Path -LiteralPath $CandidatePath).Path
    $repositoryPrefix = $RepoRoot.TrimEnd('\') + '\'
    if (-not $resolvedPath.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Scenario artifacts must be inside the repository.'
    }
    return $resolvedPath
}


function ConvertTo-ResourcePath {
    param(
        [string]$RepoRoot,
        [string]$ResolvedPath
    )

    $repositoryPrefix = $RepoRoot.TrimEnd('\') + '\'
    return 'res://' + $ResolvedPath.Substring($repositoryPrefix.Length).Replace('\', '/')
}


function Invoke-CombatScenario {
    param(
        [string]$Godot,
        [string]$RepoRoot,
        [string]$ScenarioPath,
        [string]$GodotVersion
    )

    $resourcePath = ConvertTo-ResourcePath -RepoRoot $RepoRoot -ResolvedPath $ScenarioPath
    Write-Host "Running combat scenario $resourcePath with Godot $GodotVersion"
    & $Godot `
        --headless `
        --path $RepoRoot `
        --script 'res://scripts/combat_scenario_cli.gd' `
        -- `
        --scenario $resourcePath
    if ($LASTEXITCODE -ne 0) {
        throw "Combat scenario failed with exit code $LASTEXITCODE"
    }
}


$repoRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
if ($CombatSuite -and $CombatScenarioPath) {
    throw 'Use either -CombatSuite or -CombatScenarioPath, not both.'
}

if (($CombatSuite -or $CombatScenarioPath) -and ($ReplayPath -or $ExpectedFailureCode)) {
    throw 'Combat scenarios cannot be combined with replay options.'
}

$godot = Get-GodotExecutable -Console
$version = Assert-GodotVersion -Executable $godot

if ($CombatSuite) {
    $scenarioDirectory = Join-Path $repoRoot 'tests\fixtures\combat_scenarios'
    $scenarioPaths = Get-ChildItem -LiteralPath $scenarioDirectory -Filter '*.json' |
        Sort-Object -Property Name |
        Select-Object -ExpandProperty FullName
    if (-not $scenarioPaths) {
        throw 'No checked combat scenarios were found.'
    }
    foreach ($scenarioPath in $scenarioPaths) {
        Invoke-CombatScenario `
            -Godot $godot `
            -RepoRoot $repoRoot `
            -ScenarioPath $scenarioPath `
            -GodotVersion $version
    }
    Write-Host "COMBAT SUITE PASS: $($scenarioPaths.Count) checked scenarios matched"
    return
}

if ($CombatScenarioPath) {
    $resolvedScenario = Resolve-RepositoryArtifact `
        -RepoRoot $repoRoot `
        -CandidatePath $CombatScenarioPath
    Invoke-CombatScenario `
        -Godot $godot `
        -RepoRoot $repoRoot `
        -ScenarioPath $resolvedScenario `
        -GodotVersion $version
    return
}

if (-not $ReplayPath) {
    $ReplayPath = 'tests\fixtures\replays\foundation_phase_replay.json'
}
$resolvedReplay = Resolve-RepositoryArtifact -RepoRoot $repoRoot -CandidatePath $ReplayPath
$resourcePath = ConvertTo-ResourcePath -RepoRoot $repoRoot -ResolvedPath $resolvedReplay
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
