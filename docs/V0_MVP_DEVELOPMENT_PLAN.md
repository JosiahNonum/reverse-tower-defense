# v0 MVP Development Plan

Status: Proposed execution plan, red-team revised  
Last updated: 2026-07-21  
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
