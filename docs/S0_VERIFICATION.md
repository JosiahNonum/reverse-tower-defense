# S0 Local Environment and Tooling Verification

Status: complete  
Verified: 2026-07-21  
Host: audited Windows 11 development workstation

This record closes the S0 local-toolchain gate. Paths use environment variables or repository-relative forms so the document contains no private machine path.

## Pinned baseline

- Godot Standard Windows x86_64 `4.7.1.stable.official.a13da4feb`
- Matching official `4.7.1.stable` Standard export templates
- Windows PowerShell 5.1-compatible repository commands
- No third-party addons or runtime dependencies
- No machine-wide `PATH` change and no required external-editor integration

The installation hashes and signature evidence are recorded in [LOCAL_TOOLCHAIN.md](LOCAL_TOOLCHAIN.md).

## Verified root workflow

The complete workflow was repeated from a fresh `powershell.exe -NoProfile` process rooted at the repository:

```powershell
.\scripts\doctor.ps1
.\scripts\verify.ps1
.\scripts\export.ps1
```

Observed results:

| Gate | Evidence |
| --- | --- |
| Diagnosis | Resolved the versioned editor and console executables; reported the pinned version; found the matching x86_64 Windows debug and release templates. |
| Project parse | Godot completed its headless filesystem scan and editor initialization with exit code 0. |
| Script smoke test | `SMOKE PASS: main scene loads and instantiates`. |
| Verify command | `VERIFY PASS: project parse and smoke test succeeded`. |
| Project launch | `.\scripts\run.ps1` started the configured main scene; the project log initialized the OpenGL Compatibility renderer without errors. |
| Editor launch | `.\scripts\run.ps1 -Editor` started a responsive Godot process for the repository project. |
| Windows export | `EXPORT PASS` produced `build\windows\reverse-tower-defense.exe` and its PCK. |
| Exported build | The release executable rendered the expected 1280x720 placeholder scene and exited with process code 0 after a bounded launch check. |
| Repository hygiene | `.godot\` and `build\` remained ignored; `git diff --check` passed. |

Exported-artifact evidence from this run:

| Artifact | Size | SHA-256 |
| --- | ---: | --- |
| `build\windows\reverse-tower-defense.exe` | 109,071,360 bytes | `04BAF75CC1D69DD93EB709533ECAB4FD7770BB8A530645717017A06A9D9809FC` |
| `build\windows\reverse-tower-defense.pck` | 4,224 bytes | `8A2A3EE6E9A6E4F21F70F2F4B1932C1B16F2187600825331668655FDC100E264` |

A project-only PNG frame from the exported build was retained as local task evidence outside the repository. It shows the expected placeholder title and S0 status text; it does not capture the desktop or other applications.

## Troubleshooting notes

- The official export-template package is large. The initial transfer exceeded a ten-minute automation window, but the official object store supported resuming the partial download. Verify the completed package hash before installation.
- On Windows, use Godot's `_console.exe` companion for scripted version, parse, smoke-test, and export commands. Directly invoking the GUI executable does not reliably populate PowerShell's `$LASTEXITCODE`.
- Use `Start-Process -Wait -PassThru` when an explicit exit code is required from the GUI-style exported executable.
- The first editor or verify run creates `.godot\`; exports create `build\`. Both are generated and ignored.
- Set `REV_TOWER_GODOT` only when the versioned default location is unavailable. The scripts still reject a mismatched Godot release.

## S0 exit result

The minimal project can be diagnosed, parsed, smoke-tested, launched, exported for Windows, and launched from the exported artifact using documented repository-root commands. The S0 exit condition is satisfied; gameplay and architecture implementation remain out of this setup scope.
