# Reverse Tower Defense

A single-player reverse tower defense game in which the player authors attack waves while a fair AI builds and adapts the defense between rounds.

## Status

The project is in product, architecture, and local-environment planning. The proposed v0 stack is Godot 4.7.x with statically typed GDScript, targeting Windows desktop first.

No playable Godot project has been scaffolded yet. Local setup and the first runnable project are tracked as the S0 phase of the development plan.

## Plans

- [Living project plan](docs/PROJECT_PLAN.md)
- [v0 MVP development plan](docs/V0_MVP_DEVELOPMENT_PLAN.md)
- [Detailed architecture plan](docs/V0_ARCHITECTURE_PLAN.md)
- [monday build board](https://jjs-team192542.monday.com/boards/18423168029)

## Repository workflow

Godot source, GDScript, scenes, resources, project settings, tests, and documentation belong in Git. Godot's generated `.godot/` cache and generated builds do not.

Repository-root run, test, and export commands will be added and verified during S0. See [AGENTS.md](AGENTS.md) for the working boundaries.

