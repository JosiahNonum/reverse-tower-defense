# M1 Architecture Review

Status: M1.0 ratified
Reviewed: 2026-07-22
Source: [v0 Detailed Architecture Plan](V0_ARCHITECTURE_PLAN.md)

## Outcome

The proposed v0 architecture is accepted as the implementation baseline. It is intentionally small: a headless integer rules model inside one Godot project, immutable editor-authored content definitions, explicit application composition, presentation driven by snapshots and ordered events, and a fairness-filtered defender boundary.

The review found no unresolved product choice that must return to M0 before foundation work begins. Exact balance values can change through content; they do not require a different authority model.

## Accepted decisions

| Topic | Decision | Follow-up owner |
|---|---|---|
| Rules authority | Typed match-owned `RefCounted` state, integer fixed ticks, complete tie-breakers, and no scene, physics, animation, input, or signal authority | M1.1 ADR and tests |
| Tick and scale | 20 ticks per second and 1,000 logical position units per map unit | M1.1 integer-math tests; M2 performance measurement |
| Scale target | Measure 300 active units and 100 towers; optimize only from evidence | M2 stress scenario |
| Presentation | 1280x720 base resolution, shallow scene tree, explicit composition root, and no match-state autoload | M1.6 presenter seam |
| Content | Immutable custom `.tres` definitions with match-owned runtime state | M1.4 schemas, catalog, and validation |
| Portable data | Versioned JSON for settings and diagnostic scenario/replay artifacts | M1.7 replay contract |
| Testing | Prove a dependency-free `--headless --script` project runner before considering an addon | M1.2 spike |
| Save scope | No resumable in-progress match save is required for initial v0 | Revisit only from M5 usability evidence |
| Replay compatibility | Reject schema, rules, or content fingerprint mismatches; promise no indefinite compatibility | M1.7 tests |
| Visual entity strategy | One visual node per entity is acceptable until rendered profiling disproves it | M1.6 smoke view; M2 profiling |

## Guardrails

- Presentation may interpolate floats, but never returns authoritative coordinates or combat results.
- Loaded content resources are definitions and are never mutated by a match.
- Player and defender actions pass through the same validation and legality gateway.
- The defender never receives an uncommitted wave, unrestricted match state, or presentation objects.
- Diagnostics observe completed work and cannot change iteration order or RNG consumption.
- New dependencies, addons, native extensions, ECS, or multithreading require evidence and explicit approval.

## Focused decision records

- [ADR-0001](adrs/0001-simulation-authority-and-reproducibility.md) records simulation authority and the supported reproducibility guarantee.
- M1.2 records whether the dependency-free test runner is retained.
- M1.4 records content-resource immutability, validation, and fingerprint policy.
- M1.7 records diagnostic replay compatibility and rejection behavior.

Architecture work is not complete from this review alone. Each follow-up remains open until its executable acceptance evidence passes.
