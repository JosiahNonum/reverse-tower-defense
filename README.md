# Reverse Tower Defense

A single-player reverse tower defense game in which the player authors attack waves while a fair AI builds and adapts the defense between rounds.

## Status

The project has a ratified v0 product contract and architecture baseline. The pinned v0 stack is Godot 4.7.1 with statically typed GDScript, targeting Windows desktop first.

The non-gameplay M1 foundation is complete: the project has a dependency-free test runner, headless seeded rules primitives, validated content, an explicit snapshot-driven composition/presentation seam, versioned diagnostic replay contracts, and verified Windows export/launch commands. M2 begins fixed-defense gameplay implementation.

## Plans

- [Living project plan](docs/PROJECT_PLAN.md)
- [v0 MVP development plan](docs/V0_MVP_DEVELOPMENT_PLAN.md)
- [Detailed architecture plan](docs/V0_ARCHITECTURE_PLAN.md)
- [M1 architecture review](docs/M1_ARCHITECTURE_REVIEW.md)
- [ADR-0001: simulation authority and reproducibility](docs/adrs/0001-simulation-authority-and-reproducibility.md)
- [ADR-0002: content resources and fingerprints](docs/adrs/0002-content-resources-and-fingerprints.md)
- [ADR-0003: versioned diagnostic replay contract](docs/adrs/0003-versioned-diagnostic-replay-contract.md)
- [Local toolchain policy and workstation audit](docs/LOCAL_TOOLCHAIN.md)
- [S0 verification record](docs/S0_VERIFICATION.md)
- [M1 verification record](docs/M1_VERIFICATION.md)
- [monday build board](https://jjs-team192542.monday.com/boards/18423168029)

## Repository workflow

Godot source, GDScript, scenes, resources, project settings, tests, and documentation belong in Git. Godot's generated `.godot/` cache and generated builds do not.

Repository-root run, test, and export commands are documented below and verified in [the S0 record](docs/S0_VERIFICATION.md). See [AGENTS.md](AGENTS.md) for the working boundaries.

## Local commands

Run these commands from the repository root in Windows PowerShell:

```powershell
.\scripts\doctor.ps1
.\scripts\test.ps1
.\scripts\verify.ps1
.\scripts\scenario.ps1
.\scripts\run.ps1
.\scripts\run.ps1 -Editor
.\scripts\export.ps1
```

`doctor` validates the pinned Godot editor and templates. `test` runs the dependency-free project test harness documented in [Project Test Harness](docs/TESTING.md). `verify` performs a headless project parse, presentation smoke test, project test suite, checked diagnostic replay, and incompatible-schema rejection probe. `scenario` replays the checked foundation fixture by default and accepts `-ReplayPath` for another repository-local artifact. `run` launches the placeholder project, with `-Editor` available to open the editor. `export` produces the ignored Windows artifact under `build/windows`, starts it in a bounded headless smoke check, and reports artifact hashes.
