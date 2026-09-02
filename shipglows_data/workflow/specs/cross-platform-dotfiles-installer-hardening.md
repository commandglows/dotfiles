---
artifact: spec
metadata_schema_version: "1.0"
artifact_version: "1.0.1"
project: dotfiles
created: "2026-08-27"
updated: "2026-08-31"
status: ready
source_skill: sg-development
scope: cross-platform-dotfiles-installer-hardening
owner: Diane
confidence: high
risk_level: high
security_impact: "yes"
docs_impact: "yes"
user_story: "En tant qu'operatrice Windows et Linux, je veux installer mes dotfiles et outils terminal de facon idempotente, recuperable et sans melanger le provisioning ShipGlows."
linked_systems:
  - Windows PowerShell
  - Linux Bash
  - WinGet
  - Native Linux package managers
depends_on:
  - "native-windows-dotfiles-bootstrap.md"
supersedes: []
evidence:
  - "Audit of the legacy Linux orchestrator and broad Windows provisioning script."
  - "Approved cross-platform hardening plan on 2026-08-27."
next_step: "Run syntax and temporary-profile behavior proofs on Windows and Ubuntu."
---

# Cross-platform Dotfiles installer hardening

## Outcome

Provide native Windows and Linux installers sharing a TSV component contract, with strict read-only modes, clean checkout updates, centralized recovery state, and ownership-proven uninstall. Dotfiles owns terminal configuration/tools; ShipGlows owns AI agents, skills, MCP, Doppler, secrets, and general developer provisioning.

## Scope

In: PowerShell/Bash engines, compatibility shims, manifest, terminal packages/config, checkout validation, backup/journal/restore, behavioral contracts, CI, and operator docs.

Out: Termux changes, production/server provisioning, credentials, execution policy, PowerShell profile edits, AI tooling, MCP client config, Doppler, package removal, destructive checkout repair, and publication.

## Acceptance criteria

- AC01: dry-run creates or changes nothing; check is read-only; incompatible or unknown input fails closed.
- AC02: update accepts only matching origin/branch, clean status, and fast-forward history.
- AC03: manifest selection/dependencies are validated natively without external parsing dependencies.
- AC04: conflicts use centralized backups and every managed artifact has a journal proof.
- AC05: uninstall refuses changed/unproven targets, restores backups, and leaves packages installed.
- AC06: Windows diagnoses WinGet, preserves process PATH, retains useful switches, and installs Yazi's declared packages whenever Yazi is selected; the compatibility switch remains accepted.
- AC07: Linux rejects Windows/MSYS and Termux, uses explicit native package managers, handles root directly, and has no active remote-script pipe.
- AC08: Yazi is modern/default; Ranger is Linux-only legacy and explicit.
- AC09: shims contain no provisioning; runtime and development-clone roles are documented.
- AC10: Windows/Ubuntu CI exercises syntax, contracts, and temporary profiles without heavy network installation.
- AC11: Windows Neovim pins Avante to exact release v0.2.3/SHA a0a1d12c51d5336167074215bc22ff7127ac240c with published Windows assets, uses upstream OS-specific builds, treats fzf-native as prerequisite-gated optional acceleration, and verifies pinned Codex ACP 0.16.0 plus its native x64/arm64 runtime.
- AC12: the versioned Lazy lockfile is normalized to LF so Windows lockfile rewrites do not create formatting-only dirty checkout failures.
- AC13: Windows installs and checks WinLibs GCC/CMake/Ninja plus the official Tree-sitter CLI as manifest dependencies of the Avante/ACP stack, without applying WinLibs or its probes to Linux.
- AC14: Rio is installed with the Windows core profile and restores the versioned split-navigation key bindings without persisting a machine-specific working directory.
- AC15: The Windows core profile installs dotfiles-owned `n` and `y` command shortcuts without relying on the ShipGlows runtime.

## Security, OWASP, ZOMBIES, and recovery

Targets are restricted to the current user profile. Origin, branch, and dirtiness are checked before updates. No automatic reset, stash, force checkout, secret retrieval, profile mutation, or arbitrary recursive deletion is allowed. Link targets, copied-file hashes, marked shell blocks, and PATH entries provide ownership evidence. Changed targets are preserved and reported.

OWASP: command arguments are fixed or manifest-token validated; paths are quoted; remote script execution is absent; secrets are neither read nor logged; least privilege is used; journals contain paths/hashes only. ZOMBIES: broad Windows provisioning and Linux AI/MCP/Doppler flows are removed from active entrypoints, wrappers delegate, Ranger is isolated, and uninstall removes valid owned artifacts without removing packages.

## Proof order

1. Parse PowerShell and Bash sources.
2. Run static forbidden-pattern and manifest contracts.
3. Run dry-run/check invalid-input tests in temporary profiles.
4. Run link backup, idempotence, uninstall, and restoration tests.
5. Exercise isolated fresh Windows and Ubuntu profiles without credentials.
6. Record results before publication; this implementation claims no passing test yet.

## Skill run history

| Date UTC | Flow | Model | Action | Result | Next step |
| --- | --- | --- | --- | --- | --- |
| 2026-08-27 | 100-sg-spec | inherited current model | Audited scope, ownership, safety contract, and proof order. | ready | 101-sg-ready |
| 2026-08-27 | 101-sg-ready | inherited current model | Resolved manifest, native engines, recovery, and exclusions. | ready | 102-sg-implementation |
| 2026-08-27 | 102-sg-implementation | inherited current model | Implementing engines, manifest, shims, contracts, CI, and docs. | implementation in progress; tests not run | Execute proof order. |
| 2026-08-27 | 106-sg-fix | inherited current model | Repaired Windows native plugin build assumptions and added manifest-driven Codex ACP installation/postconditions. | fix attempted; focused retest pending | Run focused Windows installer and Neovim contracts. |
| 2026-08-27 | 106-sg-fix | inherited current model | Hardened WinGet update convergence and pnpm v11 global-bin/instance runtime resolution after real Windows retests. | fix attempted; focused fixture retest pending | Prove exact HRESULT and pnpm v11 layouts. |
| 2026-08-27 | 106-sg-fix | inherited current model | Pinned Avante to stable v0.2.3 after main requested a prebuilt version with no matching release. | fix attempted; focused static/headless retest pending | Activate the pinned release in the operator runtime. |
| 2026-08-27 | 103-sg-verify | inherited current model | Verified native Windows update/check, ACP executable, Avante release build/modules/config, and Telescope core; normalized the Lazy lockfile to LF. | passed; technical non-visual proof complete | Close BUG-2026-08-27-001. |
| 2026-08-27 | 106-sg-fix | inherited current model | Persisted the WinLibs native toolchain and official Tree-sitter CLI after LazyVim's real prerequisite check identified their absence. | passed: parser, Windows behavior/static contracts, manifest validation, and Linux isolation | Keep the prerequisites under focused CI contracts. |
| 2026-08-31 | 106-sg-fix | inherited current model | Made Yazi plugin installation automatic whenever the Windows installer selects Yazi. | passed: regression-first dry-run, PowerShell parser, and Windows static contract | Verify and close BUG-2026-08-31-001. |
| 2026-08-31 | 103-sg-verify | inherited current model | Independently verified automatic Yazi package planning and read-only installer invariants. | passed: parser, behavior, static contract, and non-mutating check | BUG-2026-08-31-001 closed. |
| 2026-08-31 | direct bounded update | inherited current model | Added Rio to the Windows core manifest and captured the operator's split-navigation shortcuts without the local working directory. | passed: TOML parse, Windows dry-run behavior, and static manifest contract | Keep Rio covered by Windows installer regression tests. |
| 2026-08-31 | direct bounded update | inherited current model | Made the Windows core profile own both `n` and `y` shortcuts through the shared dotfiles bin path. | passed: Windows behavior/static contracts, runtime layout, and direct `n.cmd` smoke | Keep terminal shortcuts covered by installer contracts. |

## Current chantier flow

| Stage | Status | Evidence | Next step |
| --- | --- | --- | --- |
| 100-sg-spec | ready | Outcome, scope, acceptance, recovery, OWASP, ZOMBIES, and proofs are explicit. | 101-sg-ready |
| 101-sg-ready | ready | No unresolved material direction remains after approval. | 102-sg-implementation |
| 102-sg-implementation | completed | Native engines include Windows Neovim/ACP compatibility, release pinning, optional fzf handling, and lockfile EOL stability. | 103-sg-verify |
| 103-sg-verify | completed | Native Windows installer/check and Neovim module/config/Telescope postconditions passed; proof is technical and non-visual. | Closed. |
