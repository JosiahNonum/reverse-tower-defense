# Reverse Tower Defense

A single-player reverse tower defense game in which the player authors attack waves while a fair AI builds and adapts the defense between rounds.

## Status

The project is in product and architecture planning. The pinned v0 stack is Godot 4.7.1 with statically typed GDScript, targeting Windows desktop first.

A minimal, non-gameplay Godot project and its local Windows workflow are established. Gameplay implementation begins in later milestones.

## Plans

- [Living project plan](docs/PROJECT_PLAN.md)
- [v0 MVP development plan](docs/V0_MVP_DEVELOPMENT_PLAN.md)
- [Detailed architecture plan](docs/V0_ARCHITECTURE_PLAN.md)
- [Local toolchain policy and workstation audit](docs/LOCAL_TOOLCHAIN.md)
- [S0 verification record](docs/S0_VERIFICATION.md)
- [monday build board](https://jjs-team192542.monday.com/boards/18423168029)

## Repository workflow

Godot source, GDScript, scenes, resources, project settings, tests, and documentation belong in Git. Godot's generated `.godot/` cache and generated builds do not.

Repository-root run, test, and export commands are documented below and verified in [the S0 record](docs/S0_VERIFICATION.md). See [AGENTS.md](AGENTS.md) for the working boundaries.

## Local commands

Run these commands from the repository root in Windows PowerShell:

```powershell
.\scripts\doctor.ps1
.\scripts\verify.ps1
.\scripts\run.ps1
.\scripts\run.ps1 -Editor
.\scripts\export.ps1
```

`doctor` validates the pinned Godot editor and templates. `verify` performs a headless project parse and smoke test. `run` launches the placeholder project, with `-Editor` available to open the editor. `export` produces the ignored Windows artifact under `build/windows`.
