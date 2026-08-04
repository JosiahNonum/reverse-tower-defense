# Reverse Tower Defense v0 Windows Runbook

Release version: `v0.1.0`  
Target: offline Windows desktop, Godot 4.7.1

## Produce and check

```powershell
.\scripts\verify.ps1
.\scripts\benchmark.ps1
.\scripts\export.ps1 -Version v0.1.0 -Debug
```

The verified internal-playtest artifact is in `build\windows\v0.1.0-debug\`. Export performs a bounded headless launch check and prints executable/package SHA-256 hashes. The release-template artifact at `v0.1.0` currently access-violates on launch and must not be distributed.

## Local review

1. Launch `reverse-tower-defense.exe`.
2. Inspect the reveal, author and commit a valid wave, and use pause/1x/2x/4x during resolution.
3. Use analysis to identify leaks, survivors, and tower damage; compare the next reveal and adaptation explanation.
4. Finish five rounds and restart once.

Playback speed persists in local versioned settings; invalid data falls back to 1x. v0 has no match save, cloud sync, telemetry, installer, updater, or online service. This launch check does not establish human readability or balance; see [M5_VERIFICATION.md](M5_VERIFICATION.md).
