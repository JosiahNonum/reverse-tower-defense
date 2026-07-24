# ADR-0003: Versioned diagnostic replay contract

Status: Accepted  
Date: 2026-07-24

## Context

Headless regression scenarios and later defender-AI investigations need portable evidence that a command sequence still produces the same result. A JSON file that merely parses can become misleading after a schema, rules, or content change. Recording UI wave-draft gestures would also couple diagnostics to presentation behavior instead of authoritative commands.

## Decision

Diagnostic replay artifacts are versioned JSON owned by `src/application`. The supported schema records:

- exact artifact schema and rules versions
- the SHA-256 content-catalog fingerprint
- the root match seed as a lossless decimal string and a stable scenario ID
- normalized rules, map, unit, tower, and defender-profile IDs
- accepted authoritative phase-boundary commands
- a nonnegative fixed tick count
- the expected phase, tick, event count, and event digest

JSON dictionaries are validated immediately into typed runtime objects. Replay runs headlessly against `MatchState` and submits every recorded command through the same command gateway used by the application. A command rejection or expected-summary difference is a failed replay.

Compatibility checks are ordered and reason-coded. The runner rejects unsupported schema versions, rules ID/version changes, content fingerprint or normalized ID changes, malformed artifacts, rejected commands, and result mismatches. It never silently upgrades an artifact or claims compatibility across arbitrary versions.

The initial fixture covers only the M1 phase-boundary seam. Later `CommitWave` support extends the typed command payload without recording UI draft gestures.

## Consequences

- Checked fixtures are honest regression evidence for the exact supported rules and content.
- Authoritative content changes intentionally require fixture regeneration and review.
- Diagnostics remain presentation-independent and cannot mutate an unrelated live match.
- The schema can evolve through an explicit version change and deliberate migration or fixture replacement.
- This contract does not provide player-facing save games, match rewind, or indefinite replay compatibility.
