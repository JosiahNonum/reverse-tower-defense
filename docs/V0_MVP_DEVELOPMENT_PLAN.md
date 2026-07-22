# v0 MVP Development Plan

Status: Active execution plan; M0 product contract and M1 architecture baseline ratified
Last updated: 2026-07-22
Source product plan: [PROJECT_PLAN.md](PROJECT_PLAN.md)

Execution board: [Reverse Tower Defense — v0 MVP Build Plan](https://jjs-team192542.monday.com/boards/18423168029) (`18423168029`)

## 1. Planning workflow

This plan was produced with the following workflow:

1. Investigate the premise, comparable games, current Godot capabilities, and the existing project plan.
2. Propose the smallest development sequence that can validate the adaptation-duel hypothesis.
3. Red-team the sequence for hidden scope, premature infrastructure, unfair AI, unverifiable success criteria, and likely technical traps.
4. Revise the plan to address those findings.
5. Encode the revised skeleton into monday.com with milestones, bounded tasks, acceptance criteria, verification expectations, and dependencies.

The repository document explains why the plan exists. The monday.com board is the execution source of truth once work begins.

## 2. v0 MVP outcome

v0 MVP is a local Windows build of a complete, replayable, single-player adaptation-duel match.

The player can inspect an AI-authored defense, compose and commit an attacking wave, understand the result, and counter-adapt over five rounds. The AI changes its defense between rounds using only permitted information from earlier committed waves.

### Required playable scope

- One 2D top-down map
- Two authored routes with a shared chokepoint
- Five-round match structure
- Four player unit archetypes: swarm, tank, runner, and support
- Four defender tower archetypes: rapid, splash, control, and anti-armor
- Player control over composition, deployment order, spacing, and route
- No direct unit control after commitment in v0
- AI defense construction between waves
- AI knowledge limited to the current map, defense state, economy, rules, and prior committed-wave history
- Pause plus 1x, 2x, and 4x playback
- Tower range, route, and basic threat inspection
- Post-wave explanation of damage, deaths, leaks, and the main failure locations
- Win, loss, restart, and complete-match flow
- Seeded, reproducible game-rule scenarios
- Documented local development, test, and Windows export workflow

### Ratified M0.2 match baseline

The detailed source is the [v0 match, economy, and outcome contract](PROJECT_PLAN.md#v0-match-economy-and-outcome-contract). In summary:

- A match has exactly five rounds and a 10-integrity core that does not heal.
- The player receives fresh attack budgets of 100, 120, 140, 160, and 180; unspent attack budget expires and committed units are consumed.
- The defender receives 120 before round 1 and 40 before each later round; towers and unspent reserve persist, and sales refund 75% rounded down.
- Neither side receives performance rewards. This prevents early results from creating an economy snowball that obscures counter-adaptation.
- Each round flows through defense reveal, wave authoring, commit, fixed-tick resolution, analysis, and—unless terminal—defender adaptation before the next reveal.
- The player wins immediately when leaks reduce core integrity to 0. Otherwise the defender wins after round 5; there is no draw or score tie-break.
- Restart rebuilds the entire match from the same seed and definitions with no retained damage, economy, draft, defense, or AI memory.

M0.3 defines draft verbs, M0.4 defines valid routes, and M0.5 assigns content costs and leak damage without changing this economy shape.

### Ratified M0.3 wave-authoring baseline

The detailed source is the [v0 wave-authoring and committed-agency contract](PROJECT_PLAN.md#v0-wave-authoring-and-committed-agency-contract). The v0 composer edits an ordered list of individual unit entries with per-entry route and one of three positive spacing presets: 5, 15, or 30 authoritative ticks. Quantity add, multi-select, duplicate, reorder, route/spacing edits, undo/redo, clear, and explicit copy-previous are authoring conveniences; commit always expands to a normalized list capped at 300 entries.

Commit validates phase, entry count, content IDs, routes, spacing, total cost, round, rules version, and content identity atomically. A rejection preserves both draft and budget with structured reasons. Acceptance freezes the plan and spends its cost once. Afterward the player has inspection, camera, pause, and 1x/2x/4x playback only—no rerouting, retiming, steering, targeting, abilities, or per-unit cancellation.

### Ratified M0.4 lane and route baseline

The detailed source is the [v0 authored lane and route contract](PROJECT_PLAN.md#v0-authored-lane-and-route-contract). One fixed directed acyclic graph provides a shared spawn/approach, North and South branch corridors, a merge, a shared chokepoint, and one core. Every committed unit selects exactly one explicit route before spawning and cannot switch it.

Authoritative position is integer edge progress. Units do not collide, body-block, reserve cells, or use local avoidance; they may overlap and faster units may pass slower ones. Towers occupy fixed authored slots and never change graph connectivity. Presentation curves only visualize the graph. Core arrival produces exactly one ordered leak intent.

### Ratified M0.5 combat baseline

The detailed source is the [v0 combat vocabulary and initial counter matrix](PROJECT_PLAN.md#v0-combat-vocabulary-and-initial-counter-matrix). v0 uses deterministic direct damage, flat per-hit armor, armor penetration, cadence, positional splash, one refreshing non-stacking slow, and Support's non-stacking proximity Rally. It has no elemental matchups, hit/crit RNG, healing, shields, tower damage, or player-triggered unit abilities.

Swarm buys body count, Tank buys armored durability, Runner buys speed, and Support buys automatic formation speed. Rapid supplies cheap cleanup, Splash punishes density, Control answers speed and enables other towers, and Anti-armor answers per-target durability. Fixed targeting comparators and ordered intents make results reproducible. Initial numeric seeds, the 4x4 matrix, five encounters, and the dominance audit are review inputs rather than claims of final balance.

### Ratified M0.6 defender fairness baseline

The detailed source is the [v0 defender knowledge, fairness, and difficulty contract](PROJECT_PLAN.md#v0-defender-knowledge-fairness-and-difficulty-contract). The planner runs only during initial defense and post-wave adaptation, before the next player draft exists. It receives an immutable, value-only observation of public rules/content, its own state/economy, core/round context, and difficulty-permitted finalized history. It never receives live match state, current/future drafts, UI/input telemetry, current-wave entities, other RNG streams, or cross-match player data.

Initial defense plus 40-point adaptation grants use the same Place/Upgrade/Sell/Reserve commands and command gateway as scripted defense. Difficulty changes only completed-history age, integer scoring, candidate/action caps, reserve policy, and near-equal variation; economy, content stats, legality, and hidden-information access remain identical. Easy/Normal/Hard use 32/64/128 candidate caps, 4/6/8 action caps, 20%/10%/0% reserve intentions, and 15%/5%/0% variation bands respectively. Decision traces make observations, scores, bounded work, RNG choices, commands, and rejection reasons inspectable without affecting the result.

### Ratified M0.1 scope and capability trace

Human review accepted the combined M0.2 through M0.6 contracts on 2026-07-22. Together with the explicit non-goals below, they define one internally consistent v0 scope. Initial numeric balance values remain tunable through tests and play evidence; changing the economy shape, player agency, route model, combat vocabulary, AI information boundary, or milestone exit gates requires plan and board change control.

Every Must-priority board item maps to a required v0 capability or delivery gate:

| v0 capability or gate | Product source | Must board work |
| --- | --- | --- |
| Verified local Godot/Windows workflow | Local development environment contract | S0.1, S0.2, S0.3, S0.4 |
| One bounded adaptation-duel scope and explicit non-goals | This ratification plus `PROJECT_PLAN.md` | M0.1 through M0.6 |
| Headless, reproducible command/state/event foundation | Architecture plan and M0 rule contracts | M1.0 through M1.6 |
| Authored routes, leaks, targeting, combat archetypes and telemetry | M0.4 and M0.5 | M2.1 through M2.4 |
| Defense inspection, wave authoring, route commit, phases, playback, analysis and complete scripted match | M0.2 through M0.5 | M3.1 through M3.6 |
| Fair observation history, legal defense actions, bounded utility planning, visible adaptation and adversarial checks | M0.6 | M4.1 through M4.5 |
| Dominance search, adaptation-loop playtests, usability, stability/performance/settings, Windows build and exit decision | v0 outcome and milestone exit gates | M5.1 through M5.6 |

No Must item introduces multiplayer, services, freeform navigation, campaign/metaprogression, active unit control, machine-learned AI, expanded platforms, or other non-goals. Later/experimental board work remains Deferred and cannot become an implicit v0 dependency.

### Explicit non-goals

- Multiplayer, accounts, backend services, or cloud saves
- Freeform path drawing, tower-built mazes, or general navmesh movement
- Procedural maps or campaign generation
- Roguelite metaprogression
- Large content roster
- In-wave spells or direct unit micromanagement
- Machine-learned defender AI
- Final production art, narrative, audio, or accessibility certification
- Web, mobile, or console release

### Local development environment contract

Local setup is a first-class delivery phase, not an assumption hidden inside implementation work. Before gameplay implementation begins, the development machine must have a recorded and verified path for:

- A supported Godot 4.7.x editor and command-line executable
- Matching official Windows export templates
- PowerShell-based repository commands
- Git and repository-local conventions
- The chosen code editor and Godot language support, if used
- Headless project parsing and script execution
- Launching the project from the repository
- Exporting and launching a Windows build

Tool versions should be recorded. Optional editor integrations should remain optional. New third-party dependencies require explicit approval before installation or addition to the repository.

## 3. Research findings that shape the plan

### Use Godot as an application shell around a testable rules model

Godot 4.7 supports command-line scripts, headless execution, and automated export. This makes a simulation-first workflow possible without introducing a separate backend or custom engine. See the [Godot command-line documentation](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html).

The plan does not assume that scene-tree physics, navigation avoidance, or floating-point integration will be perfectly deterministic across every machine. Authoritative v0 movement should follow authored lane graphs with explicit rules and seeded randomness. Presentation may interpolate the resulting state.

### Avoid general-purpose navigation in v0

Godot navigation changes synchronize through the NavigationServer, and avoidance adds its own update and performance behavior. Dynamic obstacles are also not reliable constraints in crowded narrow spaces. Those capabilities are useful, but unnecessary for two authored routes. See [NavigationServer behavior](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationservers.html) and [navigation obstacle guidance](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationobstacles.html).

### Design for hundreds, not tens of thousands, of active objects

Godot's own guidance says a few hundred moving sprites generally do not require a data-oriented rewrite. v0 should establish an explicit performance envelope and measure it before considering ECS, GDExtension, or native code. See the [Godot FAQ](https://docs.godotengine.org/en/4.7/about/faq.html).

### Fix a base resolution early

The wave composer and inspection overlays are central to play. Godot recommends selecting one base resolution, handling aspect ratios deliberately, and using anchored/container-based UI. The v0 target will be defined during foundation work, with 1280x720 as the initial candidate. See [Godot's resolution guidance](https://docs.godotengine.org/en/4.7/about/faq.html#how-should-assets-be-created-to-handle-multiple-resolutions-and-aspect-ratios).

### AI quality depends on its contract, not its complexity

The first AI should be a budgeted utility planner with observable inputs and diagnostics. It must not see the wave currently being composed. More expensive lookahead or sampled simulations are optimization options after a legal, understandable heuristic defender works.

### The detailed architecture uses Godot without making the scene tree authoritative

The [v0 detailed architecture plan](V0_ARCHITECTURE_PLAN.md) defines a fixed-tick `RefCounted` rules core with integer authority, validated commands, ordered events, read-only presentation snapshots, and compact results. Custom Godot resources hold immutable definitions; match-owned runtime state remains separate because loaded resources are cached and shared.

Godot scenes are used where the engine is strongest: composition, UI, rendering, audio, input, and visual reuse. A shallow application coordinator owns the match lifecycle, but combat legality and resolution remain callable headlessly without a battlefield scene.

### The initial test path should not mistake Godot's engine tests for project tests

Godot supports `--headless --script`, but its built-in `--test` facility is for engine builds and engine/GDScript implementation tests, not ordinary user-project scripts. M1.2 therefore starts by proving a small dependency-free project test runner with a nonzero failure exit. A maintained add-on is considered only if that runner's diagnostics or ergonomics are inadequate, and adding one still requires explicit approval.

## 4. Original proposal

The initial proposal divided work into five broad stages: define the game, build the simulation foundation, build the wave composer, add the adaptive defender, and balance the vertical slice.

That direction was sound but not sufficiently executable. It left several hidden problems:

- The MVP outcome was described but not contractually bounded.
- Simulation, presentation, and Godot physics authority were not distinguished precisely enough.
- The AI could become a critical-path dependency before the player loop was validated.
- No explicit performance envelope or scale test existed.
- “Understand why a wave failed” lacked measurable evidence.
- A technically complete build could pass without demonstrating a useful adaptation loop.
- Architecture decisions and dependency choices could be buried inside implementation tickets.

## 5. Red-team findings and changes

### Finding 1 — The plan could build a simulator before proving a game

Change: establish product decisions first, then build a fixed-defense end-to-end match before adaptive AI. Every milestone must end in something observable or playable.

### Finding 2 — AI was both the novelty and the largest schedule risk

Change: split AI into an explicit knowledge contract, legal action generation, scoring, adaptation, and fairness verification. The fixed-defense loop remains playable even if AI development is delayed.

### Finding 3 — “Deterministic” was too broad

Change: require reproducible seeded rule scenarios and stable event results within the supported build. Do not require cross-platform bitwise physics determinism. Lane progress is authoritative; visual motion is presentation.

### Finding 4 — Navigation could swallow the MVP

Change: use an authored lane graph with two routes and one chokepoint. No freeform route creation, dynamic navmesh rebuilding, or local avoidance is required.

### Finding 5 — Four units and four towers can still create shallow counter matching

Change: define a combat vocabulary and counter matrix before implementing content. Each archetype must differ along at least two dimensions such as durability, count, speed, spacing, targeting pressure, or support behavior.

### Finding 6 — Automated tests cannot prove the adaptation loop is enjoyable

Change: add structured playtest gates. v0 requires observed evidence that players can identify a failure cause and form a next-wave hypothesis. Balance simulation supplements rather than replaces playtesting.

### Finding 7 — UI and explanation were scheduled too late

Change: defense inspection, playback control, and event telemetry are built alongside the first playable match. Post-wave analysis is not deferred polish.

### Finding 8 — A task board could imply false certainty

Change: early board groups contain explicit decisions and spikes. Downstream tasks remain Backlog until their inputs and testable acceptance criteria are confirmed. The board is a revisable skeleton, not a promise that all current implementation details are final.

## 6. Revised milestone plan

### S0 — Local environment and tooling

Purpose: prove that the selected technology stack works on the actual development machine before gameplay implementation depends on it.

Outputs:

- Workstation and installed-tool inventory
- Pinned Godot 4.7.x and export-template policy
- Godot command-line availability and editor integration
- Minimal repository scaffold and local PowerShell run commands
- Headless parse/script smoke check
- Windows export and launch smoke check
- Documented dependency-installation and troubleshooting notes

Exit gate: from the repository root, documented commands can identify the pinned Godot version, launch the minimal project, run a headless smoke check, export a Windows build, and launch that build on the development machine.

S0 may proceed alongside product-design work, but gameplay implementation cannot begin until the relevant setup tasks are complete.

### M0 — Product contract

Purpose: remove the design ambiguities that would materially change architecture or scope.

Outputs:

- v0 contract and non-goals
- Match, economy, and victory rules
- Wave-authoring verbs and in-wave agency decision
- Map and route contract
- Combat vocabulary and initial counter matrix
- AI knowledge, fairness, and difficulty contract

Exit gate: a complete five-round match can be specified without unstated rules, and every v0 feature maps to the core adaptation-loop hypothesis.

### M1 — Architecture and runnable foundation

Purpose: create the smallest Godot foundation that supports rapid, reproducible iteration.

Outputs:

- Godot project and Windows-first development workflow
- Detailed architecture baseline plus ADRs for simulation authority, content resources, test harness, and replay compatibility
- Test-harness decision and headless checks
- Seeded state, command, event, and result model
- Data-driven unit, tower, and map definitions
- Snapshot/presenter seam and explicit match composition root
- Versioned diagnostic scenario/replay format with rules and content compatibility checks
- Automated Windows debug/release export check
- Developer diagnostics and documented run commands

Exit gate: one command runs verification, a minimal scenario executes headlessly without presentation nodes, the same state produces a reconciled placeholder view, incompatible diagnostic replays fail clearly, and a Windows build launches.

M1.0 ratified the detailed architecture baseline on 2026-07-22. The remaining M1 items own the focused ADRs and executable evidence for simulation authority, the test harness, runtime primitives, content schemas, diagnostics/replay, the composition root, and the complete Windows verification gate.

M1 progress on 2026-07-22:

- M1.0 ratified the architecture baseline and recorded the follow-up decision map.
- M1.1 accepted ADR-0001 and proved headless phase authority, stable tie order, named RNG isolation, and the simulation dependency boundary.
- M1.2 retained a dependency-free project test runner after pass, filter, readable-diagnostic, timing, and nonzero-failure proofs.
- M1.3 established seeded match state, validated phase commands with structured rejection codes, tick-plus-ordinal events, copied views, JSON result summaries, centralized integer math, monotonic entity IDs, and match-instance isolation.

M1 remains open for content schemas, the expanded verification/diagnostic workflow, the composition/presenter seam, and versioned diagnostic replay contracts.

### M2 — Fixed-defense combat slice

Purpose: prove the core simulation and readable combat before introducing adaptive AI.

Outputs:

- Authored lane-graph movement
- Tower targeting and attack resolution
- Unit durability, leaks, support behavior, and death
- Four unit and four tower archetype definitions
- Fixed-step seeded scenario coverage
- Performance envelope and stress scenario
- Basic battlefield rendering and combat telemetry

Exit gate: a committed wave resolves reproducibly against a fixed defense, produces an inspectable event summary, and stays within the agreed performance budget.

### M3 — Player-authored match

Purpose: validate the player experience against a fixed or scripted defense.

Outputs:

- Defense inspection and threat visualization
- Wave composition, order, spacing, budget, and route controls
- Input validation and commit flow
- Match phase state machine
- Pause and playback speeds
- Post-wave analysis
- Five-round economy, win/loss, and restart flow using a scripted defense

Exit gate: a player can complete a five-round match and explain the primary reason each wave succeeded or failed.

### M4 — Adaptive defender

Purpose: make the defense side responsive while preserving fairness and explainability.

Outputs:

- Observation history limited by the AI contract
- Legal build and upgrade action generation
- Budgeted utility scoring and action selection
- At least one visible adaptation to prior-wave behavior
- AI decision diagnostics
- Fairness, legality, and repeatability tests

Exit gate: the AI completes multiple matches without illegal actions or forbidden knowledge, and its major adaptations can be explained from recorded inputs and scores.

### M5 — v0 validation and release

Purpose: determine whether the adaptation duel works well enough to justify further development.

Outputs:

- Balance matrix and dominant-strategy search
- Structured playtest protocol and findings
- Usability fixes for inspection, wave authoring, and failure explanation
- Performance and stability pass
- Local save/settings scope required for a usable build
- Versioned Windows build and release notes
- v0 exit review against the product hypothesis

Exit gate: the build satisfies the v0 definition, no known Must-severity defect blocks a full match, and playtest evidence supports either continuing, revising, or stopping the concept.

## 7. Verification strategy

Completion evidence is layered:

- **Rule tests:** targeting, timing, budgets, damage, status effects, route assignment, victory, and failure behavior
- **Seeded scenario tests:** stable commands produce the expected event and result summaries
- **AI contract tests:** no forbidden observations, illegal actions, overspending, invalid placements, or nonterminating planning
- **Integration tests:** full phase progression from defense reveal through post-wave analysis
- **Performance checks:** agreed unit/tower scale, simulation time, and frame-time targets on the development machine
- **Visual/manual checks:** ranges, routes, overlays, playback speeds, resolution behavior, and Windows build launch
- **Playtests:** the player can identify a failure cause, form a counter-plan, and understand a visible AI adaptation

Compilation alone is never sufficient completion evidence.

## 8. monday.com board model

The board should reuse the useful execution fields from the Audio Tag Catalog project:

- Status: Backlog, Ready, In Progress, Review, Blocked, Done, Deferred
- Priority: Must, Should, Could, Later
- Area: Product, Game Design, Architecture, Simulation, AI, UX, Content, DevEx, Quality, Release
- Work Type: Decision, Spike, Feature, Test, Chore, Documentation, Epic
- AI Mode: Human Design, Pairing, AI Draft, Verification Heavy
- Estimate: relative focused work sessions, not calendar time
- Acceptance Criteria: observable completion contract
- AI Brief: bounded implementation or investigation context
- Verification Evidence: proof required to mark Done
- Blocked By: explicit dependencies

Board groups mirror S0 and M0 through M5, plus an intake group and a Later/Experiments group. Only dependency-free items with testable acceptance criteria should be moved to Ready.

## 9. Change control

This plan should change when design rounds resolve open questions or play evidence disproves an assumption.

Changes that alter the v0 contract, authoritative simulation model, AI knowledge boundary, dependency policy, or milestone exit gates should be recorded in the repository plan and reflected on the monday.com board before implementation proceeds.
