# M3 Player-Authored Match Verification

Status: M3 implementation and visual flow verified
Verified: 2026-08-03
Godot: 4.7.1.stable.official.a13da4feb

## M3.1 defense inspection and threat visualization

The first M3 slice exposes a readable fixed-defense reveal without granting presentation any combat authority.

Automated evidence:

- `.\scripts\test.ps1 -TestPath res://tests/integration/defense_inspection_test.gd`
- 5 tests passed, 39 assertions, 0 failures
- Factual tower type, range, target policy, upgrade, route coverage, and covered-segment values come from validated content and copied deployment inputs.
- Threat priority is stable and qualitative: the checked reveal identifies Chokepoint → Core and Merge → Chokepoint as Fortified with two overlapping tower ranges each.
- Returned models and arrays are copies; UI changes cannot mutate authoritative or cached content state.
- Mouse-style selection through the map contract updates the inspection panel, and left/right keyboard actions cycle the same stable tower list.
- The combined minimum layout fits the 1280x720 base and 1024x768 check, with scrollable inspection details.

Full repository evidence:

- `.\scripts\verify.ps1`
- Project parse and composition smoke passed.
- 58 tests passed, 606 assertions, 0 failures.
- Three checked combat scenarios matched their semantic summaries.
- The checked diagnostic replay matched and the incompatible schema was rejected with `schema_mismatch`.
- Final result: `VERIFY PASS: parse, smoke, tests, combat scenarios, and replay checks succeeded`.

Visual evidence:

- `.\scripts\capture-inspection.ps1`
- Generated captures: 1280x720, 1440x900, and 1024x768 under ignored `build/visual_checks/m3_1/`.
- All three captures keep the map, selected range, legend, tower detail panel, priority reads, and non-predictive disclaimer visible without overlap or clipping.
- Operator task: inspect the map without developer telemetry and identify the two strongest shared-route reads. Result: the red two-range bands and the Priority Reads panel both identify Chokepoint → Core and Merge → Chokepoint.

The visual task is a layout/readability check, not a representative-player playtest. M5 still owns structured adaptation-loop playtesting.

## M3.2 wave composition, order, and spacing editor

Status: implementation and automated verification complete; human click-through pending before the board item is marked Done.

Implemented evidence:

- `WaveDraft` is application-owned and copies entries for callers. It uses the checked-in catalog and round-one 100-point budget, accepts 5/15/30-tick spacing only, gives every new entry a deterministic valid default route, and caps the v0 draft at 300 entries.
- The composer is reachable through the existing valid Defense Reveal → Wave Authoring player transition. It exposes catalog-derived unit costs, add/remove, move up/down, spacing, undo/redo, clear, cost, remaining points, entry count, and concise invalid feedback.
- A deliberately over-budget 120-point tank draft remains editable and says `Over budget by 20 points.`; removing an entry restores validity. No draft edit mutates `MatchState` or spends an authoritative budget.
- Focused suite: `.\scripts\test.ps1 -TestPath res://tests/integration/wave_composer_test.gd` covers catalog costs, ordering, spacing, undo/redo, invalid edits, over-budget correction, and two distinct valid wave shapes.
- Authoring-mode visual captures at 1280x720, 1440x900, and 1024x768 show a valid 70/100 four-entry wave with the map, composer, order list, controls, and feedback visible. Run `.\scripts\capture-inspection.ps1 -Authoring` to recreate them.
- Full `.\scripts\verify.ps1`: parse and smoke passed; 64 tests passed with 692 assertions and 0 failures; checked replay, all three combat scenarios, and incompatible-schema rejection passed.

Manual review still required:

1. Start authoring from Defense Reveal.
2. Build one mixed wave and one different runner-heavy wave, keeping each at or below 100 points.
3. Reorder an entry, change a spacing value, then undo and redo it.
4. Briefly exceed the budget and remove an entry; confirm the message is actionable and the draft remains editable.

M3.3 owns route assignment and authoritative atomic commit, so this review should not expect either control yet.

## M3.3 through M3.6 player-authored match flow

Automated evidence:

- Route selection remains draft-local until commit. The commit path normalizes the first spacing, validates the full route/unit schedule with `UnitSpawnSchedule`, and creates an independent fixed-defense resolution input. Later draft edits cannot alter the committed wave.
- `MatchState` explicitly enforces reveal, authoring, commit, resolution, analysis, round transition, and match-end phases. Playback pause and 1x/2x/4x only change presentation tick delivery; they never change fixed-tick results.
- `PostWaveAnalysis` reports only ordered combat-event facts: core integrity, leaks, survivors, effective damage by tower/location, and deaths by location. It returns copies and is available only after resolution.
- Scripted match coverage drives five full rounds through the shared command gateway, verifies the defender win after round five, verifies a player win immediately after the core reaches zero, and verifies restart rebuilds the initial state from the same root seed.

Final automated gate:

- `./scripts/verify.ps1` passed on 2026-08-03: parser, smoke, full test suite, checked replay, three checked combat scenarios, and incompatible-schema rejection all succeeded.
- `git diff --check` passed in the same run.

Live runtime evidence:

- 2026-08-03 Godot runtime bridge validation launched the actual main scene, entered authoring from Defense Reveal, added a wave entry, scrolled to and activated Commit Wave, and observed the visible `ANALYSIS · 0 leaks · core 10` result.
- The live `NEXT ROUND` control activated after analysis and returned the composition to the next reveal. The phase label is updated to show the new round.
