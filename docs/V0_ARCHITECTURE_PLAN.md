# v0 Detailed Architecture Plan

Status: ratified v0 baseline; focused M1 ADRs and spikes in progress
Last updated: 2026-07-22
Scope: single-player Windows v0 MVP using Godot 4.7 and GDScript

This document turns the product and milestone plans into an implementable architecture. The M0 product inputs and the M1.0 technical baseline are ratified. Focused ADRs and executable spikes may refine implementation details without weakening the headless rules seam or honest-AI boundary.

Related sources:

- [Living project plan](PROJECT_PLAN.md)
- [v0 MVP development plan](V0_MVP_DEVELOPMENT_PLAN.md)
- [ADR-0001: Simulation Authority and Reproducibility](adrs/0001-simulation-authority-and-reproducibility.md)
- [ADR-0002: Content Resources and Fingerprints](adrs/0002-content-resources-and-fingerprints.md)
- [monday build board](https://jjs-team192542.monday.com/boards/18423168029)

## 1. Architecture goals

The architecture must make the adaptation duel fast to change, easy to inspect, and difficult to accidentally make unfair.

Required qualities:

- The outcome of combat is decided without rendered scenes, animation timing, or Godot physics bodies.
- A scenario can run headlessly from a seed and validated command sequence.
- The player UI, defender AI, tests, and debug tools use the same rules-facing command contracts.
- The AI can only observe information allowed by the product fairness contract.
- Content and balance changes do not require editing simulation control flow.
- A failed wave can be explained from ordered events and derived summaries.
- The first implementation remains ordinary Godot/GDScript; no backend, ECS, GDExtension, or multithreaded simulation is introduced for v0.

## 2. Decision status

### Ratified as the v0 baseline

- Godot 4.7.x with statically typed GDScript
- One Godot project rooted in this repository
- Windows desktop, mouse and keyboard, offline and local-first
- Authored lane graph with fixed build slots
- Fixed-tick authoritative simulation
- Integer authoritative values for ticks, currency, health, damage, cooldowns, IDs, and lane progress
- Lightweight `RefCounted` runtime model rather than one authoritative `Node` per entity
- Custom Godot `Resource` definitions for editor-authored content, treated as immutable after loading
- Explicit commands, ordered domain events, read-only presentation snapshots, and wave results
- Budgeted utility AI with bounded candidate generation and deterministic tie-breaking
- Versioned JSON for diagnostic scenario/replay artifacts and user settings
- The dependency-free headless project test runner recorded in [Project Test Harness](TESTING.md); reconsider a test add-on only if concrete test needs prove it inadequate and explicit dependency approval is granted

### Ratified working values, subject to measurement

- 20 simulation ticks per second
- 1,000 logical position units per map unit
- A v0 stress target of 300 simultaneously active units and 100 placed towers
- 1280x720 base presentation resolution

The tick rate and logical scale are authoritative v0 defaults. The stress target and base resolution are validation targets, not performance promises; profiling may change implementation strategy without changing rules authority.

### Ratified scope constraints

- The phase names, economy timing, targeting rules, status stacking, and initial archetype vocabulary are the M0 contracts recorded in the living product plan.
- v0 does not require resumable in-progress match saves. Versioned settings and diagnostic scenario/replay files are sufficient unless M5 usability evidence authorizes a scope change.

### Explicitly deferred

- Freeform path drawing or dynamic navigation meshes
- Physics-authoritative movement, collision, or projectiles
- Multithreaded or distributed simulation
- ECS, GDExtension, native code, backend services, accounts, or cloud persistence
- Machine-learned defender behavior
- Long-term replay compatibility across arbitrary content or rules changes

## 3. System context and dependency rule

```text
Player input
    |
    v
Godot UI and application coordinator -----> content catalog / settings
    |                         ^
    | validated commands      | snapshots, events, results
    v                         |
Authoritative simulation <----+
    ^
    | validated defense commands
Defender planner <---- observation projection <---- prior committed history
```

The dependency rule is inward-facing:

- `simulation` depends only on shared value types and validated content definitions.
- `defender_ai` depends on simulation contracts and an explicitly filtered observation model.
- `application` coordinates phases and owns live services, but does not decide combat rules.
- `presentation` and `ui` depend on snapshots/events exposed by the application seam; the simulation never references scenes, controls, animation, audio, or input.
- `content` may describe presentation references, but authoritative definitions never contain live scene nodes.

No application singleton is permitted to become an alternate rules authority. A minimal autoload may later hold process-wide settings or scene navigation, but the match is created and owned by an explicit composition root.

## 4. Authoritative simulation model

### 4.1 Runtime shape

The live match is a small graph of typed `RefCounted` objects and value-like records:

```text
MatchState
|- rules_version, content_fingerprint, seed
|- phase, round_index, tick
|- player_economy, defender_economy, core_health
|- lane_graph and build-slot occupancy
|- units_by_id
|- towers_by_id
|- effects/statuses
|- wave runtime queue
|- defender observation history
`- next_entity_id and RNG stream states
```

Definitions and runtime state are different types. A loaded `UnitDefinition` can be shared and cached; `UnitState` is match-owned and mutable. Runtime systems must never mutate a loaded `Resource`.

Entity IDs are monotonically allocated integers within a match. Stable content IDs are lowercase `StringName` or strings such as `unit.runner` and `tower.slow_field`; serialized artifacts use their textual form.

### 4.2 Time and numeric policy

- The simulation advances with `advance_one_tick()`; rendering frame delta is never passed into authoritative rules.
- Playback speed controls how many simulation ticks the application requests, not the size of a tick.
- All timers and cooldowns are integer tick counts.
- Health, damage, costs, refunds, and budgets are integers.
- Lane progress and logical map coordinates use scaled integers. Presentation converts them to floating-point screen/world coordinates.
- Squared integer distance is used for range checks; no square root is required for authority.
- Percentages use explicit integer basis points or rational numerator/denominator rules rather than hidden float rounding.
- Any unavoidable rounding mode is named, centralized, and tested.

This is stronger than relying on seeded randomness alone: it removes frame-rate and most floating-point drift from rule results without promising bitwise equivalence outside the supported build.

### 4.3 Tick order

With the ratified M0.2 through M0.5 vocabulary, the tick order is:

1. Apply commands scheduled for the tick boundary.
2. Spawn due units in stable wave-entry order.
3. Expire and apply start-of-tick statuses.
4. Advance units along authored lanes in ascending entity ID order.
5. Resolve goal arrival and leaks.
6. Acquire or validate tower targets using an explicit targeting comparator.
7. Advance attacks and enqueue damage/effect intents.
8. Resolve intents in a defined order, then deaths and rewards.
9. Emit tick-end summaries and evaluate wave/round/match completion.

Systems may create intents during a stage, but do not mutate collections while iterating them. Ties always have a documented final key, normally entity ID. A targeting rule such as “first” is therefore a full comparator, not an informal label.

### 4.4 v0 combat resolution

M0.5 defines deterministic instant attacks. A valid target is living, spawned, not leaked, and inside an inclusive squared-integer range check after movement. Rapid compares remaining route distance then entity ID; Splash compares in-radius victim count, remaining distance, then ID; Control prefers unslowed units then effective speed, remaining distance, and ID; Anti-armor compares armor, maximum health, remaining distance, then ID.

Ready towers acquire from the same post-movement target view and stage attacks in tower-ID order. Splash victims are ordered by entity ID. Intents resolve by source tower ID, attack ordinal, and target ID; deaths resolve only after all staged attack intents. Normal damage is `max(1, raw_damage - armor)` and penetration bypasses armor. Cosmetic projectiles never own hit results.

Rally is recomputed at the start-of-tick status stage from authoritative integer distance, is 125%, excludes its source, and does not stack. Control Slow is 60% for 30 ticks, refreshes rather than stacks, and begins at the next start-of-tick stage. Speed applies Rally then Slow with floor rounding and a living minimum of 1. Units that reach the core are removed before targeting, so death/leak cannot both occur in one tick.

### 4.5 Randomness

`MatchSeed` owns named streams derived from the root seed:

- `rules` only if a ratified combat rule needs randomness
- `defender_variation` for legal AI choice variation
- `scenario_generation` for offline test tooling
- `cosmetic` is presentation-owned and never recorded as authority

The v0 preference is deterministic combat with no hit/crit RNG. Adding authoritative randomness requires a named stream, a documented draw point, and a reproducibility test. AI evaluation order must not accidentally change RNG consumption; random variation is applied only after deterministic candidate scoring and tie grouping.

## 5. Commands, events, snapshots, and results

### Commands

Commands are requests, not trusted mutations. Each has a command ID, expected phase, actor, and typed payload. Initial command families are:

- wave draft operations and `CommitWave`
- `SetPlaybackState`
- defender `PlaceTower`, `UpgradeTower`, `SellTower`, and `ReserveBudget`
- lifecycle commands such as `StartMatch`, `AdvanceFromAnalysis`, and `RestartMatch`

Draft-only UI edits remain in application state until commit. Each normalized v0 wave entry contains a unit content ID, route ID, and spacing-after-previous value of 5, 15, or 30 ticks; list order is spawn order and the first entry is scheduled at wave tick 0. `CommitWave` contains 1 through 300 of these entries plus expected round, rules version, and content fingerprint, so replay does not depend on reconstructing every drag, batch edit, copy, undo, or click.

Commit validation is atomic and recomputes cost from authoritative content. Acceptance creates an immutable match-owned `CommittedWave` and spends attack budget once. Rejection preserves the application-owned draft and returns structured reasons. Only `SetPlaybackState` is a player gameplay command during resolution; camera and inspection are presentation concerns.

The command gateway returns either accepted commands or structured rejection codes. Tests, UI, and AI all call the same legality and affordability checks.

### Events

Every authoritative event carries `tick`, `ordinal`, `event_type`, and typed data. The ordinal is incremented within each tick, providing one stable total order.

Useful event families include spawn, movement milestone, target acquisition, attack, damage, status change, death, leak, economy change, tower action, phase change, and AI rationale reference. High-frequency events may be omitted from the persisted diagnostic stream if they do not help presentation or analysis; the event contract is purposeful telemetry, not a dump of every assignment.

Events are retained for the current wave. At wave end, the application derives a compact `WaveResult` and `AnalysisSummary`, then releases unneeded fine-grained history. This bounds memory over a five-round match.

### Snapshots

`MatchView` is a read-only projection generated at a tick boundary for presentation. It contains logical positions, visible stats, phase/economy data, and stable IDs. Presentation nodes reconcile themselves from this snapshot and may interpolate between the previous and current view.

The snapshot deliberately excludes mutable simulation objects. UI code cannot retain an entity reference and change health or placement.

### Results and diagnostic replay

`WaveResult` and `MatchResult` contain totals and reason-coded outcomes used by post-wave analysis and tests. A diagnostic scenario/replay artifact records:

- artifact schema version
- rules version and content fingerprint
- root seed
- normalized scenario definition or content IDs
- accepted phase-boundary commands
- expected summary or optional event digest

Replays are debugging and regression artifacts. If rules or content fingerprints differ, the runner reports incompatibility instead of silently claiming the old result is valid.

## 6. Map, content, and validation

Authoritative content uses custom `.tres` resources because they are Inspector-friendly, version-controllable, and native to Godot. Definitions are registered through a `ContentCatalog` built at startup.

Primary definitions:

- `MapDefinition`: stable ID, logical bounds, one spawn/core, directed lane nodes and positive-length edges, explicit ordered route edge lists, fixed build slots, and presentation scene reference
- `UnitDefinition`: integer cost, health, armor, speed, leak damage, and optional non-stacking Rally specification
- `TowerDefinition`: integer cost/upgrade, range, cadence, complete targeting comparator kind, direct/splash damage, optional penetration or Slow specification, and presentation scene reference
- `MatchRulesDefinition`: round count, budgets, rewards, core health, timing, and difficulty profile reference
- `DefenderProfile`: legal policy knobs and scoring weights, never hidden observations

Content validation runs before a match and in headless verification. It rejects duplicate or missing IDs, invalid references, negative or overflow-prone values, unreachable routes, disconnected goals, invalid build slots, upgrade cycles, unsupported status combinations, and definitions that violate v0 bounds.

For the v0 map, `route.north` and `route.south` share authored approach and post-merge edges. Unit runtime position is route ID, edge-list index, and integer distance on that edge. Units have no authoritative collision occupancy and may overlap or pass; only tower build slots have exclusive occupancy. Presentation curves cannot create graph connectivity. Reaching the core stages exactly one leak intent and removes the unit from movement/target eligibility.

Resources are definitions, not save files. Versioned JSON is used where a human-readable portable runtime artifact is more useful: settings, diagnostic scenarios, replay command logs, and test fixtures.

M1.4 implements this boundary through the validated `ContentCatalog` and the checked-in `content/` resources. The durable immutability, validation, and SHA-256 fingerprint decision is recorded in [ADR-0002](adrs/0002-content-resources-and-fingerprints.md).

## 7. Godot application and scene architecture

The initial scene tree should stay shallow:

```text
Main (composition root)
|- MatchCoordinator
|- MatchScreen
|  |- BattlefieldView
|  |  |- MapView
|  |  |- UnitViewRoot
|  |  |- TowerViewRoot
|  |  `- OverlayView
|  |- WaveComposerPanel
|  |- MatchHud
|  `- AnalysisPanel
`- DebugOverlay
```

- `Main` loads definitions, creates the match services, and connects explicit interfaces.
- `MatchCoordinator` owns the match phase state machine and calls the simulation runner and defender planner.
- `BattlefieldView` reconciles visual scenes against `MatchView`; unit/tower scenes contain visuals only.
- UI panels emit user intents and render view models. They do not call entity methods.
- Signals are used at UI/application boundaries for user intent and notifications. Signals are not used to determine authoritative intra-tick order.
- Node groups may locate visual/debug participants, but not simulation entities.
- Autoloads are limited to true process-wide concerns. Match state, content mutation, and rules execution are never globally reachable singletons.

One visual node per active unit is acceptable for the initial measured envelope. If profiling disproves that assumption, presentation can pool views or batch sprites without rewriting the rules core.

## 8. Match lifecycle

The coordinator enforces the M0.2 phase state machine:

```text
INITIAL_DEFENSE -> DEFENSE_REVEAL -> WAVE_AUTHORING -> WAVE_COMMITTED -> RESOLVING
                                                                         |
                                                                         v
                                                                     ANALYSIS
                                                                       |  \
                                                  more rounds          |   \ terminal
                                                                       v    v
DEFENSE_REVEAL <- DEFENDER_ADAPTATION <- ROUND_TRANSITION          MATCH_END
```

The defender builds the initial defense from map, rules, profile, and seed. Between rounds it receives only the allowed observation projection of committed history. It never receives the live wave draft. The coordinator captures the exact observation before asking the planner for commands, then validates those commands through the normal command gateway. Initial defense and defender adaptation are the only phases that accept defense actions. `DEFENSE_REVEAL` is a player-visible application phase and cannot mutate rules state.

The rules definition supplies the five-round attack budget schedule, initial defense budget, adaptation grants, 75% floor-rounded sale refund, and 10-integrity core from the product contract. Attack budget is round-local; defense reserve and tower investment persist. Economy changes are authoritative ordered events, not UI calculations.

Pause stops requests for simulation ticks. Faster playback advances multiple fixed ticks while presentation renders the newest snapshot. Planning and analysis are not simulation-time phases.

## 9. Defender AI architecture

The AI boundary is capability-based. During `INITIAL_DEFENSE` and `DEFENDER_ADAPTATION`, the application assembles an immutable `DefenderObservationInput` only from public definitions/rules, defender-owned state/economy, core/round context, and finalized `WaveResult`/`AnalysisSummary` history. `ObservationProjector` applies the difficulty's completed-history age and creates the value-only `DefenderObservation` passed to the planner.

Neither input nor observation contains `MatchState`, the application draft, an unresolved/current `CommittedWave`, live entities/events, UI/input/presentation objects, root seed, unrelated RNG streams, cross-match files, or mutable resources. The new player draft is created only after planning and defense reveal. AI modules have no global match lookup. Contract tests enforce type/dependency boundaries and attempt forbidden reads.

The explicit pipeline is:

1. `ObservationProjector` creates a fairness-filtered `DefenderObservation` and observation fingerprint.
2. `ThreatAnalyzer` derives lane, armor, density, speed, spacing, support, and leak-pressure features from permitted prior results.
3. `CandidateGenerator` enumerates legal placements/upgrades/sales/reserves within hard caps.
4. `UtilityScorer` emits a score breakdown per candidate.
5. `BudgetPlanner` selects a bounded action set using deterministic greedy selection, synergy adjustments, and stable tie-breaking.
6. `VariationPolicy` may choose within a near-equal score band using only the `defender_variation` stream.
7. The command gateway independently validates every selected action.
8. `DecisionTrace` records permitted source rounds, observations/features used, caps/truncation, rejected candidates, integer component scores, variation draw ordinals/indices, chosen actions, gateway results, remaining budget, and stop reason.

Planning is bounded by deterministic candidate and action counts, not wall-clock authority. Candidate simulation/rollouts and recursive search are not part of v0. Stable candidate keys order action kind, slot ID, tower entity ID, definition ID, and upgrade ID. The Easy/Normal/Hard profiles cap candidates at 32/64/128 and selected commands at 4/6/8.

`VariationPolicy` may select only inside the documented 1,500/500/0-basis-point near-equal band using one indexed draw from `defender_variation` per selected action. Legality, scoring, and candidates outside the band are deterministic. Diagnostics are write-only and cannot consume RNG or alter planning.

Difficulty changes only completed-history age, public integer scoring weights/features, candidate/action breadth, intended reserve, or near-equal variation. Easy sees completed history with a one-round delay; Normal and Hard see through the most recently completed round. All difficulties use the same grants, prices, refund, tower stats, core, legal commands, command order, and observation schema. The planner can propose only `PlaceTower`, `UpgradeTower`, `SellTower`, and `ReserveBudget`; the shared gateway independently validates each sequential command.

Observation history is match-local, append-only, ordered, and capped at five finalized rounds. Restart/new match clears history, features, caches, candidates, and traces before reconstructing state. v0 performs no cross-match learning or player profiling.

## 10. Repository and module layout

```text
/
|- project.godot
|- export_presets.cfg
|- docs/
|  |- .gdignore
|  `- ...plans and ADRs
|- src/
|  |- shared/          # IDs, result/error types, integer math, serialization helpers
|  |- content/         # Resource definitions, catalog, validation
|  |- simulation/      # state, commands, systems, events, snapshots, results
|  |- defender_ai/     # observation, analysis, candidates, scoring, planning, traces
|  |- application/     # composition, phases, orchestration, settings/replay services
|  |- presentation/    # battlefield views, effects, audio, camera, visual scenes
|  `- ui/              # wave composer, HUD, inspection, analysis
|- content/
|  |- maps/
|  |- units/
|  |- towers/
|  `- rules/
|- tests/
|  |- unit/
|  |- scenarios/
|  |- contracts/
|  |- integration/
|  `- fixtures/
|- scripts/            # repository-root PowerShell entry points
`- build/               # ignored generated output
```

Use lowercase `snake_case` paths and file names. Each feature folder may colocate a scene with its visual assets where that improves maintainability, but authoritative simulation and content contracts retain the dependency boundaries above.

## 11. Verification architecture

The retained test runner is a project script invoked with Godot `--headless --script`. This is intentionally separate from Godot's engine-development `--test` suite, which is not a user-project test harness. M1.2 proved discovery, filtering, readable assertions and timing, a passing suite, and a nonzero failure exit without adding a dependency. The commands and retain/replace decision are recorded in [Project Test Harness](TESTING.md).

Test layers:

- Pure rule tests for integer math, comparators, command validation, movement, targeting, damage, statuses, economy, and phase transitions
- Content contract tests for every checked-in definition and invalid fixture
- Seeded scenario tests comparing result summaries and selected event digests
- AI contract tests for observation filtering, legality, budget, termination, candidate caps, and trace completeness
- Integration tests for a complete scripted five-round match
- Presentation smoke checks for snapshot reconciliation and UI phase availability
- Performance scenarios measuring headless simulation throughput and rendered frame behavior separately
- Export smoke checks for headless Windows build creation and launch

Golden files are limited to stable summaries or event digests. Broad serialized object snapshots are avoided because they make harmless refactors expensive.

Repository-root PowerShell commands should eventually provide `setup` or `doctor`, `verify`, `run`, `test`, `scenario`, and `export` entry points. S0 defines their actual names after the workstation audit.

## 12. Red-team findings and safeguards

### Shared `Resource` mutation can corrupt multiple matches

Godot caches loaded resources. Safeguard: treat definition resources as immutable, validate once, and create separate match-owned runtime state. Add a test proving one match cannot change another match's definitions.

### A scene-first implementation could quietly regain authority

Animation callbacks, physics bodies, or signal order are tempting shortcuts. Safeguard: scenario tests run with no battlefield scene, and the simulation module cannot import presentation/UI classes.

### “Fixed tick” alone does not guarantee reproducible outcomes

Floats, unordered iteration, and ambiguous ties can still drift. Safeguard: integer authority, stable iteration, complete comparators, named RNG streams, and event-digest tests.

### Telemetry can become an unbounded event warehouse

Hundreds of units across five waves can create noisy logs. Safeguard: retain fine events per wave, derive compact summaries, explicitly whitelist persisted event types, and measure log size.

### Replay files can lie after balance changes

Safeguard: include schema, rules version, and content fingerprint; reject incompatible playback. v0 makes no indefinite compatibility promise.

### Utility planning can grow combinatorially

Safeguard: hard candidate caps, bounded greedy planning, diagnostics for truncation, and termination tests. No recursive search or sampled rollout is required initially.

### An application coordinator can become a god object

Safeguard: coordinator only sequences phases and services. Rule validation remains in simulation; observation projection remains in AI; view-model creation remains at the presentation seam.

### A third-party test framework can become setup debt

Safeguard: first prove a dependency-free headless runner. If its diagnostics or ergonomics are inadequate, compare a maintained add-on during M1.2 and request approval before adding it.

### Integer spatial math can spread complexity everywhere

Safeguard: centralize scale conversion, interpolation, squared distance, and rounding in a small tested module. Presentation is free to use floats after it receives logical coordinates.

## 13. Architecture delivery sequence

1. Finish M0 contracts that can change rules, phases, routes, and AI knowledge.
2. Ratify this baseline and record focused ADRs for simulation authority, content/resources, testing, and replay compatibility.
3. Complete S0 local toolchain verification before gameplay implementation.
4. Build the typed content catalog and validators.
5. Build the headless command/state/event seam with one tiny scenario.
6. Add snapshot/presenter reconciliation with placeholder visuals.
7. Prove fixed-defense combat before connecting adaptive AI.
8. Add AI through the same observation and command contracts.

Architecture work is complete only when the decisions are reflected in executable boundaries and verification evidence, not when the diagrams are approved.

## 14. M1.0 review outcome

M1.0 accepted the following baseline on 2026-07-22:

- Integer authoritative movement and lane progress, with float conversion confined to presentation
- A 20 Hz simulation tick and 1,000 logical position units per map unit
- An initial measured envelope of 300 active units and 100 towers at a 1280x720 base resolution
- Immutable custom `.tres` content definitions plus versioned JSON settings and diagnostic artifacts
- A dependency-free project test runner as the first choice
- No resumable in-progress match save in initial v0 scope
- A shallow scene tree, no match-state autoload, and one visual node per entity until profiling shows a need to change presentation strategy
- Diagnostic replay compatibility guarded by schema version, rules version, and content fingerprint, with no indefinite compatibility promise

The review record and follow-up decision map are in [M1 Architecture Review](M1_ARCHITECTURE_REVIEW.md). Focused ADRs own durable decisions; executable tests own proof that the boundaries work.
