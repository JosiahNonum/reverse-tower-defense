# M1 Architecture and Foundation Verification

Status: complete  
Last verified: 2026-07-24

This record owns the repeatable M1 gate. It supplements the S0 workstation/toolchain record with project tests, diagnostic replay compatibility, and the current Windows export.

## Repository-root workflow

Run from the repository root in Windows PowerShell:

```powershell
.\scripts\doctor.ps1
.\scripts\verify.ps1
.\scripts\scenario.ps1
.\scripts\export.ps1
```

`verify` performs the editor import/parse pass before direct test execution so newly added GDScript global classes are registered. It then runs the composition smoke test, all discovered project tests, the checked foundation replay, and an expected schema-incompatibility probe.

`scenario` accepts only repository-local replay artifacts. By default it runs `tests/fixtures/replays/foundation_phase_replay.json`. A compatibility failure exits nonzero unless the caller explicitly supplies the expected failure code for a verification probe.

`export` requires the pinned matching templates, writes only to ignored `build/windows`, verifies both EXE and PCK outputs, launches the generated executable headlessly for two iterations, and prints SHA-256 hashes.

## Verification evidence

Observed on the pinned Windows/Godot baseline:

| Gate | Evidence |
| --- | --- |
| Diagnosis | `doctor.ps1` resolves Godot `4.7.1.stable.official.a13da4feb` and matching Windows templates. |
| Project verification | Editor import/parse PASS; composition smoke PASS; 29 tests PASS, 235 assertions, 0 failures. |
| Checked scenario | Reached `wave_authoring` at tick 3 with 5 events and digest `992ca692e481a519c5be7223c4854ec8b3f9b4f4d6c885ddf0034191286ad006`. |
| Incompatible replay | Schema 99 was rejected against supported schema 1 with `schema_mismatch`; the expected-failure probe exited 0 only after observing that exact code. |
| Intentional test failure | Explicit fixture reported 0 passed, 1 failed, the readable `intentional failure fixture` assertion, and process exit 1. |
| Windows export | Release EXE and PCK were created; the generated EXE launched headlessly and exited with process code 0. |
| Repository hygiene | `.godot/` and `build/` remained ignored; `git diff --check` passed. |

Exported-artifact evidence:

| Artifact | SHA-256 |
| --- | --- |
| `build/windows/reverse-tower-defense.exe` | `04BAF75CC1D69DD93EB709533ECAB4FD7770BB8A530645717017A06A9D9809FC` |
| `build/windows/reverse-tower-defense.pck` | `97CA3316AA2D495B1D7FEC4635C19FCD0773F5D4F31B64B9F5F1D8DCC6C053ED` |

The M1 gate is satisfied: one root verification command proves the headless rules/content/contracts, minimal scenario, snapshot/presenter smoke seam, and incompatible replay behavior; the export command independently proves the Windows artifact boots.

## Intentional-failure contract

`tests/fixtures/intentional_failure_test.gd` remains outside default discovery and exists only to prove that the test command exits nonzero. Run it explicitly:

```powershell
.\scripts\test.ps1 -TestPath res://tests/fixtures/intentional_failure_test.gd
```

The command must fail with a readable assertion and PowerShell error. A passing exit would be a harness regression.

## Hygiene

- `.godot/`, `build/`, and logs remain ignored.
- Checked replay fixtures contain stable project IDs and digests, never private machine paths.
- `git diff --check` must pass.
- Verification and diagnostics do not install tools or mutate authoritative content.
