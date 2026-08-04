# M5 v0 Validation and Release Verification

Status: **revise before external v0 release**  
Measured: 2026-08-03

## M5.1 — deterministic balance matrix

`./scripts/balance.ps1` runs 72 complete headless matches: four single-archetype wave shapes, both routes, Tight/Standard/Wide spacing, and Easy/Normal/Hard defender profiles. Each row uses a distinct deterministic seed and records outcome, core integrity, leaks, initial deployment count, and trace count. The scenario test runs the matrix twice and requires identical reports.

Post-repair measurement: **71 player wins, 1 defender win; three of four archetype shapes are universal attacker wins; no tested shape is universally unreachable.** This is a balance failure, not a release claim. Route and spacing do not yet create enough strategic separation in the single-archetype sweep.

Evidence-backed tuning made: during initial defense, the planner may no longer sell towers it just placed. That was the cause of empty initial layouts for some profiles; focused planner and presentation tests prove a non-empty legal initial deployment. No economy/stat number was changed because one matrix cannot responsibly select a new value.

Required next balance slice: add mixed-wave counterplay cases, then tune starting defense budget, tower costs/stats, or wave costs one variable at a time against this matrix. Preserve fixed integers, shared command legality, and fairness-filtered observations.

## M5.2 — adaptation-loop playtest protocol

For each fresh participant, record seed/profile, completed rounds, task times, assistance, task outcomes, quotes, and observations. Do not explain an interaction before they attempt it; record interventions.

1. Ask them to inspect the reveal and name a route/tower/coverage concern.
2. Ask them to author, validate, and commit a first wave without coaching.
3. After resolution, ask what caused the result using the visible analysis.
4. On the next reveal, ask what changed, why, and what counter-wave they would try.
5. Complete or restart through five rounds; ask whether they want another attempt and why.

Automated substitute evidence: the matrix completes 72 five-round loops deterministically, and the composed two-round playthrough authors and resolves two waves through `Main`, observes tower attack feedback/projectile events, and verifies a non-empty second-round reveal. These cannot measure comprehension, satisfaction, or retry intent. **No human sessions were run in this automated environment**, so M5.2 remains open.

## M5.3 and M5.4 — fixes, stability, and settings

- The main scene now reveals the adaptive planner's actual initial deployment instead of overwriting it with a fixed demonstration layout.
- The resolution battlefield now draws runtime unit/tower markers in the map's coordinate frame and flashes an attack beam when tower attack events arrive; the prior empty `Node2D` placeholders were not visible.
- Follow-up presentation pass adds cosmetic moving projectiles and read-only unit health bars from `EntityView` snapshots. Projectile motion cannot affect hit results.
- The next-round map redraw now uses an explicit typed branch instead of assigning an untyped empty array to `Array[StringName]`, removing the observed `NEXT ROUND` runtime error.
- Defender adaptation now retains at least one tower, preventing an empty second-round reveal while preserving legal sales of excess towers.
- Runtime battlefield entities are now phase-scoped: old combat towers/units and projectile feedback are cleared before the next defense reveal, so the reveal map cannot show stray plus-shaped tower markers off the course.
- Wave authoring remembers the last valid route and spacing selection; the next `+ Unit` uses those settings while raw `WaveDraft` defaults remain unchanged for headless callers.
- A four-round composed UI regression now verifies every reveal, authoring, resolution, analysis, and next-round boundary. It exposed that round one omitted its round label; initial reveal now follows the same labeled state as later rounds.
- Terminal analysis now says `VIEW RESULT` rather than the misleading `NEXT ROUND`; the resulting match-complete screen restores the inspection panel, identifies the outcome, and its `RESTART` path returns to a labeled round-one reveal.
- Reveal and authoring labels use the current round instead of hard-coded round 1.
- A schema-versioned `user://settings.json` persists only 1x/2x/4x playback speed. Invalid/incompatible data safely falls back to 1x.
- The matrix is a 72-match deterministic headless soak with no command failure or corrupt terminal state. It does not replace human visual testing.

Current workstation performance (`.\scripts\benchmark.ps1`, 2026-08-03) passes the M2 envelope: simulation median totals were 210.77 ms (diagnostics off) and 206.731 ms (on) for 20 ticks at 300 units/100 towers; rendered p95 frame time was 9.732 ms and p95 reconciliation was 1.99 ms at 1280x720.

Presentation only consumes copied deployments, inspection models, snapshots, and events; it never mutates authoritative simulation state. No in-progress match save, cloud save, profile, telemetry, addon, or architecture change was added.

## M5.5 — build runbook

```powershell
.\scripts\export.ps1 -Version v0.1.0 -Debug
```

It writes the verified internal-playtest artifact to `build\windows\v0.1.0-debug\`, runs a bounded launch check, and prints SHA-256 hashes. See [V0_RELEASE_RUNBOOK.md](V0_RELEASE_RUNBOOK.md).

Recorded debug-export evidence: `reverse-tower-defense.exe` SHA-256 `1CB23CEC5F4DE7FA6C884CD61AF3B5B3DF52B7D0F82638AA36B241A1CFDC3244`; package SHA-256 `E5C894CCF566AEC513A37BF02B426ED5022C6D583AF127B2F45ABB8DEF48A2AE`; bounded launch result `EXPORT LAUNCH PASS`.

Follow-up visual-fix export: `build\windows\v0.1.1-debug\` also passed `EXPORT LAUNCH PASS`; its package SHA-256 is `C264B120188C2C4A6D96290B8AE6AC2B26B246748707757F8B8AF84FD6776DDE`.

Round-two/feedback export: `build\windows\v0.1.2-debug\` passed `EXPORT LAUNCH PASS`; its package SHA-256 is `5C04E1AEC529139A484380E200C78764B10B279B131B3842849F6AA7F6138BC6`.

Live-event bridge export: `build\windows\v0.1.3-debug\` passed `EXPORT LAUNCH PASS`; its package SHA-256 is `2D7806AE2893FB1F8EB3D3D6D52CAEF75D89134485C42EB11E85985D7B672CF4`.

Dropdown/reveal cleanup export: `build\windows\v0.1.4-debug\` passed `EXPORT LAUNCH PASS`; exe SHA-256 is `1CB23CEC5F4DE7FA6C884CD61AF3B5B3DF52B7D0F82638AA36B241A1CFDC3244`, and package SHA-256 is `7E590B676AC6D91AD617405D7EAA42E12D2B15DE60C8DCD543A902C196D56D3E`.

Round-progression export: `build\windows\v0.1.5-debug\` passed `EXPORT LAUNCH PASS`; exe SHA-256 is `1CB23CEC5F4DE7FA6C884CD61AF3B5B3DF52B7D0F82638AA36B241A1CFDC3244`, and package SHA-256 is `7B5BED478EA066FFED0A0A986069BB239178887271D816CFE685C9C8F7F4F884`.

Export packaging succeeds at `build\windows\v0.1.0\`, but the bounded launch check fails on this workstation with Windows exit code `-1073741819`. The failure also occurs for exported `--headless --editor --quit` and normal `--quit-after 2`, so it is not isolated to main-scene composition or the headless flag. M5 removed the development MCP runtime autoload, excluded its addon/cache from the release package, and fixed a PowerShell version-parameter shadowing bug; the access violation persisted. No checksum or launch-pass claim is made; this is a release blocker requiring a focused exported-runtime crash investigation.

## M5.6 — exit review

| Exit criterion | Evidence | Result |
| --- | --- | --- |
| Five-round loop repeatability | 72-case matrix and integration/AI tests | Pass locally |
| Legal/fair defender boundary | M4 contracts plus planner regression | Pass locally |
| No Must defect blocks a match | 71/72 player wins and universal attacker shapes | **Fail** |
| Adaptation is understood and wanted | Human playtests absent | **Open** |
| Internal Windows playtest artifact | Debug export starts and exits cleanly | Pass |
| Release Windows candidate | Benchmark passes; release-template launch exits `-1073741819` | **Fail** |

Decision: **REVISE**. Do not publish this as a validated external v0. The deterministic implementation seam is sound, but the balance failure and absent human evidence prevent a truthful continue/release decision.

## Board status

The M5 group and all six Backlog items were read. No mutation was attempted because repository instructions reserve remote work to the user; the earlier M4 `USER_UNAUTHORIZED` result remains the last known mutation failure. The board has not changed.
