# Project Test Harness

Status: dependency-free runner retained for M1
Decision date: 2026-07-22

## Decision

The project uses a small GDScript runner invoked through Godot's project-level `--headless --script` support. Godot's engine-development `--test` option is not used as a project test harness. No addon or third-party dependency is needed for the current test requirements.

The runner provides:

- recursive discovery of `*_test.gd` files under `tests/unit`, `tests/scenarios`, `tests/contracts`, and `tests/integration`
- stable path and method ordering
- substring filtering by full `res://path::test_method` name
- focused execution of an explicit test script
- readable per-test results, assertion counts, durations, and a suite summary
- exit code `0` for a passing suite, `1` for assertion failures, and `2` for runner or selection errors

The test framework remains deliberately narrow. Reconsider a maintained addon only if concrete tests require diagnostics or lifecycle behavior this runner cannot provide, and request approval before adding one.

## Commands

Run all project tests from the repository root:

```powershell
.\scripts\test.ps1
```

Filter by path or method substring:

```powershell
.\scripts\test.ps1 -Filter framework
```

Run one explicit script:

```powershell
.\scripts\test.ps1 -TestPath res://tests/unit/test_framework_test.gd
```

The normal verification gate parses the project, runs the presentation smoke test, and then runs the discovered project tests:

```powershell
.\scripts\verify.ps1
```

The verification gate also runs the checked semantic combat scenarios. They can be exercised separately:

```powershell
.\scripts\scenario.ps1 -CombatSuite
.\scripts\scenario.ps1 -CombatScenarioPath tests\fixtures\combat_scenarios\splash_density.json
```

Combat artifacts record a seed, real content IDs, normalized wave/tower inputs, a bounded tick count, and an expected semantic summary. Failures report precise dictionary paths and expected/actual values rather than relying on screenshots or a digest alone.

Performance is measured separately from the ordinary deterministic gate because workstation timing is hardware-sensitive:

```powershell
.\scripts\benchmark.ps1
.\scripts\benchmark.ps1 -SkipRender
```

The first command measures headless simulation with diagnostics on/off and then opens a short-lived rendered window for the 1280x720 presentation proxy. Thresholds, current workstation results, and the required production-visual recheck are recorded in [M2 Performance Envelope](M2_PERFORMANCE.md).

## Intentional failure proof

`tests/fixtures/intentional_failure_test.gd` is excluded from normal discovery. Running it explicitly must print its assertion message and return a nonzero process exit:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1 -TestPath res://tests/fixtures/intentional_failure_test.gd
```

This fixture is verification evidence for the runner itself; it is not part of the passing suite.
