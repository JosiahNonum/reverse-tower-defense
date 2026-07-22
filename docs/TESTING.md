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

## Intentional failure proof

`tests/fixtures/intentional_failure_test.gd` is excluded from normal discovery. Running it explicitly must print its assertion message and return a nonzero process exit:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test.ps1 -TestPath res://tests/fixtures/intentional_failure_test.gd
```

This fixture is verification evidence for the runner itself; it is not part of the passing suite.
