---
summary: "Windows port implementation plan: CLI-first architecture, platform seams, tray UI, packaging, and parity criteria."
read_when:
  - Planning Windows support for CodexBar
  - Auditing cross-platform CLI or provider portability
  - Designing Windows tray, credential, browser-cookie, or packaging work
---

# Windows Port Implementation Plan

## Purpose

This note turns the Windows-port feasibility review into an implementation plan for reaching a CodexBar-equivalent Windows release. The target is not a line-for-line port of the macOS app; the target is feature parity for the user-facing CodexBar requirements through a Windows tray application backed by the shared provider engine.

## Definition of done

A Windows port is complete when a signed Windows build can satisfy the core CodexBar product promise:

- keep AI coding-provider limits visible from the Windows notification area;
- show provider-specific usage meters, reset countdowns, credits, spend, status incidents, and actionable errors;
- support provider enablement, account selection, manual refresh, refresh cadence, display preferences, and safe credential storage;
- expose scriptable JSON output equivalent to the bundled CLI on macOS/Linux;
- document unsupported or degraded provider modes instead of silently showing cross-provider or stale data.

## Current architecture signals

- The package already separates shared provider logic into `CodexBarCore` and a script-friendly `CodexBarCLI` executable. Those products are declared outside the macOS-only product block, while the menu-bar app, widget, watchdog, and web probe are declared only for macOS.
- `CodexBarCore` is partially cross-platform today: it contains Linux-specific SQLite linkage and Linux test targets, and many provider fetchers are Foundation/network/parser code.
- The user-facing app is macOS-native. The main app target depends on SwiftUI/AppKit-adjacent packages such as Sparkle, KeyboardShortcuts, and Vortex, and the README describes CodexBar as a macOS menu bar app requiring macOS 14+.
- Some platform surfaces are explicitly macOS-bound: Keychain access, WebKit teardown, status-item/menu UI, Sparkle updates, login item behavior, app packaging/signing/notarization, and browser-cookie decryption flows.
- A Windows-related ecosystem already exists outside this codebase: the README links to `Win-CodexBar`, while Linux desktop integrations consume the bundled CLI JSON output.

## Architecture decision

Build the Windows port as a native Windows tray shell around shared CodexBar data contracts. Do not port the macOS SwiftUI/AppKit app directly.

The planned architecture is:

1. **Shared engine**: keep provider fetching, parsing, cost calculations, account selection, and payload shaping in Swift where possible.
2. **Windows-compatible CLI/service**: make `CodexBarCLI` run on Windows and expose stable `usage`, `cards`, `cost`, `config`, `diagnose`, and optional `serve` JSON contracts.
3. **Windows tray client**: implement a small native Windows UI that reads the CLI/service payloads and renders notification-area icons, flyouts, settings, errors, and refresh controls.
4. **Windows platform adapters**: add Windows-specific implementations for process execution, config paths, credential storage, browser cookies, opening URLs, notifications, startup behavior, update checks, and installer integration.

This minimizes macOS regression risk because `Sources/CodexBar` remains the macOS UI, while Windows work lands behind platform seams and a separate tray shell.

## Functional requirement mapping

| Requirement | Existing source of truth | Windows implementation target | Acceptance criteria |
| --- | --- | --- | --- |
| Provider usage meters and reset countdowns | `CodexBarCore` provider fetchers and CLI payloads | Shared engine through Windows CLI/service | Enabled providers render current values, reset labels, and stale/error states from the same JSON schema as macOS/Linux CLI. |
| Credits, spend, and cost scans | Provider-specific fetchers plus `codexbar cost` | Reuse fetchers where credentials are available on Windows | API-backed spend and local cost views match CLI output in golden fixtures. |
| Provider status incidents | Status probes and menu descriptors | Expose incident fields in CLI/service payload and render tray badges | Incident state appears in the tray flyout without mixing provider identity/plan fields. |
| Multi-provider tray visibility | macOS status-item/menu model | Windows notification-area icon plus flyout cards | Users can see one merged icon or provider-focused cards with quota bars and labels. |
| Settings and provider toggles | Config commands and app preferences | Windows settings view backed by CLI config APIs or shared config module | Provider enable/disable, account selection, cadence, and display settings persist across app restarts. |
| Refresh cadence and manual refresh | Usage store/adaptive refresh concepts | Windows scheduler in tray client or local service | Manual refresh and cadence presets update payloads without overlapping provider probes. |
| Credentials and cookies | macOS Keychain and browser-cookie support | Windows Credential Manager/DPAPI plus Windows Chromium cookie adapter | Secret material is never logged, is scoped per provider/account, and browser imports fail safely when unavailable. |
| CLI and automation | `CodexBarCLI` | Native Windows CLI binary | JSON commands work in PowerShell/cmd with documented exit codes and no UI prompts in noninteractive mode. |
| Packaging and updates | macOS app bundle, Sparkle, notarization | MSIX/winget or signed installer plus update policy | Signed release artifacts install, upgrade, and uninstall cleanly. |
| Diagnostics | CLI diagnose and docs | Windows-aware diagnose command | Diagnose reports missing adapters, config paths, browser support, credential backend status, and provider failures. |

## Workstreams

### 1. Portability inventory

- Build `CodexBarCore`, `CodexBarCLI`, `AdaptiveRefreshCore`, and `AdaptiveReplayCLI` on Windows with SwiftPM.
- Record every unsupported import, package dependency, compiler condition, Foundation API gap, linker failure, and test failure.
- Classify failures as manifest-only, dependency, POSIX/process, filesystem path, credential, browser-cookie, UI, or packaging.
- Add a living compatibility matrix in this document or a follow-up doc before changing runtime behavior.

Exit criteria:

- A reproducible Windows build log exists.
- The first provider subset for Windows MVP is selected.
- Manifest changes required for Windows are known and scoped.

### 2. Shared platform seams

Introduce narrow interfaces before adding Windows-specific behavior:

- `CodexBarProcessRunner`: run provider CLIs without PTY assumptions and with platform-specific cancellation/tree termination.
- `CodexBarPathResolver`: resolve home, config, cache, browser profile, and provider-specific paths on macOS, Linux, and Windows.
- `CodexBarSecretStore`: abstract Keychain, Windows Credential Manager/DPAPI, test stores, and no-UI/noninteractive behavior.
- `CodexBarCookieStore`: abstract browser cookie discovery/decryption and cache invalidation.
- `CodexBarOpenURL` and notification adapters: isolate UI-triggered shell integration from provider logic.

Exit criteria:

- Existing macOS/Linux behavior is preserved behind default adapters.
- Tests cover each seam with stubs and no real Keychain/browser prompts.
- Windows adapters can be added without importing AppKit, Security, WebKit, or POSIX-only APIs into shared code.

### 3. Windows CLI MVP

Bring up `CodexBarCLI` on Windows before building UI.

Initial provider scope:

- API-key/config-file providers that do not need browser cookies or OS credential prompts.
- Local log/cost parsers where Windows paths are known.
- Providers that call external CLIs only after the Windows process runner is stable.

Required commands:

- `codexbar usage --json`
- `codexbar cards --json`
- `codexbar cost --provider codex|claude|both --json` when local log paths are available
- `codexbar config` for provider toggles and safe nonsecret settings
- `codexbar diagnose --json`

Exit criteria:

- Windows CLI produces stable JSON for the selected provider subset.
- Noninteractive commands never display OS credential prompts.
- Provider failures are represented as structured payload errors.

### 4. Windows credential and browser-cookie support

Add sensitive integrations after the CLI MVP is reliable.

- Implement a Windows secret backend using Credential Manager or DPAPI-protected storage.
- Decide which secrets remain config-file backed and which require OS-protected storage.
- Add a Windows Chromium cookie backend that handles profile discovery, local state keys, cookie DB reads, decryption, cache refresh, and opt-in UX.
- Keep browser-cookie imports disabled by default until the credential backend has no-prompt test coverage.

Exit criteria:

- Secrets are siloed by provider/account and never appear in logs, diagnostics, or JSON output.
- CLI tests can run with fake stores and no real Windows credential prompts.
- Cookie-backed providers report clear unsupported/authorization-needed states when browser data is unavailable.

### 5. Windows tray MVP

Build the Windows tray shell only after the CLI/service contract is stable.

Minimum UI:

- notification-area icon with merged/provider-focused status;
- flyout with provider cards, bars, reset countdowns, credits/spend/status badges, and errors;
- manual refresh and refresh cadence controls;
- provider enable/disable and account selection;
- open settings, open logs/diagnostics, quit;
- safe degraded-state messaging for unsupported providers.

Preferred integration:

- Start with a tray UI that invokes the CLI or talks to `codexbar serve` over localhost.
- Move to direct shared-library integration only if measured process overhead or UX latency requires it.

Exit criteria:

- Tray UI satisfies the definition of done for the selected provider subset.
- Refreshes are debounced and cancellable.
- The UI never displays identity, plan, or usage fields sourced from a different provider.

### 6. Packaging, updates, and release

- Choose the distribution model: signed installer, MSIX, winget package, portable zip, or a staged combination.
- Define update behavior separately from Sparkle.
- Add Windows release checks, artifact signing, checksums, installation docs, and uninstall cleanup notes.
- Document known provider limitations by release channel.

Exit criteria:

- A signed Windows artifact installs and launches on a clean Windows machine.
- CLI is on PATH or discoverable by the tray app.
- Upgrade/uninstall flows preserve user config and remove app-owned caches safely.

## Suggested milestone sequence

1. **M0: Decision and scope lock**
   - Confirm repository ownership model for the Windows tray code.
   - Choose the first provider subset and release channel.
   - Decide whether to integrate with `Win-CodexBar` or treat it as prior art only.

2. **M1: Windows build inventory**
   - Run SwiftPM builds/tests on Windows.
   - Produce the compatibility matrix and initial failing-target list.

3. **M2: Platform seams merged**
   - Add process/path/secret/cookie abstractions with macOS/Linux adapters and tests.
   - No user-visible behavior changes.

4. **M3: Windows CLI MVP**
   - Build and package the Windows CLI.
   - Support Tier 1 providers and JSON diagnostics.

5. **M4: Windows tray alpha**
   - Render usage cards from CLI/service JSON.
   - Support manual refresh, cadence, provider toggles, and settings persistence.

6. **M5: Sensitive integrations**
   - Add Windows Credential Manager/DPAPI and browser-cookie backends.
   - Expand provider support to Tier 2 and selected Tier 3 providers.

7. **M6: Beta hardening**
   - Add installer/update flow, telemetry-free diagnostics, regression fixtures, and localization checks.
   - Validate performance, refresh overlap prevention, and error recovery.

8. **M7: Windows release**
   - Ship signed artifact and docs.
   - Track unsupported providers and parity gaps explicitly.

## Provider support tiers

- **Tier 1**: API-key/config-file providers and local parsers that require no OS credential prompt or browser-cookie import.
- **Tier 2**: providers requiring external CLI execution or local subprocess orchestration after the Windows process runner is stable.
- **Tier 3**: browser-cookie, OAuth-cache, Keychain-derived, or OS-secret-dependent providers after Windows credential/cookie backends are implemented.
- **Deferred**: macOS-only affordances such as WidgetKit widgets, Sparkle update UI, macOS login items, and AppKit-specific menu behavior.

## Test strategy

- Unit tests for parsers, payload shaping, path resolution, secret-store stubs, process-runner cancellation, and provider failure mapping.
- Golden JSON fixtures for `usage`, `cards`, `cost`, and `diagnose` across macOS/Linux/Windows.
- Windows CI build for portable targets and CLI commands.
- UI automation for the tray client using mocked CLI/service responses.
- No tests may trigger real OS credential prompts unless explicitly run as a manual secure-integration suite.

## Risks and mitigations

- **Swift package compatibility on Windows**: start with build inventory and isolate nonportable packages behind compiler conditions.
- **Secret handling regressions**: add fake stores and no-UI tests before real Windows credential access.
- **Provider drift**: keep CLI JSON as the contract so macOS/Linux integrations and Windows UI consume the same shapes.
- **UI parity creep**: define the Windows release around core status/usage/settings requirements and defer macOS-only widgets/update affordances.
- **Packaging scope**: choose one MVP channel first, then add winget/MSIX after signed installer or zip flow is stable.

## Compatibility findings (2026-07-15 source audit)

A read-through of the current tree confirms the architecture direction but surfaces
concrete blockers the workstreams above must reorder around. These are code facts,
not estimates:

| # | Finding | Evidence | Impact |
| --- | --- | --- | --- |
| C1 | `SweetCookieKit` is an **unconditional** dependency of `CodexBarCore`. | `Package.swift` declares it on the `CodexBarCore` target with no platform condition; `import SweetCookieKit` appears in ~36 `CodexBarCore` files, none guarded by `#if os(...)`. | `CodexBarCore` — and therefore `CodexBarCLI` — will not compile on Windows until this kit is either Windows-buildable or moved behind a `CodexBarCookieStore` seam with a platform condition. Blocks even Tier 1. |
| C2 | SQLite linkage is Linux-only. | `CSQLite3` system library is attached to `CodexBarCore`/`CodexBarCLI`/tests via `.when(platforms: [.linux])`; SQLite-backed providers (Windsurf, OpenCode Go, Cursor, Factory, Alibaba cookie import, cost scanner) read it in `CodexBarCore`. | No Windows SQLite link strategy exists. SQLite-dependent providers cannot link on Windows until one is defined (bundled amalgamation, vcpkg, or a `winsqlite3` module map). |
| C3 | `Commander` (argument parser) Windows support is unverified. | `CodexBarCLI` depends on `steipete/Commander`; no Windows build has ever run it. | CLI MVP (workstream 3) rests on this; verify or replace before committing to the Windows CLI. |
| C4 | Windows CI now has a **non-blocking inventory job**, but not a release gate. | `.github/workflows/windows-build-inventory.yml` runs on Windows manually and on PRs that touch portable build surfaces; the main CI and release CLI workflows still gate only macOS/Linux. | Workstream 1 / M1 can start collecting Windows SwiftPM/toolchain evidence without blocking unrelated PRs. It should become a required build gate only after C1/C2 and the toolchain install path are resolved. |
| C5 | Zero `#if os(Windows)` conditionals exist in `Sources/`. | grep of `Sources/` returns nothing for `os(Windows)`. | Confirms work is pre-M2. Note the codebase already carries ~20 `#if os(Linux)` seams in `CodexBarCore`, so the cross-platform seam pattern to imitate is established, not novel. |
| C6 | `#if os(macOS)` in `Package.swift` is host-evaluated (a manifest subtlety, not a bug). | The macOS-only product/target blocks are gated with `#if os(macOS)` in the manifest itself. | Correct for cross-compilation: when SwiftPM's manifest is compiled on a Windows host, the macOS products/targets drop out automatically. Keep this pattern; do not switch to `.when(platforms:)` inside the macOS block. |

### Plan correction: dependency ordering

The workstream list presents "2. Shared platform seams" and "3. Windows CLI MVP" as
sequential, but C1/C2 make part of workstream 2 a **hard precondition** for workstream 3,
not a parallel nicety:

1. **First**, keep the non-blocking Windows inventory workflow running when portable
   build surfaces change, so runner/toolchain facts are captured early without making
   Windows a required gate.
2. **Next**, land the `CodexBarCookieStore` seam and make `SweetCookieKit` conditional
   (C1) plus a Windows SQLite decision (C2). Until then `swift build --product CodexBarCLI`
   cannot produce a useful Windows binary, so build failures from those blockers should be
   captured but not treated as new discovery.
3. **Then** promote the Windows build inventory from evidence-gathering to a stricter
   PR/release signal against a Core that at least parses, so the remaining failures are
   genuinely new signal (Foundation gaps, `Commander`, process runner, path resolution)
   rather than the two blockers documented here.

Recommended sequencing: M1 (inventory) and the C1/C2 slice of M2 should interleave; the
first useful Windows CLI cannot precede them.

## Open questions

- Should the Windows tray app live in this repository, a sibling repository, or an existing `Win-CodexBar` fork?
- Which providers are mandatory for the first Windows alpha and beta?
- Is direct shared-library integration required, or is CLI/service integration acceptable for the first release?
- Which Windows distribution channel is required for the first public release?
- What level of visual parity with the macOS popover is required before release?
