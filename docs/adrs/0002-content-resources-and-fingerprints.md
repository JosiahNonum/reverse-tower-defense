# ADR-0002: Content Resources and Fingerprints

Status: Accepted
Date: 2026-07-22
Owners: M1.4 Architecture and Foundation

## Context

The v0 map topology, build slots, units, towers, upgrades, match economy, and defender difficulty knobs must be editable without embedding balance values in simulation control flow. Godot caches loaded resources, so treating a definition as mutable runtime state would allow one match or test to corrupt another. Diagnostic replay also needs an explicit way to reject results recorded against different content.

## Decision

- Editor-authored authoritative definitions are custom Godot `Resource` types stored as text `.tres` files under `content/`.
- Every cataloged definition and every map-local node, edge, route, and slot has a lowercase stable ID.
- `MapDefinition` owns logical bounds, nodes, directed positive-length edges, ordered routes, fixed build slots, and an optional presentation scene path.
- `UnitDefinition` owns integer cost, health, armor, speed, leak damage, allowed routes, optional Rally values, and an optional presentation reference.
- `TowerDefinition` owns integer combat values, a complete targeting comparator, optional Splash/Slow/penetration data, tags, one optional upgrade reference, and an optional presentation reference.
- `MatchRulesDefinition` owns the five-round economy, core health, tick rate, and references to the selected map, units, base towers, and defender profiles.
- `DefenderProfileDefinition` contains only documented planning knobs and integer scoring weights. It contains no observations, live state, or hidden policy access.
- `ContentCatalog` loads `.tres` files through Godot's normal cache, treats them as immutable, validates them before match creation, and exposes lookup by stable ID.
- Mutable runtime objects copy the required definition values and IDs. They do not retain authority by mutating the cached definition.
- The content fingerprint is SHA-256 over stable JSON representations of every cataloged definition, sorted independently of filesystem load order.
- Portable diagnostic scenarios and replays remain versioned JSON. They store the fingerprint; they do not serialize cached Resource objects.

## Validation contract

Headless verification rejects:

- missing, malformed, or duplicate stable IDs
- missing graph, route, upgrade, rules, unit, tower, profile, or map references
- nonpositive required values, negative values, and values above the authoritative safety bound
- disconnected, cyclic, empty, or non-core-reaching authored routes
- map coordinates and build slots outside logical bounds
- contradictory build-slot tags
- unsupported targeting/status combinations
- tower upgrade cycles or chains deeper than the single v0 upgrade
- invalid basis points, round counts, or attack-budget schedules

All checked-in content must validate as one catalog before a match starts.

## Consequences

- Any authoritative definition change produces a different content fingerprint and invalidates older diagnostic expectations unless deliberately migrated.
- Presentation paths may change without granting scenes authority; they are still part of the current fingerprint because the v0 catalog records the complete checked-in definition.
- Godot Inspector editing remains available, while diffable text resources and headless validation protect the runtime boundary.
- Balance numbers in the initial resources are ratified M0 seeds, not permanent tuning promises.

## Initial evidence

- The checked-in catalog contains one authored two-route map, four units, four base towers plus four one-step upgrades, three defender profiles, and one five-round rules definition.
- Repeated loads produce the same 64-character SHA-256 fingerprint.
- Invalid fixtures cover duplicate and missing IDs, bad references, negative and overflow-prone values, unreachable routes, invalid slots, and upgrade cycles.
- Two `UnitState` instances created from the same cached Tank resource remain independent, and damage to one does not mutate the shared definition.
