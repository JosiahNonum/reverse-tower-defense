# Reverse Tower Defense — Living Project Plan

Status: M0 product contract ratified; M1 architecture review next
Last updated: 2026-07-22

Execution planning is tracked in [V0_MVP_DEVELOPMENT_PLAN.md](V0_MVP_DEVELOPMENT_PLAN.md).

## 1. Purpose of this document

This document records the ratified v0 product direction for the reverse tower defense project. It remains a living plan: balance values may change through verified tuning, while changes to scope, rules shape, or fairness boundaries follow the documented change-control process.

M0 fixes the product contract needed for architecture and implementation. Theme, presentation detail, and evidence-driven balance tuning remain open where they do not silently change that contract.

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

A v0 match lasts exactly five rounds. The player wins by reducing the core from 10 integrity to 0 through leaks before or during round five. The defender wins if the core has any integrity after the final committed wave resolves. There is no draw state. The detailed phase, budget, terminal-state, and restart rules are recorded below.

### v0 match, economy, and outcome contract

This contract is the baseline for M0.2. Numeric values are initial balance values, not promises that tuning can never change; changing the economy shape or outcome rules requires product-plan and board review.

#### Match phases

Each match uses one root seed, one map, one rules definition, and five numbered rounds.

1. **Initial defense:** before round 1, the defender receives its initial budget and submits legal defense actions.
2. **Defense reveal:** the resulting defense, remaining defender reserve, tower ranges, and routes are visible to the player.
3. **Wave authoring:** the player receives that round's attack budget and may edit a wave until it is valid.
4. **Commit:** committing freezes the normalized wave plan and spends its unit costs. The defender cannot act or inspect the draft during authoring or after commit.
5. **Resolution:** the committed wave runs automatically. Pause and playback speed change presentation pacing, not rules or tick size.
6. **Analysis:** the game reports damage, deaths, leaks, core integrity, and important failure locations. The player may inspect but not alter the resolved result.
7. **Transition:** if the core is intact and fewer than five rounds have resolved, the defender receives the next adaptation grant, may take legal defense actions, and reveals the revised defense before the next authoring phase. Otherwise the match ends.

The initial defense and each between-round adaptation use the same validated defense-command boundary. No tower may be placed, upgraded, sold, or reserved during wave resolution.

#### Attack economy

The attack budget schedule is **100, 120, 140, 160, and 180** points for rounds 1 through 5.

- Each round's attack budget is fresh; unspent attack points do not carry to another round.
- Adding, removing, reordering, spacing, or rerouting draft entries is free. Costs are checked against the current draft and are spent only on commit.
- A committed wave is consumed whether its units die or leak. Units never persist into another round and receive no refund.
- The player receives no kill, damage, survival, or leak reward. Later-round escalation comes only from the published schedule.
- Commit requires at least one unit, total cost at or below budget, valid route assignments, and valid spacing/order data. The UI must explain every rejection without mutating authoritative match state.

#### Defense economy

The defender receives **120** points before round 1 and **40** additional points before each of rounds 2 through 5.

- Towers and upgrades persist until sold or the match ends.
- Unspent defense points carry as an explicit reserve with no cap or interest.
- Selling is legal only during initial defense or adaptation and refunds **75% of the item's total invested cost, rounded down**. A sale and replacement must still pass the normal legality and affordability checks.
- The defender receives no reward for kills, remaining core integrity, prevented leaks, or player spending.
- Defense costs, upgrades, slots, and sale value are fully visible to the player. Difficulty cannot change the budget schedule, refund rate, or tower prices.

This asymmetry is intentional: the player gets a clean wave-design problem each round, while the defender's persistent layout makes its adaptation history visible and creates a reason to reserve or replace defenses.

#### Resolution and terminal rules

- The core starts a match at **10 integrity** and never heals in v0.
- A unit that reaches the core leaks exactly once, is removed from play, and deals its integer `leak_damage` from the unit definition. M0.5 assigns the four archetypes' values.
- A wave ends when every committed entry has spawned and every spawned unit has either died or leaked, with no unresolved authoritative damage or status intent remaining.
- If a leak reduces core integrity to 0, resolution completes that tick's already-staged intents in the documented stable order, then the match ends immediately as a player win. Core integrity is clamped at 0.
- If round 5 ends with core integrity above 0, the match ends as a defender win. Partial damage, unused budget, units killed, and remaining towers are analysis facts, not tie-break scores.
- There is no draw. The player wins exactly when the core is breached; otherwise the defender wins after round 5.
- An impossible-to-resolve state, invalid content, or internal rules failure is an error result, never silently converted into a win or loss.

#### Restart and replay

`RestartMatch` is available from analysis and match end. It discards all runtime state, drafts, observations, reserves, towers, events, and results, then recreates round 1 from the same rules, content fingerprint, map, defender profile, and root seed. It does not reuse mutable objects. Starting a new match may choose a new seed.

A restart is therefore a clean replay opportunity, not a rewind. Diagnostic replay uses committed commands and the compatibility rules in the architecture plan.

#### Worked round example

| Round | Player attack budget and plan | Defender funds and action | Result and next state |
| --- | --- | --- | --- |
| 1 | 100 available; commits a 96-point mixed wave | 120 initial; spends 100 and reserves 20 | Two units leak for 2 total damage; core 8; committed units are consumed |
| 2 | Fresh 120; commits all 120 after seeing the revealed defense | Reserve 20 + grant 40 = 60; spends 45 and reserves 15 | No leaks; core remains 8; no kill reward is created |
| 3 | Fresh 140; commits 132 and leaves 8 unspent | Reserve 15 + grant 40 = 55; sells 40 invested points for 30, then has 85 to adapt | Leaks deal 3; core 5; the player's unused 8 expires |

Rounds 4 and 5 follow the same rules. If round 5 deals the remaining 5 core damage, the player wins; if it deals 4 or less, the defender wins.

#### Edge cases

| Case | Required result |
| --- | --- |
| Empty or over-budget draft | Commit rejected with structured reasons; authoring continues |
| Player commits below budget | Legal; unused attack points expire after commit |
| Defender takes no action | Legal; all available points remain reserved |
| Defender cannot afford any action | Legal reserve action; reveal still occurs |
| Sale refund is fractional | Multiply invested integer cost by 75, divide by 100, round down |
| Multiple units reach the core on one tick | Resolve arrivals in stable entity-ID order; each unit leaks at most once |
| Core reaches 0 before later same-tick arrivals | Complete already-staged intents in stable order, clamp integrity to 0, then end the match |
| Final wave has no leaks | Defender wins if core integrity remains above 0 |
| Pause or playback speed changes | No budget, command order, tick size, event order, or result changes |
| Restart after any outcome | New runtime graph with the same seed and initial contract; no prior reserve, damage, or AI memory remains |

### v0 wave-authoring and committed-agency contract

This contract is the baseline for M0.3. The wave composer authors a complete spawn schedule before resolution; it is not a real-time unit-command interface.

#### Draft model

A draft is an ordered list of individual wave entries. Each entry contains:

- a stable draft-entry ID used only while editing;
- one unit archetype;
- one valid authored route;
- a spacing preset that controls the delay after the preceding entry; and
- its visible integer cost from the content catalog.

The first entry always spawns at wave tick 0. Later entries use one of three v0 spacing presets: **Tight = 5 ticks**, **Standard = 15 ticks**, or **Wide = 30 ticks**. At the provisional 20 Hz tick rate these represent 0.25, 0.75, and 1.5 seconds. If the tick rate changes during architecture review, the tick counts remain authoritative and the displayed seconds update.

Spacing belongs to each transition in the ordered schedule, not to physical collision distance or a persistent formation. M0.4 defines how same-route occupancy and branch/merge behavior resolve after spawn.

#### Authoring verbs

During `WAVE_AUTHORING`, the player may:

- add one or a chosen quantity of any unlocked v0 unit, producing individual entries;
- remove selected entries;
- duplicate selected entries when the result remains within the entry limit;
- reorder entries with drag/drop or keyboard move commands;
- assign or batch-assign a valid route to selected entries;
- assign or batch-assign Tight, Standard, or Wide spacing;
- undo and redo draft edits through the current authoring session;
- clear the draft;
- copy the previous committed wave into the new round as an editable starting point; and
- commit when the complete draft is valid.

Copying a prior wave copies only its normalized unit, order, spacing, and route data. It does not copy spent budget or authoritative runtime IDs, and the copied draft must pass the current round's budget and content validation.

The composer supports multi-select and quantity add as editing conveniences, but commit expands everything into an ordered list of individual entries. A v0 wave contains at most **300 entries**, matching the initial measured simulation envelope rather than promising that a 300-unit wave is affordable or balanced.

#### Feedback and validation

The composer continuously shows total cost, round budget, remaining points, entry count, unit/order timeline, route, and spacing. Invalid entries receive row-level reasons and the commit area shows a concise issue summary.

Commit is an atomic request. It is accepted only when:

- the phase is `WAVE_AUTHORING`;
- the list has 1 through 300 entries;
- every unit ID exists and is permitted by the match rules;
- every route ID exists and is legal for that unit under M0.4;
- every spacing value is one of the three permitted tick counts;
- the normalized total cost is at or below the current attack budget; and
- the command's expected round and rules/content identity match the live match.

On rejection, the authoritative match and attack budget are unchanged, the draft remains editable, and structured error codes identify all independently detectable problems. The UI never silently drops an entry, changes a route, substitutes a unit, or auto-spends the remaining budget.

On acceptance, the simulation stores a normalized immutable `CommittedWave`, spends the exact total cost once, clears undo/redo history, and transitions to `WAVE_COMMITTED`. Draft gestures are not authoritative commands and are not included in diagnostic replay.

#### Agency after commit

After commit, the player cannot add, remove, reorder, reroute, retime, target, steer, activate abilities, or cancel individual units. v0 provides only:

- pause and resume;
- 1x, 2x, and 4x playback request rates;
- camera movement and zoom;
- inspection of visible units, towers, routes, ranges, and current telemetry; and
- abandoning the match and returning to the menu through an explicit confirmation flow, never as a way to revise the current result. `RestartMatch` remains available only from analysis or match end as defined by M0.2.

Pause and playback commands affect how the application requests fixed simulation ticks. They do not alter the committed schedule, command order, cooldowns, or result.

During analysis, the committed wave and its result remain read-only. The next round begins with an empty draft unless the player explicitly chooses **Copy previous wave**.

#### Composer walkthroughs

The totals in this UI sketch are illustrative only; M0.5 owns final unit costs.

```text
Round 2 - Attack 116 / 120                       Commit [enabled]

Order  Unit       Route   Gap after previous
1      Tank       North   First: tick 0
2      Support    North   Tight: 5 ticks
3      Runner     South   Wide: 30 ticks
4      Runner     South   Tight: 5 ticks

[Add units] [Duplicate] [Move up/down] [Set route] [Set spacing]
[Undo] [Redo] [Clear] [Copy previous wave]
```

Walkthrough A—split pressure: the player batch-adds two runners, assigns South, adds a tank and support on North, reorders the tank first, and uses a Wide gap before the first runner. The 126-point draft is marked over budget; removing one runner lowers it to 116, clears the row/summary error, and enables commit. The accepted command preserves the visible order and routes exactly.

Walkthrough B—dense bait and follow-up: in a later round the player copies the prior committed wave, removes the tank, batch-adds swarm entries, assigns Tight spacing to the swarm sequence, moves support behind them, and routes a Wide-spaced runner to the other branch. Duplicating the swarm once too often creates a visible budget error; undo restores the last valid draft and enables commit. During resolution the player may pause and inspect why the bait failed, but cannot redirect the runner or trigger the support unit.

#### Authoring edge cases

| Case | Required result |
| --- | --- |
| Quantity add would exceed 300 entries | Edit rejected before partial insertion; existing draft is unchanged |
| Reorder or batch edit is undone | One user action is restored atomically, including prior selection-independent values |
| Copied wave exceeds the new budget | Copy succeeds as an editable invalid draft; commit identifies the budget excess |
| Content or rules changes between draft and commit | Commit rejected for identity mismatch; no automatic substitution |
| Two entries use the same spawn tick on different routes | Not possible through v0 spacing presets; every later entry has a positive scheduled gap |
| Pause occurs before a scheduled spawn | Simulation tick does not advance, so the spawn schedule does not advance |
| Playback changes from 1x to 4x | The same fixed ticks and ordered spawns occur; only wall-clock presentation rate changes |
| Player attempts a unit command during resolution | Rejected as unavailable in the current phase; committed state is unchanged |

### v0 authored lane and route contract

This contract is the baseline for M0.4. The v0 map is a fixed directed lane graph, not a navigation mesh, player-drawn path, or tower-created maze.

#### Topology and authored routes

The map contains one spawn, one shared approach, one branch, two distinct branch corridors, one merge, one shared chokepoint, and one core. It publishes exactly two route IDs, `route.north` and `route.south`. A route is an immutable ordered list of directed edge IDs from the spawn node to the core node.

```text
                                               [T-N1]   [T-N2]
                                                  \       /
                                                   N1 -> N2
                                                 /          \
[SPAWN] S -> A [T-A] -> B [BRANCH]              /            M -> C [CHOKE] -> G [CORE]
                                                 \          /     [T-C1] [T-C2]
                                                   S1 -> S2
                                                  /       \
                                               [T-S1]   [T-S2]

route.north: S -> A -> B -> N1 -> N2 -> M -> C -> G
route.south: S -> A -> B -> S1 -> S2 -> M -> C -> G
```

The sketch is topological, not to scale. Map content supplies integer logical coordinates, positive integer edge lengths, presentation curves, and fixed build-slot positions. Shared edge IDs are genuinely shared graph edges; they are not duplicated per route.

Every graph node, edge, route, and build slot has a stable content ID. Validation rejects duplicate IDs, missing references, nonpositive edge lengths, cycles, disconnected route segments, routes that do not start at the spawn and end at the core, and route lists that do not match connected directed edges.

#### Unit route state and movement

Each committed unit has one route ID selected during authoring. It cannot change routes after commit. Runtime position is authoritative as:

- `route_id`;
- `edge_index` into that route's ordered edge list; and
- nonnegative integer `distance_on_edge` in logical units.

Movement consumes an integer distance budget each fixed tick. If the budget reaches an edge end, the unit enters the next route edge and spends any remainder there; a fast unit may cross multiple nodes in one tick. Arrival and edge transitions are processed in ascending stable entity ID order.

Presentation derives world position by interpolating between authored logical points or along a presentation curve. Curves, sprites, tweening, frame delta, physics bodies, and navigation agents never decide progress, range, arrival, or leak results.

#### Occupancy, passing, branches, and merges

Units do not reserve lane cells, collide, push, block, or use local avoidance in v0. Multiple units may share the same logical position. Faster units may pass slower units, including on shared edges. Spawn spacing is therefore a schedule decision, not a collision guarantee.

The committed route resolves every branch choice before spawning. At a branch node the runtime follows the next edge in its assigned route; it does not make a new choice. At the merge, both routes enter the same authored edge. No route has priority and no queue forms—movement remains independent, with stable entity ID as the final ordering key for simultaneous rule events.

This no-body-blocking rule is essential to v0 scope. Adding traffic, lane capacity, collision separation, or route switching would change combat and authoring contracts and requires a later product decision.

#### Build slots and route legality

Towers may be placed only in authored build slots. A slot contains a stable ID, integer logical coordinate, and optional allowed/forbidden tower tags. Exactly zero or one tower occupies a slot.

- Placement on an occupied, missing, or incompatible slot is rejected.
- Selling a tower during a legal defense phase frees the slot after the sale resolves.
- Towers never change graph connectivity, edge cost, route assignment, or unit movement.
- Range uses centralized squared distance between integer logical coordinates and authoritative unit positions.
- The revealed defense and composer show both complete routes, the selected route of every draft entry, shared edges, the core, and occupied/unoccupied build slots.

All v0 unit archetypes may use both routes. A future unit-specific route restriction is data-supported but requires an explicit content rule and validation; the composer may not infer restrictions from visuals.

#### Core arrival and leak behavior

The core is the terminal node shared by both routes. When movement first reaches or passes the final edge length, the unit generates one ordered leak intent, is marked arrived, and can no longer be targeted or moved. Leak resolution follows the M0.2 core-integrity rules. A unit can never leak twice, even if later stages inspect the same entity before cleanup.

#### Route and archetype review

| Situation | Required behavior and design consequence |
| --- | --- |
| Dense swarm reaches the merge from both branches | Units may overlap and interleave by entity ID; there is no traffic jam. Splash value comes from timing and logical proximity, not collision packing. |
| Runner catches a tank on a shared edge | Runner passes without changing either unit's speed or route. Target priorities use full comparators, not collection order. |
| Tank crosses an edge boundary with movement remaining | Remainder carries to the next edge in the same tick; durability never changes movement bookkeeping. |
| Support and allies occupy different branches | M0.5 defines the support rule using authoritative logical position; no support link exists merely because route progress percentages match. |
| Support and allies merge onto the shared edge | Proximity may become valid from their logical coordinates; merge order does not create a special buff rule. |
| Slow effect reduces movement below one map unit | Central integer speed/effect math still produces a tested nonnegative tick distance; the presentation cannot round it independently. |
| Multiple unit types arrive at the core in one tick | Leak intents resolve in entity-ID order and each arrival occurs once; terminal evaluation follows the complete staged-tick rule. |
| Route ID or edge reference is invalid at commit | Whole commit is rejected; no fallback route is selected. |
| A tower is sold and another placed in the same adaptation | Ordered commands determine occupancy; both actions pass through the same slot legality checks. |
| A presentation curve crosses another route visually | No branch, merge, targeting, or support relationship exists unless the authored graph and logical coordinates define it. |

### v0 combat vocabulary and initial counter matrix

This contract is the ratified M0.5 baseline. Its rules and identities are contractual; numeric values are initial balance seeds to validate in headless scenarios and playtests.

#### Combat vocabulary

v0 uses one direct-damage vocabulary rather than elemental or color-matched damage types:

- **Health:** nonnegative integer durability. A unit dies when resolved damage leaves health at 0.
- **Armor:** flat integer reduction applied to each direct-damage intent. Normal resolved damage is `max(1, raw_damage - armor)`.
- **Armor penetration:** a property of an attack that ignores armor for that damage intent; it is not a separate damage type.
- **Range:** inclusive squared-distance check between authoritative integer logical coordinates.
- **Cadence:** integer cooldown ticks. A ready tower may stage one attack, then resets its cooldown.
- **Splash:** one attack stages separate damage intents for the chosen target and every other living target within the inclusive integer splash radius of that target's attack-time position.
- **Slow:** a timed movement multiplier. The v0 control slow sets speed to 60% for 30 ticks, rounded down after positive speed bonuses. Reapplication refreshes duration; slows do not stack.
- **Rally:** the support unit's proximity aura. At each start-of-tick status stage, other living allied units within 800 logical units gain 125% movement speed for that tick. Rally does not affect its source; multiple rally sources do not stack.
- **Death:** after staged intents resolve, a unit at 0 health emits one death event, loses all statuses and auras, and is removed from movement and targeting. Death grants neither side economy.
- **Leak:** a living unit reaching the core is removed before tower targeting, emits exactly one leak, and deals its unit-defined core damage. A unit cannot both die and leak in the same tick because core arrival resolves before targeting and attacks.

Movement speed for a tick is calculated as base speed, then Rally if present, then Slow if present, rounding down after each multiplier and clamping a living unit to at least 1 logical unit per tick. Status durations count fixed simulation ticks. A slow staged by an attack begins at the next start-of-tick status stage because movement for the attack tick has already resolved.

Attack effects are authoritative and instantaneous on the firing tick. Presentation may animate a projectile between source and target, but projectile travel cannot change whether the attack hits. v0 has no miss chance, critical hit, evasion, damage-over-time, healing, shields, tower damage, or unit attacks against towers.

#### Targeting and intent order

A valid target is spawned, living, not leaked, and within inclusive range at the post-movement targeting stage. Each tower type uses a complete deterministic comparator:

- **Rapid:** least remaining authored distance to the core, then lowest entity ID.
- **Splash:** most valid units inside the splash radius around the candidate, then least remaining distance, then lowest entity ID.
- **Control:** units without the control slow first, then highest effective movement speed, then least remaining distance, then lowest entity ID.
- **Anti-armor:** highest armor, then highest maximum health, then least remaining distance, then lowest entity ID.

All ready towers acquire against the same post-movement living-target view. Attacks are staged in ascending tower entity ID. Splash victims are ordered by entity ID. Damage/status intents resolve by source tower ID, attack ordinal, then target entity ID; already-staged attacks are not canceled merely because an earlier intent kills their target. Deaths resolve after all attack intents for the tick. This permits deterministic overkill and prevents scene or collection order from changing results.

#### Initial unit archetypes

| Unit | Cost | Health | Armor | Speed/tick | Leak | Identity and tradeoff |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| **Swarm** | 5 | 24 | 0 | 12 | 1 | Cheapest body and best target saturation; individually fragile and highly spacing-sensitive against splash. |
| **Tank** | 30 | 280 | 6 | 5 | 3 | High health, armor, and breach value; slow, expensive, and deliberately attractive to anti-armor targeting. |
| **Runner** | 15 | 48 | 0 | 20 | 2 | Highest speed and route-pressure value; low durability and strongly affected by control coverage. |
| **Support** | 20 | 72 | 1 | 9 | Projects non-stacking 125% Rally within 800 logical units; pays for that aura with modest personal combat efficiency and leak value. |

All four units may use both v0 routes. Only Support has an active rule beyond movement, durability, and leaking, and that rule is automatic rather than player-triggered.

#### Initial tower archetypes

| Tower | Cost | Range | Damage | Cooldown | Identity and tradeoff |
| --- | ---: | ---: | ---: | ---: | --- |
| **Rapid** | 30 | 1,000 | 8 | 5 ticks | Cheap, frequent single-target cleanup focused nearest the core; armor reduces every small hit. |
| **Splash** | 45 | 950 | 22 | 20 ticks | Punishes dense timing with a 300-unit radius; slow cadence and separated routes/gaps reduce its value. |
| **Control** | 40 | 1,250 | 4 | 10 ticks | Longest range, prioritizes unslowed fast units, and applies 40% Slow for 30 ticks; weak direct killing without another tower. |
| **Anti-armor** | 50 | 1,150 | 90 | 30 ticks | High armor-ignoring single-target damage prioritizes armored/high-health units; expensive cadence wastes damage on cheap bodies. |

Each tower supports zero or one v0 upgrade. The upgrade costs 60% of base cost rounded up, increases base damage to 125% rounded down, and increases range to 110% rounded down. It does not change cadence, radius, status strength/duration, penetration, or targeting. This keeps upgrades legible and prevents them from erasing archetype weaknesses.

#### Initial interaction matrix

Legend: `++` strong tower answer, `+` favorable, `0` situational/even, `-` unfavorable, `--` poor. These describe equal-cost baseline pressure, not guaranteed outcomes; route coverage, spacing, order, and mixed compositions remain decisive.

| Tower vs. unit | Swarm | Tank | Runner | Support |
| --- | --- | --- | --- | --- |
| **Rapid** | `+` reliable cleanup, but can be saturated | `--` armor reduces each hit from 8 to 2 | `0` lethal if coverage lasts; speed shortens exposure | `0` can kill exposed support; escorts may remain ahead |
| **Splash** | `++` against Tight groups; `-` when split/Wide | `-` low sustained damage into health/armor | `--` sparse fast targets waste cadence and radius | `+` if clustered with rallied allies; `-` when isolated |
| **Control** | `-` low damage and no stacking; useful setup only | `--` tank is already slow and hard to kill | `++` speed drops from 20 to 12 and repeated targets rotate | `+` disrupts aura timing and creates setup, but does not remove it alone |
| **Anti-armor** | `--` extreme overkill at slow cadence | `++` ignores armor and follows the intended target priority | `-` expensive overkill and limited firing windows | `0` meaningful hit if exposed, but tanks deliberately draw priority |

The matrix is intentionally many-to-many. Splash answers density rather than the Swarm label; Control answers speed and creates positional synergy; Anti-armor answers per-target durability; Rapid supplies affordable cleanup. The player can alter order, spacing, route, and escort relationships to change these interactions without changing unit colors.

#### Example encounters

1. **Tight Swarm into a chokepoint:** eight Swarm entries at Tight spacing create several valid victims around one Splash target. One 22-damage hit nearly kills each 24-health body, making Rapid cleanup efficient. Sending the same bodies Wide or splitting routes reduces simultaneous splash victims but increases exposure to independent Rapid coverage.
2. **Tank as armor bait:** a Rapid hit deals `max(1, 8 - 6) = 2` to a Tank, while Anti-armor deals its full 90. Placing a Tank before Runners can attract Anti-armor shots by comparator, but the player pays 30 points and slow travel for that screen; Control may still catch the Runners.
3. **Runner through control:** an unbuffed Runner moves 20 units per tick. Once Control's slow becomes active it moves `floor(20 * 60 / 100) = 12`, extending exposure to other towers. An Anti-armor tower may one-shot it, but its 30-tick cadence and armored-target priority make that coverage inefficient against a spread of Runners.
4. **Support timing:** Rally raises a nearby Runner from 20 to 25 speed. If that Runner is also slowed, ordered multipliers yield `floor(25 * 60 / 100) = 15`. Wide spacing or opposite routes can break the 800-unit aura; killing Support ends future Rally checks but does not retroactively change movement already resolved that tick.
5. **Mixed defense and route split:** a Splash/Control chokepoint cluster strongly punishes a Tight single-route wave, but it leaves branch slots and its slow firing rhythm exploitable by Wide Runners on both routes. Adding Rapid coverage improves cleanup but consumes budget/slots that could have funded Anti-armor against a Tank-led alternative.

#### Red-team review: universal and dominated choices

- **Rapid is not universal:** it is the cheapest flexible tower, but Tank armor cuts its raw damage by 75%. If Rapid-only defenses still stop Tank-led equal-budget waves, its coverage or cost is overtuned.
- **Splash is not universal:** its ceiling depends on multiple units sharing a radius at one firing time. Wide gaps and route splits must materially lower targets hit.
- **Control is not dominated by damage towers:** it is the dedicated Runner answer and a force multiplier for Splash/Rapid, but Control-only defenses should leak durable or numerous waves because slow does not stack and direct damage is low.
- **Anti-armor is not universal:** it efficiently removes Tanks but loses shots to overkill, target bait, slow cadence, and cheap-body saturation.
- **Swarm is not a cheaper Runner:** Swarm buys bodies and target saturation; Runner buys distance per tick and breach damage. Splash and Control separate their failure modes.
- **Tank is not a universal screen:** armor defeats Rapid, but Anti-armor priority and high cost prevent consequence-free shielding.
- **Runner is not a universally efficient leak:** its speed reduces exposure, while low health and Control's fastest-unslowed targeting create a clear answer.
- **Support is not a mandatory multiplier:** Rally does not stack, excludes its source, requires proximity, and consumes wave budget/body order. A second Support is useful only for coverage continuity or separate routes.
- **Mixed compositions are expected, not forced by a color lock:** every pure composition has exploitable timing or durability, while no tower receives a hidden unit-class bonus.
- **Shared chokepoint is a risk:** if chokepoint coverage invalidates both routes, branch-slot geometry, range, tower cost, and defense budget are tuned before adding new mechanics.

Initial balance validation must compare equal-budget pure and mixed waves across Tight, Standard, Wide, single-route, and split-route schedules. A choice is flagged for redesign if it is strictly worse at the same cost across all tested defenses, or if one affordable tower mix trivially defeats every legal 100-point round-1 wave. These are investigation triggers, not claims that the paper matrix proves balance.

### Core fairness rule

The AI may react to prior waves, but it should not inspect the uncommitted wave the player is currently creating.

This rule is intended to prevent perfect hidden-information counters. The AI should feel intelligent because it recognizes patterns, plans well, and adapts—not because it cheats.

### v0 defender knowledge, fairness, and difficulty contract

This contract is the ratified M0.6 baseline. Fairness is enforced by the data and command boundaries given to the planner, not by asking code with unrestricted match access to behave honestly.

#### Decision timing and capability boundary

The defender planner is invoked only:

1. once in `INITIAL_DEFENSE`, after the initial 120-point grant and before the first defense reveal; and
2. once in `DEFENDER_ADAPTATION` after each nonterminal wave's result and analysis summary are finalized, the next 40-point grant is applied, and before the next defense reveal or player draft exists.

It is never invoked during defense reveal, wave authoring, commit, resolution, player analysis, or after a terminal result. The application creates one immutable, value-only `DefenderObservation` for the decision and passes that object plus the defender's dedicated variation interface to the planner. The planner receives no `MatchState`, `CommittedWave` for an unresolved wave, draft model, UI/presentation node, input service, global object lookup, or mutable content resource.

Planning is bounded by deterministic work counts rather than authoritative wall-clock timing. v0 uses no recursive search or combat rollout. Candidate and selected-action caps come from the visible difficulty profile; stable truncation occurs after complete candidate sorting. A development wall-clock watchdog may report or abort a defect, but elapsed time cannot change a legal decision.

#### Information-flow contract

| Information | Initial defense | Between rounds | Rule |
| --- | --- | --- | --- |
| Map graph, routes, logical coordinates, build slots | Allowed | Allowed | Public fixed match content |
| Unit/tower definitions, costs, upgrades, targeting, status and leak rules | Allowed | Allowed | Same immutable catalog visible to the player |
| Round count, public attack-budget schedule, defense grants, refund rate | Allowed | Allowed | Published rules; difficulty cannot alter them |
| Difficulty/profile ID and its documented planning knobs | Allowed | Allowed | Player-selected and inspectable |
| Current defender towers, upgrades, occupied slots, reserve and invested cost | Allowed | Allowed | Defender's own persistent state |
| Current core integrity and next round number | Allowed | Allowed | Defender's objective and phase context |
| Finalized prior `CommittedWave` data: unit IDs, order, spacing, routes and total spend | None exist | Allowed subject to difficulty information age | A committed wave enters history only after its resolution is finalized |
| Finalized prior results: spawn/death/leak ticks and positions, tower damage/status totals, core damage and analysis summary | None exist | Allowed subject to difficulty information age | Deterministic, reason-coded history only |
| Derived density, speed, armor, route, leak and failure-location features | From public content only | Allowed only when derived from permitted rows above | Trace records every source round and feature |
| Current or future player draft entries, cost, route, order, spacing or validation errors | Forbidden | Forbidden | Never represented in `DefenderObservation` |
| Draft existence, edit count, undo/copy actions, selection, hover, camera, inspection, authoring duration or input timing | Forbidden | Forbidden | Prevents side-channel inference about uncommitted plans |
| Current-wave live units, queue, events or combat state | Forbidden | Forbidden | Defender makes no mid-wave decisions; data becomes history only after finalization |
| Root seed, `rules`, `scenario_generation`, or cosmetic RNG streams | Forbidden | Forbidden | Planner receives only its `defender_variation` capability |
| Prior matches, player profile, files, telemetry, network data or cross-match learning | Forbidden | Forbidden | v0 memory is match-local and clears on restart/new match |
| Mutable simulation objects or unrestricted snapshots | Forbidden | Forbidden | Observation contains copies/IDs/summaries, never authority-bearing references |

The next attack budget is public because it is fixed by M0.2. Knowing that round 4 permits 160 points is fair; knowing that the player has currently drafted 145 points of Runners is forbidden. The AI may form expectations from allowed history and public rules, but it may not receive metadata whose only purpose is to predict the live draft.

#### Match-local memory

The authoritative history stores at most the five finalized round records in round order. Each record contains the normalized committed plan, compact deterministic result, analysis features approved above, and the defender decision ID that preceded it. Fine-grained events may be reduced into the stable summary after verification needs are met.

- History is append-only within a match; a prior record is never rewritten by later balance or AI calculations.
- `RestartMatch` and new match creation clear all history, derived features, planner caches, candidate lists, and decision traces before rebuilding from the seed.
- The v0 defender does not learn across matches, write a player model, or read prior replay/save files.
- A difficulty profile may receive an older prefix of the same history, but it can never receive facts unavailable to harder or normal profiles because they were hidden from the player.

#### Legal defender actions and economy

The planner may propose only the same typed commands available to a scripted defender:

- `PlaceTower(tower_definition_id, build_slot_id)`;
- `UpgradeTower(tower_entity_id)` for the single legal v0 upgrade;
- `SellTower(tower_entity_id)` with the M0.2 floor-rounded 75% refund; and
- `ReserveBudget`, including taking no other action.

Commands are evaluated sequentially through the normal command gateway. A sale may free funds/occupancy for a later placement in the same decision only because the accepted sale resolves first. Every command must satisfy phase, budget, ownership, definition, upgrade, slot, and occupancy validation. Rejected commands do not receive privileged correction; the rejection and remaining budget are recorded in the trace.

The planner cannot spawn or modify units, damage/heal the core, move a tower between slots, change routes or build slots, alter definitions/prices/refunds/grants, grant itself funds, bypass upgrade limits, mutate the player wave, or issue commands outside its decision phase. Difficulty never changes attack or defense budgets, tower/unit stats, sale value, core integrity, legality, or command priority.

#### Candidate bounds, tie-breaking, and variation

Candidate generation is deterministic and stable. The full final candidate key is action kind, build-slot ID, existing tower entity ID, tower definition ID, and upgrade ID, with missing fields using documented sentinel values. Scores and score components are integers.

After scoring, candidates sort by descending total score then the complete candidate key. If controlled variation is enabled, only candidates inside the profile's near-equal band around the best score are eligible. The threshold is `best_score - floor(max(1, abs(best_score)) * band_basis_points / 10000)`. One uniform indexed choice uses only the named `defender_variation` stream for each selected action. Without variation, the first candidate wins. Selection repeats after updating the projected legal budget/occupancy until the action cap, reserve rule, or empty legal set stops planning.

Randomness never changes candidate legality, score components, observation contents, budget, or the stable ordering outside the eligible near-equal band. The same rules/content/seed, allowed history, difficulty, and defense state must produce the same trace and accepted commands. Diagnostics record draw ordinal and chosen index without consuming additional draws.

#### v0 difficulty profiles

All profiles use the same economy and legal actions. The player can inspect these differences before starting a match.

| Lever | Easy | Normal | Hard |
| --- | ---: | ---: | ---: |
| Completed-history age | One-round delay | Current through last completed round | Current through last completed round |
| Maximum generated candidates per decision | 32 | 64 | 128 |
| Maximum selected commands per decision | 4 | 6 | 8 |
| Minimum intended reserve after planning | 20% of funds entering decision | 10% | 0% |
| Near-equal variation band | 15% (1,500 basis points) | 5% (500 basis points) | None |
| Scoring | Simplified public weights; no synergy bonus | Full baseline weights and synergy | Full weights with stronger leak-risk and coverage-gap emphasis |

“One-round delay” means the Easy decision after round 1 sees no player history, after round 2 sees round 1, and so on. Public map/rules and its current defense are never delayed. A minimum intended reserve is planner policy, not protected money: it may reserve more, and command validation still accepts any affordable legal command. If later testing needs another difficulty lever, it must be one of information age, scoring weights, candidate/action breadth, reserve policy, or controlled variation and must be recorded here before implementation.

#### Decision trace and player-facing explanation

Every invocation emits a `DecisionTrace` that cannot influence planning and contains:

- decision ID, round, phase, difficulty/profile, rules version and content fingerprint;
- observation fingerprint and the exact completed rounds visible;
- current defense/economy facts and derived threat features actually used;
- candidate counts before/after caps, stable truncation, legality rejections and reasons;
- integer score components, totals, stable candidate keys and near-equal membership;
- variation stream draw ordinals/chosen indices, if any;
- proposed commands, gateway acceptance/rejection, funds before/after, and stop reason; and
- explicit confirmation that no draft/UI/current-wave fields exist in the observation schema.

Development diagnostics may show the full trace. The player-facing defense reveal uses a concise explanation such as “added Control coverage on South after prior fast leaks” and links only to facts the player already observed. Disabling, hiding, or rendering diagnostics cannot change RNG consumption, candidate order, commands, or results.

#### Adversarial fairness examples

| Attempt or situation | Required defense |
| --- | --- |
| Player edits from Swarm to Runners while the AI is planning | Impossible timing: defender planning completes before the new draft object exists |
| UI exposes current draft through a globally reachable singleton | Contract test fails; planner modules may receive only immutable observation values and variation capability |
| Player spends a long time hovering South-route entries | Hover, selection, elapsed authoring time and input telemetry never enter observation or history |
| Player copies the previous wave then changes one entry | AI knows only the previous finalized wave; copy/edit gestures and current result are indistinguishable from any other draft |
| Hard difficulty attempts to read current draft for a “smarter” counter | Schema/capability is identical to Normal except documented profile knobs; forbidden field cannot be requested |
| Planner tries to infer draft cost from remaining player budget | Current draft spending is application-local and unspent attack budget is not authoritative until commit; only the public round cap is visible |
| Planner retains a mutable match-state reference captured earlier | Architecture/contract test rejects the dependency; observation contains copied IDs and summaries only |
| Same seed/history produces different choice after diagnostics are enabled | Repeatability test fails; traces are write-only outputs and may not consume RNG |
| Easy profile sees round 3 while making the post-round-3 decision | Test fails: its one-round delay permits history only through round 2 |
| AI overspends through a sell/place sequence | Gateway rejects the first unaffordable command; later commands use only accepted projected state and the trace records rejection |
| Match restarts after round 4 | Old history, caches and traces are discarded; same seed reconstructs the same initial decision from clean state |
| Round 5 ends with the core intact | No further defender decision is invoked because the result is terminal |

## 4. Player experience goals

The game should make the player feel like a strategist and wave designer rather than a passive unit purchaser.

The ratified v0 wave composer includes:

- Unit composition
- Deployment order
- The 5-, 15-, and 30-tick spacing presets
- Per-entry authored-route selection
- A shared wave or command-point budget
- The automatic proximity Rally of the Support archetype
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

The AI's knowledge, available actions, budget, and decision timing should be explicitly defined. Difficulty should primarily affect planning breadth, information age, scoring, reserve behavior, and controlled error—not secret information, economy changes, or unexplained stat inflation.

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

The proposed technical baseline is specified in [V0 Detailed Architecture Plan](V0_ARCHITECTURE_PLAN.md). Its M0 product inputs are ratified; the technical choices remain subject to the focused M1 architecture review and ADRs.

The simulation should be separated from presentation as much as is practical within Godot. In concrete terms, authoritative rules run in typed `RefCounted` state and systems rather than rendered scenes or physics nodes. Godot scenes present snapshots and events; they do not decide combat outcomes.

Provisional boundaries:

```text
Game application
├── Simulation
│   ├── Map and lane graph
│   ├── Units, towers, attacks, and effects
│   ├── Economy and round rules
│   ├── Seeded random number generation
│   └── Commands, events, and results
├── Defender AI
│   ├── Knowledge and observation model
│   ├── Legal action generation
│   ├── Threat analysis
│   ├── Placement and upgrade evaluation
│   └── Difficulty profile and later personality profiles
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

The v0 decision process is:

1. Analyze the map, current defense, economy, and previously observed waves.
2. Generate legal placement, upgrade, sale, and reserve actions.
3. Score candidate actions for factors such as coverage, expected damage, leak risk, synergy, vulnerability, and future flexibility.
4. Select a set of actions within the available budget.
5. Apply only the difficulty profile's seeded near-equal variation, then validate every selected command through the shared gateway.

v0 uses one transparent generalist scoring profile at the selected Easy, Normal, or Hard difficulty. Additional personalities are later possibilities, including:

- A generalist that values broad coverage
- An engineer that builds synergistic clusters
- A warden that emphasizes slowing and control
- An analyst that reacts strongly to recent player patterns
- A gambler that creates powerful but exploitable kill zones

Combat rollouts, recursive search, cross-match learning, and machine-learned player-facing AI are outside v0. Later work may revisit sampled plausible-wave evaluation or additional personalities only if the bounded heuristic defender cannot produce legible adaptation.

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

- Should later usability testing add higher-level group-editing conveniences without changing the normalized per-unit wave contract?
- Which defense-change details need emphasis beyond the fully revealed resulting layout and economy?
- What tuning changes to the initial leak damage and content costs are needed after seeded combat scenarios and playtests?
- Should a post-v0 design ever let attackers disable towers, given that v0 units only endure or bypass them?
- Should the tone be fantasy villainy, science fiction, abstraction, or something else?
- Is the long-term structure a campaign, roguelite run, puzzle set, sandbox, or hybrid?

## 13. Design-round status and next decisions

The M0 product contract was accepted on 2026-07-22:

1. **M0.2 — match, economy, and victory:** ratified.
2. **M0.3 — wave-authoring verbs and agency:** ratified.
3. **M0.4 — map and authored routes:** ratified.
4. **M0.5 — combat vocabulary and counters:** ratified.
5. **M0.6 — defender knowledge, fairness, and difficulty:** ratified.

M0.1 ratifies these decisions as one combined v0 scope with the non-goals in this plan and the capability trace in the MVP development plan. M1 next ratifies the simulation architecture, fixed-tick contracts, commands/events, testing, and replay boundaries before gameplay implementation. Theme/tone and detailed presentation direction remain open only where they do not change these product or architecture contracts.

## 14. Reference points

Existing games worth studying during design:

- [Anomaly: Warzone Earth](https://store.steampowered.com/app/91200/) — route planning, squad composition, and active support in a tower-offense structure
- [Tower Escape](https://store.steampowered.com/app/2009860/Tower_Escape/) — wave-as-party design, path planning, threat visualization, and roguelite variation
- [Countless Army](https://store.steampowered.com/app/2413640/Countless_Army/) — troop order, routes, support powers, and campaign progression
- [BYTES: The Reverse Tower Defense](https://store.steampowered.com/app/2348350/BYTES_The_Reverse_Tower_Defense/) — editable waves and a defender AI that purchases and upgrades towers

These are reference points rather than templates. The project's intended identity is the repeated, fair adaptation duel between a player-authored wave and an AI-authored defense.
