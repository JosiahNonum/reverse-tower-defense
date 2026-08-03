# M4 Adaptive Defender Verification

Status: M4 implementation verified locally.

Implemented seam:

- `DefenderObservation` is a value-only copied projection containing only round/phase, defender economy/layout, core, public version fingerprints, and difficulty-filtered finalized history. Contract tests reject AI-source dependencies on match state, drafts, UI, presentation, nodes, and global-node lookups.
- `ObservationHistory` is match-local, append-only, returns deep copies, and applies the profile's history delay.
- The planner uses a simulation-side `DefenseCommandGateway` for PlaceTower, UpgradeTower, SellTower, and ReserveBudget proposals; it does not receive `MatchState`, drafts, live entities, presentation, or input state.
- Planning is invoked for initial defense and between resolved rounds. Restart reconstructs the AI history, budget, variation stream, decision sequence, and trace store.
- Candidate ordering is stable by score then action/slot/tower keys; planner work is capped by the profile candidate/action caps. Controlled near-equal choice uses only the named defender-variation stream.
- `DecisionTrace` captures decision identity/context, observation fingerprint and visible rounds, derived features, candidate caps/truncation, score components, rejections, variation draw metadata, commands/results, remaining budget, and stop reason. Trace recording is write-only.
- The defense-reveal presentation refreshes from copied deployments after an adaptation and states either the observed prior leaks or the resulting public-coverage change.

Focused automated evidence:

- `./scripts/test.ps1 -TestPath res://tests/unit/defender_ai_test.gd` — 4 passed, 61 assertions: forbidden dependencies, copied observation history, Easy/Normal/Hard history age, stable bounded planning, and same-seed trace equality.
- `./scripts/test.ps1 -TestPath res://tests/integration/adaptive_defender_test.gd` — 1 passed, 17 assertions: headless multi-round adaptation, repeatability, player-safe explanation, and restart history clearing.
- `./scripts/verify.ps1` — parse, smoke, full test suite, replay, and all checked combat scenarios pass.
- `git diff --check` — pass.

Board update note: the M4.1 through M4.5 status/evidence update was attempted on 2026-08-03 against the `Reverse Tower Defense — v0 MVP Build Plan` board. monday.com returned `USER_UNAUTHORIZED` for every item mutation, so the remote board was not changed. This repository document is the concrete local completion record.
