# ADR-0001: Simulation Authority and Reproducibility

Status: Accepted
Date: 2026-07-22
Owners: M1.1 Architecture and Foundation

## Context

Reverse Tower Defense needs repeatable combat, useful diagnostics, honest defender observations, and presentation that can change without changing results. Godot scenes, physics callbacks, animation timing, signals, floating-point drift, unordered iteration, and shared mutable resources would make those guarantees difficult to inspect and test.

The M0 contract fixes a five-round match, authored routes, deterministic instant attacks, explicit targeting comparators, integer economy, and fairness-filtered defender history. M1.0 accepted the detailed architecture baseline.

## Decision

### Authority ownership

- `src/simulation` owns match phases, ticks, entity state, lane progress, targeting, combat intents, health, damage, statuses, core integrity, economy, entity IDs, command validation, ordered events, snapshots, and results.
- Match runtime is a graph of typed `RefCounted` objects. Loaded content resources are immutable definitions and never hold mutable match state.
- `src/application` owns composition and orchestration, but changes rules state only through validated commands or explicit simulation entry points.
- `src/presentation` and `src/ui` consume copied snapshots and ordered events. Scenes, nodes, animation, audio, input, signals, and frame delta never determine an authoritative result.
- `src/defender_ai` receives only the approved immutable observation and submits actions through the same command legality gateway used by scripted or player-authorized actions.

### Time and numeric policy

- Authority advances only through `advance_one_tick()` at 20 ticks per second.
- Ticks, cooldowns, health, damage, armor, currency, budgets, IDs, lane progress, and logical coordinates are integers.
- Logical coordinates use 1,000 units per map unit. Presentation may convert them to floats after snapshot creation.
- Percentages use explicit integer ratios or basis points. Each rounding rule is named, centralized, and tested.
- Range checks use squared integer distance.

### Stable tick stages

Each resolving tick uses this order:

1. apply commands scheduled for the tick boundary
2. spawn due units in committed-wave entry order
3. expire and apply start-of-tick statuses
4. advance units by ascending entity ID
5. resolve goal arrival and leaks
6. acquire or validate targets with complete comparators
7. advance attacks and stage damage/effect intents
8. resolve intents, deaths, and rewards in documented order
9. emit tick-end summaries and evaluate completion

Systems stage intents rather than mutating a collection during iteration. Every comparator has a final stable entity-ID key. Events carry tick plus an ordinal that increments within that tick.

### Commands and projections

Commands are untrusted requests with an actor, expected phase, command identity, and typed payload. Invalid requests return structured rejection codes and do not partially mutate state. The UI, defender planner, scenarios, and replays use the same gateway.

`MatchView`, `WaveResult`, and `MatchResult` are copied projections. They expose no mutable simulation objects. Diagnostic events and traces are outputs only; enabling them cannot consume RNG or alter rule order.

### Randomness

- A root match seed derives isolated, named streams.
- Initial names are `rules`, `defender_variation`, and offline-only `scenario_generation`; presentation owns an unrecorded `cosmetic` stream.
- Adding a rule draw requires a named stream, documented draw point, and repeatability test.
- Cross-stream draw order cannot change another stream's sequence.
- Deterministic scoring and complete tie-breakers run before any permitted defender variation draw.

### Supported reproducibility guarantee

The project guarantees the same accepted command sequence produces the same ordered event digest and result summary when all of these match:

- Godot build and project rules version
- content fingerprint
- root seed and named-stream implementation
- normalized initial scenario
- command order and payloads

The guarantee targets the pinned Windows v0 build and headless execution of the same rules. It does not promise compatibility across arbitrary Godot versions, rules changes, content changes, platforms, physics behavior, or old diagnostic schemas. Incompatible diagnostic artifacts must fail clearly instead of silently replaying.

## Consequences

- Simulation code is more explicit than scene-driven gameplay and requires conversion at the presentation seam.
- Complete ordering and integer math make regression tests and failure analysis practical.
- Presentation can interpolate, pool, or batch visuals without rewriting combat.
- Future changes to tick rate, integer scale, RNG derivation, or stage order are rules-version changes and require updated replay evidence.
- Dependency contract tests scan the simulation module for node, presentation, and UI coupling; headless authority tests execute without loading a scene.

## Initial evidence

- Two phase-boundary transitions execute headlessly through typed commands and emit tick-plus-ordinal events.
- A forbidden actor is rejected without changing phase or emitting events.
- Targeting ties resolve by remaining route distance and then stable entity ID.
- Named RNG stream results are independent of cross-stream draw order.
- A dependency contract test proves current simulation scripts do not extend `Node` or import presentation/UI paths.

These probes establish the boundary. M1.3 extends the same types into the full seeded state, command, event, snapshot, and result seam.
