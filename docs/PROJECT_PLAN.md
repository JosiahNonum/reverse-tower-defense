# Reverse Tower Defense — Living Project Plan

Status: Discovery and pre-production  
Last updated: 2026-07-21

Execution planning is tracked in [V0_MVP_DEVELOPMENT_PLAN.md](V0_MVP_DEVELOPMENT_PLAN.md).

## 1. Purpose of this document

This document records the current direction for the reverse tower defense project. It is a living plan, not a final specification. Architecture, scope, terminology, and gameplay rules are expected to change as the project is developed through additional design rounds.

The immediate goal is to preserve the initial premise and the recommended path forward without prematurely locking down details that still need exploration.

## 2. Core premise

The game is a single-player reverse tower defense game:

- The AI creates and evolves the tower defenses.
- The player creates the attacking waves.
- The player studies the visible defense, composes a wave, and watches that plan resolve against the AI's plan.
- The AI adapts between rounds based on information it could legitimately have observed.

The central experience should feel like an ongoing strategic conversation between two asymmetric designers: the player designs attacks and the AI designs defenses.

## 3. Current product direction

The recommended starting form is a 2D, top-down, round-based **adaptation duel**.

A provisional match loop is:

1. The AI spends a defense budget on towers, upgrades, or other defensive changes.
2. The updated defense is revealed to the player.
3. The player receives an attack budget and composes the next wave.
4. The player commits the wave.
5. The wave resolves, primarily through automatic simulation.
6. The game explains the result and records what the AI was able to observe.
7. The AI uses that history when preparing the next defense round.

A match would likely last a limited number of rounds. The player wins by breaching the defended objective, delivering enough units to an exit, exhausting the defense, or completing a mission-specific objective before the match ends. The exact victory model remains open.

### Core fairness rule

The AI may react to prior waves, but it should not inspect the uncommitted wave the player is currently creating.

This rule is intended to prevent perfect hidden-information counters. The AI should feel intelligent because it recognizes patterns, plans well, and adapts—not because it cheats.

## 4. Player experience goals

The game should make the player feel like a strategist and wave designer rather than a passive unit purchaser.

The first version of wave composition should explore:

- Unit composition
- Deployment order
- Timing, delays, and spacing
- Route or lane selection
- Limited formation choices
- A shared wave or command-point budget
- One or more limited support effects
- Clear path, range, and threat previews

After a failed wave, the player should be able to understand what happened and immediately form a new hypothesis for the next wave.

The primary early validation question is:

> After seeing why a wave failed and how the AI changed its defense, does the player immediately want to compose another wave?

## 5. Provisional design principles

### Readability over spectacle

The interaction between units, towers, paths, and timing must remain understandable. Playback speed controls, pause, inspection, tower ranges, threat overlays, and post-wave analysis are core features rather than optional polish.

### Adaptation without hard counters

Units and towers should have positional, timing, and behavioral identities in addition to conventional damage strengths and weaknesses. The strategy should not collapse into matching one unit color to one tower color.

### Decisions before content volume

A small set of mechanically distinct units and towers is preferable to a large shallow roster. Early development should prove that the basic decision loop is interesting before adding campaign progression, extensive content, or metagame systems.

### Reproducible simulation

Matches should use seeded randomness, stable identifiers, and serializable commands where practical. Reproducible outcomes will support testing, replays, debugging, AI evaluation, and future seeded challenges.

### Honest AI

The AI's knowledge, available actions, budget, and decision timing should be explicitly defined. Difficulty should primarily affect planning quality, adaptation speed, budget pressure, and controlled error—not secret information or unexplained stat inflation.

## 6. Recommended technology direction

### Engine

Use **Godot 4.7 with GDScript** for the initial project.

Reasons for this recommendation:

- Strong dedicated 2D workflow
- Fast edit-run iteration
- Suitable scene and node model for a top-down strategy game
- Free and open-source MIT licensing
- Straightforward Windows builds
- A possible web-demo path if it becomes valuable
- Headless execution for simulation and automated verification
- Less infrastructure overhead than building a game around a web application stack

This decision remains provisional until the first architecture round confirms that Godot supports the desired simulation and testing boundaries cleanly.

### Initial platform

- Primary development and first release target: Windows desktop
- Input: mouse and keyboard first
- Offline, local-first, and single-player
- No account, server, or required network connection

### Persistence

Use simple, versioned local save data initially. Do not introduce a database or backend until a concrete feature requires one.

## 7. Architecture direction

The proposed v0 baseline is specified in [V0 Detailed Architecture Plan](V0_ARCHITECTURE_PLAN.md). It is ready for review, but values coupled to unfinished M0 game-design decisions remain provisional.

The simulation should be separated from presentation as much as is practical within Godot. In concrete terms, authoritative rules run in typed `RefCounted` state and systems rather than rendered scenes or physics nodes. Godot scenes present snapshots and events; they do not decide combat outcomes.

Provisional boundaries:

```text
Game application
├── Simulation
│   ├── Map and lane graph
│   ├── Units, towers, projectiles, and effects
│   ├── Economy and round rules
│   ├── Seeded random number generation
│   └── Commands, events, and results
├── Defender AI
│   ├── Knowledge and observation model
│   ├── Legal action generation
│   ├── Threat analysis
│   ├── Placement and upgrade evaluation
│   └── Difficulty and personality profiles
├── Content
│   ├── Unit definitions
│   ├── Tower definitions
│   ├── Maps and missions
│   └── Balance values
├── Presentation
│   ├── Visual entities and animation
│   ├── Audio and effects
│   └── Camera
└── Interface
    ├── Wave composer
    ├── Defense and threat inspection
    ├── Playback controls
    └── Post-wave analysis
```

Desired properties of the simulation boundary:

- Can run without relying on rendered scenes where feasible
- Uses a fixed simulation step
- Produces inspectable events and results
- Supports deterministic or reproducible test scenarios
- Keeps balance data outside deeply embedded presentation code
- Allows the same scenario to be simulated repeatedly for AI and balance testing

The architecture round recommends:

- A fixed-tick simulation using integer ticks, health, damage, economy, cooldowns, IDs, lane progress, and logical coordinates
- Validated commands as the only route into authoritative mutation
- Ordered domain events, read-only presentation snapshots, and compact wave/match results as outputs
- Custom Godot `Resource` files for immutable content definitions, with separate match-owned runtime state
- A shallow scene tree coordinated by an explicit match composition root; no globally reachable match-state autoload
- An authored lane graph and fixed build slots, with presentation deriving visual positions from logical progress
- A fairness-filtered defender observation followed by bounded candidate generation, utility scoring, selection, and an inspectable decision trace
- Versioned JSON for settings and diagnostic scenario/replay artifacts, guarded by rules version and content fingerprint
- A dependency-free headless project test runner as the first option, subject to the M1.2 spike

Provisional working values are 20 simulation ticks per second, 1,000 logical position units per map unit, a 1280x720 base resolution, and a rendered stress target of 300 active units plus 100 towers. These are measurement starting points rather than product promises.

## 8. Defender AI direction

Begin with a transparent, budgeted utility AI rather than machine learning.

A provisional decision process is:

1. Analyze the map, current defense, economy, and previously observed waves.
2. Generate legal placement, upgrade, sale, and reserve actions.
3. Score candidate actions for factors such as coverage, expected damage, leak risk, synergy, vulnerability, and future flexibility.
4. Select a set of actions within the available budget.
5. Apply controlled variation so repeated situations do not always create identical defenses.

Potential defender personalities include:

- A generalist that values broad coverage
- An engineer that builds synergistic clusters
- A warden that emphasizes slowing and control
- An analyst that reacts strongly to recent player patterns
- A gambler that creates powerful but exploitable kill zones

Later iterations may allow the AI to test candidate defenses against a sample of plausible waves. Machine learning may eventually help with automated balance testing, but it is not required for the first player-facing AI.

## 9. First playable vertical slice

The first vertical slice should be deliberately small:

- One top-down map
- Two routes with at least one shared chokepoint
- Four player unit archetypes
  - Swarm
  - Tank
  - Runner
  - Support
- Four defender tower archetypes
  - Rapid single-target
  - Area or splash damage
  - Slow or control
  - Anti-armor
- Five rounds
- A simple attack and defense economy
- Wave order and spacing controls
- Visible paths, tower ranges, and a basic threat overlay
- One deterministic defender AI profile
- Pause and multiple playback speeds
- A basic post-wave report showing damage and failure locations
- Placeholder geometric or icon-based visuals
- Automated simulation scenarios for core combat interactions

### Vertical-slice success criteria

The slice is successful when:

- A player can complete a full match without developer intervention.
- The player makes meaningful choices about composition, order, spacing, or route.
- The AI creates valid defenses and adapts to at least one observable player pattern.
- The player can explain the main reason a wave succeeded or failed.
- Replaying the same committed scenario with the same seed produces the expected result.
- There is no single wave composition that trivially solves every defense in the slice.
- The game can be launched and verified through a documented local workflow.

## 10. Development stages

### Setup — Local environment and tooling

- Inventory the development workstation and existing tools.
- Install and pin the selected Godot 4.7.x editor and matching export templates.
- Verify command-line, headless, project-launch, and Windows-export workflows.
- Establish repository-local PowerShell commands and troubleshooting notes.
- Record optional editor integration separately from required tooling.
- Require approval before adding third-party development or runtime dependencies.

Exit condition: the minimal project can be launched, checked headlessly, exported, and run on the local Windows machine using documented repository-root commands.

### Stage 0 — Define the game

- Refine the core loop and match structure.
- Define the player's wave-authoring verbs.
- Define the AI's information and fairness rules.
- Decide map topology, path control, victory conditions, and economy shape.
- Record an initial product scope and explicit non-goals.

Exit condition: the first vertical slice can be specified without relying on unstated design assumptions.

### Stage 1 — Simulation foundation

- Create the Godot project and repository conventions.
- Implement the minimal map, unit, tower, targeting, damage, and round models.
- Establish seeded scenarios and automated checks.
- Verify that simulation logic is sufficiently separated from presentation.

Exit condition: a headless or minimally rendered scenario can produce a reproducible combat result.

### Stage 2 — Playable wave composer

- Build the map presentation and inspection tools.
- Add wave composition, ordering, timing, and commit flow.
- Add playback controls and result feedback.
- Complete an end-to-end match against a fixed valid defense.

Exit condition: the player can author and evaluate waves through the actual game interface.

### Stage 3 — Adaptive defender

- Implement defense action generation and utility scoring.
- Define the AI observation history.
- Add at least one visible adaptation behavior.
- Add AI diagnostics so decisions can be inspected during development.

Exit condition: the AI constructs a valid, understandable defense over multiple rounds without using forbidden information.

### Stage 4 — Vertical-slice balance and usability

- Tune the initial units, towers, economy, and round pacing.
- Improve threat communication and post-wave analysis.
- Add basic sound and visual feedback.
- Run repeated simulation and hands-on playtesting.

Exit condition: the adaptation loop is understandable and produces a desire to retry or counter-adapt.

### Later stages — To be authorized by validated play

Possible later work includes additional maps, campaigns, defender personalities, roguelite drafting, progression, modifiers, daily seeds, replays, community challenges, controller support, and broader platform releases. None of these are part of the initial commitment.

## 11. Initial non-goals

Unless later design work changes them, the following are outside the first vertical slice:

- Multiplayer or networking
- Accounts or cloud services
- A backend API or external database
- Console or mobile releases
- Freeform tower maze construction
- Large campaign or narrative systems
- Procedurally generated maps
- Roguelite metaprogression
- User-generated content tools
- Machine-learned player-facing AI
- Final art, animation, or audio production
- A large roster of units or towers

## 12. Major risks and questions

### Design risks

- The AI may feel unfair if its knowledge boundary is unclear.
- The AI may feel trivial if its adaptation is too slow or predictable.
- Wave composition may become a spreadsheet-like counter-matching exercise.
- Automatic resolution may feel passive without enough authorship or feedback.
- Too much unit and tower content may make balance combinatorial before the core loop is proven.
- Flexible pathing or maze construction may create costly navigation and exploit problems.

### Technical risks

- Presentation code may become too tightly coupled to simulation state.
- Godot physics or navigation behavior may make exact reproducibility difficult if used as the authoritative rules layer.
- Large unit counts may require a simpler movement and collision model than general-purpose character nodes.
- AI evaluation may become expensive if candidate defenses are tested through full simulations.

### Open product questions

- What exactly constitutes creating a wave?
- Does the player choose routes per unit, per group, or per wave?
- Can the player intervene after committing a wave?
- Does the AI build before every wave, after every wave, or both?
- What information about future AI construction is visible?
- What is the match victory condition?
- How are attack and defense budgets generated?
- Are surviving units persistent, refunded, or consumed?
- Can towers be destroyed, disabled, bypassed, or only endured?
- Should the tone be fantasy villainy, science fiction, abstraction, or something else?
- Is the long-term structure a campaign, roguelite run, puzzle set, sandbox, or hybrid?

## 13. Recommended next design rounds

The next planning conversations should address these topics approximately in order:

1. **Player verbs and match loop** — precisely define what the player can do before and during a wave.
2. **Map and path model** — fixed lanes, branching graph, player-routed paths, and interaction with towers.
3. **Economy and victory model** — budgets, rewards, attrition, escalation, and match length.
4. **Combat vocabulary** — initial unit and tower identities, targeting, status effects, and counters.
5. **AI contract** — observations, memory, actions, decision timing, personalities, and difficulty.
6. **Simulation architecture** — authoritative state, timestep, commands, events, determinism, and tests.
7. **Vertical-slice scope** — convert the refined design into concrete milestones and acceptance criteria.
8. **Presentation direction** — visual perspective, theme, tone, interface, and information design.

## 14. Reference points

Existing games worth studying during design:

- [Anomaly: Warzone Earth](https://store.steampowered.com/app/91200/) — route planning, squad composition, and active support in a tower-offense structure
- [Tower Escape](https://store.steampowered.com/app/2009860/Tower_Escape/) — wave-as-party design, path planning, threat visualization, and roguelite variation
- [Countless Army](https://store.steampowered.com/app/2413640/Countless_Army/) — troop order, routes, support powers, and campaign progression
- [BYTES: The Reverse Tower Defense](https://store.steampowered.com/app/2348350/BYTES_The_Reverse_Tower_Defense/) — editable waves and a defender AI that purchases and upgrades towers

These are reference points rather than templates. The project's intended identity is the repeated, fair adaptation duel between a player-authored wave and an AI-authored defense.
