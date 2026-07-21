# Local Toolchain

Status: S0 complete  
Last audited: 2026-07-21

This document records the Windows-first development baseline for the v0 project. It separates required tooling from optional editor preferences and avoids machine-specific private paths.

## Toolchain policy

### Required

| Tool | Policy | Reason |
| --- | --- | --- |
| Windows | 64-bit Windows 11 development and export host | The v0 development and release target is Windows desktop. |
| Godot | Pin the Standard GDScript Windows x86_64 editor to `4.7.1-stable` | The project plans require Godot 4.7.x. Pinning the current 4.7 maintenance release prevents editor, import, and serialization drift. The .NET build is unnecessary for the approved GDScript stack. |
| Export templates | Install the official Standard templates matching `4.7.1-stable` exactly | Godot export templates must match the editor release used by the project. |
| PowerShell | Support Windows PowerShell 5.1 for repository-root commands | Windows PowerShell 5.1 is present by default on the audited workstation and is sufficient for the planned local scripts. |
| Git | Git 2.x with the repository's checked-in attributes and ignore rules | Source and local workflow are Git-based; no exact Git patch pin is needed for project compatibility. |

Godot feature updates and maintenance updates are deliberate repository changes. Do not silently float to a newer engine or template version. Record the new version, verify the full local workflow, and update this policy in the same change.

### Optional

- Visual Studio Code and Godot language support. The Godot editor remains a complete required workflow, so external-editor integration must not become a hidden prerequisite.
- PowerShell 7. Repository scripts may support it, but must continue to work in Windows PowerShell 5.1 until this policy changes.
- Graphics, audio, profiling, and asset-authoring tools. Add them only when a scoped task requires them.

Third-party addons, test frameworks, package-manager dependencies, and runtime libraries require explicit approval before installation or addition to the repository.

## Audited workstation

| Area | Observed state |
| --- | --- |
| Operating system | Microsoft Windows 11 Home, 64-bit, version `10.0.26200` (build `26200`) |
| CPU | AMD Ryzen 5 7600X3D, 6 cores / 12 logical processors |
| Memory | 31.2 GiB installed |
| Graphics | AMD Radeon RX 7900 GRE plus integrated AMD Radeon Graphics; a virtual display adapter is also present |
| Shell | Windows PowerShell `5.1.26100.8875`, Desktop edition; execution policy `Unrestricted` |
| Git | `2.55.0.windows.2`; available on `PATH`; system `core.autocrlf=true` |
| Code editor | Visual Studio Code `1.128.1`; available on `PATH` |
| Package manager | Chocolatey is installed; `winget` and Scoop were not discovered on `PATH` |
| Godot command | Neither `godot` nor `godot4` resolves from `PATH` |
| Godot installation | No installation was found in the checked standard user-local, Program Files, Scoop, WinGet, download, or `C:\Godot` locations |
| Export templates | `%APPDATA%\Godot\export_templates` does not exist |
| Repository project | `project.godot` and `.vscode` do not exist yet, as expected before S0.3 |

The hardware exceeds Godot's ordinary desktop requirements and presents no known blocker for the planned 2D v0. The virtual display adapter should be kept in mind only if renderer or screenshot behavior is inconsistent later.

## Gaps and approved setup shape

The remaining required gaps are a minimal project, root commands, and end-to-end verification.

Subject to explicit approval in S0.2, use this setup shape:

1. Download the official Godot `4.7.1-stable` Standard Windows x86_64 archive and matching Standard export templates from the [official Godot archive](https://godotengine.org/download/archive/4.7.1-stable/).
2. Verify the downloads came from the official Godot distribution and record hashes before extraction.
3. Extract the self-contained editor to a versioned user-local tools directory outside the repository. Do not add the engine binary or templates to Git.
4. Install the matching templates in Godot's user data location.
5. Prefer repository-root discovery of a documented environment override followed by the versioned conventional location. A machine-wide `PATH` edit is not required.
6. Keep Visual Studio Code integration optional. Configure it only if requested after the required editor and command-line workflow works.

## S0 delivery boundary

- S0.1 records the audit and obtains approval for this policy.
- S0.2 installs and verifies the approved editor and matching templates.
- S0.3 creates only the minimal Godot project and repository-root PowerShell commands.
- S0.4 verifies editor launch, headless checking, Windows export, and launching the exported build from a fresh PowerShell session.

Do not claim a command works until its owning S0 item has created and exercised it on this workstation.

## Repository-root commands

Run these from the repository root in Windows PowerShell 5.1 or later:

| Command | Responsibility |
| --- | --- |
| `.\scripts\doctor.ps1` | Resolve the pinned engine, print its version, and require matching Windows templates. |
| `.\scripts\verify.ps1` | Parse/import the project headlessly and run the minimal scene smoke test. |
| `.\scripts\run.ps1` | Launch the configured main scene. |
| `.\scripts\run.ps1 -Editor` | Open the project in the Godot editor. |
| `.\scripts\export.ps1` | Produce the ignored Windows release artifact in `build\windows`. |

Set `REV_TOWER_GODOT` to an explicit editor executable only when overriding the versioned conventional location. The command layer still rejects versions outside the pinned `4.7.1.stable` line.

## Installed S0.2 baseline

The approved installation was completed on 2026-07-21 without a machine-wide `PATH` change or VS Code configuration change.

| Artifact | Verified result |
| --- | --- |
| Editor | `%LOCALAPPDATA%\Programs\Godot\4.7.1\Godot_v4.7.1-stable_win64.exe` |
| Console executable | `%LOCALAPPDATA%\Programs\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe` |
| Reported version | `4.7.1.stable.official.a13da4feb` |
| Editor archive SHA-256 | `C7A289051EAEFB460B0106B60E9CD5BEE0EF55FD102DCB2BED1EB356CF3D90A1` |
| Editor signature | Valid Authenticode signature from Prehensile Tales B.V. |
| Templates | `%APPDATA%\Godot\export_templates\4.7.1.stable` with 35 files |
| Template archive SHA-256 | `86409DB6200B6F8FD3230989C2D2002851F3DD18ACF11D7BDBAFDDF5A0DD0F72` |
| Required Windows templates | `windows_debug_x86_64.exe` and `windows_release_x86_64.exe` present |
| Editor process check | Process remained running and responsive during the launch check |

Use the console executable for repository automation so version, parse, test, and export output is reliably attached to PowerShell. Use the non-console executable for the interactive editor and game.
