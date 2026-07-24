# M2 Performance Envelope

Status: verified  
Measured: 2026-07-24  
Command: `.\scripts\benchmark.ps1`

## Agreed v0 targets

The M1 architecture baseline fixes the measured scale at 300 simultaneously active units, 100 placed towers, and a 1280x720 presentation viewport. M2.5 turns that scale into these workstation gates:

- simulate 20 authoritative ticks (one gameplay second) in at most 1,000 ms median with diagnostics disabled
- meet the same 1,000 ms median with ordered diagnostics retained
- produce identical semantic state with diagnostics enabled and disabled
- reconcile and render 400 current placeholder entity nodes with a p95 frame time no greater than 16.67 ms
- keep p95 snapshot reconciliation within 4 ms

The simulation benchmark uses three measured samples after one warmup. Its synthetic capacity fixture spawns 300 real Swarm definitions at tick zero and places 100 real Control towers in unique benchmark-only slots within active range. This intentionally bypasses player wave spacing and economy because it measures simultaneous swarm pressure, not legal round balance.

## Development workstation

- Windows 11 Home
- AMD Ryzen 5 7600X3D
- 31.2 GiB RAM
- AMD Radeon RX 7900 GRE
- Godot 4.7.1 stable, Compatibility renderer

## Measured result

### Headless authoritative simulation

| Mode | Sample totals | Median total | Median average tick | Retained events | Result |
| --- | --- | ---: | ---: | ---: | --- |
| Diagnostics off | 221.394 / 225.241 / 262.833 ms | 225.241 ms | 11.2621 ms | 0 | Pass |
| Diagnostics on | 214.003 / 221.417 / 237.315 ms | 221.417 ms | 11.0709 ms | 902 | Pass |

Both modes ended with the same semantic signature: tick 20, core integrity 10, 298 active units, two deaths, no leaks, 7,152 total health, 71,664 total edge distance, and 200 attacks. Diagnostics therefore add observation cost without changing results.

### Rendered presentation proxy

The current presentation creates one placeholder `Node2D` per entity. At 1280x720 with 300 unit nodes and 100 tower nodes:

| Metric | Result | Target |
| --- | ---: | ---: |
| Median frame | 1.558 ms | informational |
| p95 frame | 2.435 ms | <= 16.67 ms |
| Maximum sampled frame | 3.889 ms | informational |
| Median reconciliation | 1.172 ms | informational |
| p95 reconciliation | 1.588 ms | <= 4 ms |

This passes the current node-count and snapshot-reconciliation assumption. It is not a final sprite, shader, particles, UI, or GPU-overdraw promise. M3 visual implementation and M5 stability work must rerun the rendered measurement with production visuals.

## Measured remediation

The first 200-tick prototype exceeded 180 seconds and was terminated. A bounded 20-tick follow-up still took about 1,970 ms before towers entered range. Profiling by code-path isolation identified repeated candidate sorting plus repeated route-position and remaining-distance calculation for every tower.

M2.5 replaced candidate sorting with a stable linear best-candidate scan and added an ephemeral per-tick `TowerTargetingFrame`. The frame computes each active unit's logical position and remaining route distance once, then every tower reads those cached values. It does not survive the attack stage, alter authority, change tie-breakers, or affect RNG. The full semantic scenario suite stayed identical.

No ECS, native extension, pooling, multithreading, or addon is justified by the measured result.

## Commands

Run both measurements:

```powershell
.\scripts\benchmark.ps1
```

Run only the headless simulation measurement:

```powershell
.\scripts\benchmark.ps1 -SkipRender
```

The rendered command briefly opens a 1280x720 Godot window. Both benchmark scripts return a nonzero exit when their threshold or semantic-parity gate fails and print machine-readable JSON summaries.
