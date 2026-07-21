# Agent guide

## Product and boundaries

Reverse Tower Defense is a local-first, single-player Windows game in which the player authors attack waves and a fair AI builds and adapts the tower defense between rounds.

- Godot 4.7.x and statically typed GDScript are the provisional v0 stack.
- `docs/PROJECT_PLAN.md` owns the living product direction.
- `docs/V0_MVP_DEVELOPMENT_PLAN.md` owns milestone scope and delivery gates.
- `docs/V0_ARCHITECTURE_PLAN.md` owns the proposed technical boundaries until focused ADRs supersede a decision.
- `src/simulation` owns authoritative rules, state, commands, events, snapshots, and results.
- `src/defender_ai` owns fairness-filtered observations, threat analysis, candidates, scoring, planning, and decision traces.
- `src/content` owns definitions, the content catalog, and content validation.
- `src/application` owns composition, match phases, orchestration, settings, and diagnostic replay services.
- `src/presentation` and `src/ui` own scenes, rendering, audio, input, wave authoring, inspection, and analysis displays.

The authoritative simulation must run headlessly without rendered scenes, animation timing, input, or Godot physics bodies. Presentation consumes read-only snapshots and ordered events; it never decides a combat result.

## Working conventions

- Inspect the relevant plan and ADR before changing product scope, contracts, or architectural boundaries.
- Keep authoritative simulation state out of the scene tree. Use typed `RefCounted` runtime objects and explicit interfaces unless an approved ADR changes the boundary.
- Use fixed integer ticks and centralized integer math for authoritative timing, health, damage, economy, cooldowns, IDs, lane progress, and logical coordinates.
- Treat loaded custom `Resource` definitions as immutable. Create separate match-owned runtime state because Godot caches loaded resources.
- Route player and defender actions through the same command validation and legality checks.
- Never expose the current uncommitted player wave to the defender AI.
- Preserve stable iteration, complete tie-breakers, named RNG streams, and ordered events where results must be reproducible.
- Add tests with every behavior change. Never mark work complete from parsing, compilation, or export alone.
- Do not add dependencies, addons, plugins, or change architecture without explicit approval.
- Do not commit secrets, `.godot/` cache data, generated builds, logs, local settings, or diagnostic files containing private machine paths.
- Keep work aligned to one monday item when practical and record concrete verification evidence before marking it Done.

## Git workflow

- The user performs all remote Git operations, including creating the GitHub repository, configuring remotes, pulling, pushing, and remote branch management.
- Prepare local changes and provide clear verification and commit-ready summaries; do not initiate remote Git operations.
- Do not rewrite or discard the user's local changes. Work around unrelated edits and report any unavoidable overlap.

## Commands

The repository-root PowerShell commands will be established during S0. Until then, do not invent or document commands as working when they have not been created and verified.

Planned command responsibilities:

```text
doctor/setup  inspect the local Godot toolchain
run           launch the project
test/verify   parse the project and run headless tests
scenario      run a diagnostic scenario or replay
export        produce a Windows build
```

## Code standard

### General rules

- Use statically typed GDScript for production code and test contracts where practical.
- Follow Godot naming conventions: `snake_case` files, folders, functions, variables, signals, and groups; `PascalCase` node names and `class_name` types; `UPPER_SNAKE_CASE` constants.
- Reuse existing scenes, resources, components, and functions before creating new ones.
- Prefer Godot and GDScript built-ins over hand-rolled proxies. Do not create utilities that merely rename built-in behavior.
- Prefer early returns over deeply nested conditionals.
- Keep functions focused. Extract named values before allowing a call or expression to become difficult to read.
- Prefer explicit typed objects for stable contracts over unstructured dictionaries. Dictionaries are acceptable at serialization boundaries with immediate validation.
- Keep comments concise and add context that the code cannot communicate itself. Avoid duplicating the same explanation in multiple locations.
- Shared helpers belong in a small, focused module rather than being duplicated across features.
- Do not overcomplicate. Use the smallest viable design unless it materially harms correctness, testability, or readability.

### Simulation

- Do not use frame delta, physics callbacks, scene signals, animation callbacks, or collection iteration accidents as rules authority.
- Do not mutate a collection while iterating it. Stage intents and resolve them in an explicit order.
- Every ambiguous rules order requires a documented final tie-breaker, normally stable entity ID.
- Keep definition resources separate from mutable runtime state.
- Centralize logical-coordinate conversion, interpolation, squared-distance checks, percentages, and rounding rules.
- Preserve the command-in and event/snapshot/result-out seam so tests and diagnostic scenarios can run without presentation.

### Defender AI

- Read only from the approved `DefenderObservation`; do not reach into live UI drafts or unrestricted match state.
- Bound candidate counts and planning work. Add termination, legality, budget, and repeatability tests.
- Record score components and selection reasons in a decision trace without changing RNG consumption or rules order.
- Difficulty may change allowed information age, scoring weights, candidate breadth, reserves, or controlled variation. It may not cheat on economy or hidden information.

### Performance

- Measure before replacing ordinary Godot/GDScript with pooling, batching, ECS, GDExtension, native code, or multithreading.
- Measure headless simulation performance separately from rendered frame performance.
- Prefer clear code when performance differences are marginal, but do not hide avoidable per-tick allocations or unbounded work in hot paths.

### Function order

- Group functions by feature and call flow where practical.
- Keep public entry points and lifecycle functions easy to find, followed by their focused helpers.
- Group related simulation stages, serializers, validators, or AI pipeline functions together rather than alphabetizing unrelated behavior.

