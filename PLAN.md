# Devvy — Dev Drive Migration Studio

Draft plan v1 — 2026-11-19.
Origin: the Dev Drive migration hand-built with PowerShell scripts on this machine (2026-11-18/19), plus the UI/UX patterns we admire in [Cleanly](https://github.com/0xCodez/cleanly).

---

## 1. Product

**One-liner.** Relay moves your heavy folders — package caches, IDE data, SDKs, whole dev trees — onto a Dev Drive (or any fast second volume) and links them back in place, with a plan you can see, a resume you can trust, and a backup that fits in one file.

**Target user.** Windows 11 developers and creators whose C: fills up: pnpm/npm/Gradle/Cargo caches, Android SDK, VS Code extensions, JetBrains, Docker/WSL disks. Anyone who today runs `robocopy` + `mklink /J` by hand from a forum post.

**Why now.**
- Windows 11 ships Dev Drives (ReFS + async Defender performance mode) but ships **zero migration tooling** — you get an empty volume and good luck.
- The gap is real: six existing utilities (Folder Move, Link Shell Extension, Steam Mover, RoboMirror, ChoEazyCopy, WinRoboCopy) cover only "move one folder + junction" or "robocopy flags in a GUI." Nobody does inventory → plan → batch migrate → resume → verify → backup.
- We know the workflow works: it was executed end-to-end on this machine — 22 junctions, zero broken paths, C: free 79.9 → ~100 GB, V: writes at full NVMe speed (1752 MB/s). **~80% of the hard logic already exists as tested PowerShell** in `reference/`.

## 2. Safety model (the differentiator)

Cleanly's rule "cleaning tools should never cost you a file" generalizes to: **a migration tool should never orphan your paths.**

1. **Move is never delete-first.** Copy → verify → swap in junction → only then remove the source remainder. Interrupted = original still there.
2. **Reversible everything.** Every action writes a plan-file entry with its undo (remove junction + move back).
3. **Labels.** Every tree gets Cleanly-style labels: **Safe** (caches — rebuildable), **Review** (source trees, IDE data), **Permanent** (never offer: Windows, Program Files, drive roots).
4. **Junction-aware.** Resolve every path to its real target before touching it; verify a junction resolves after creating it (today's "honest verification"); never copy *through* junctions (`robocopy /XJ`).
5. **In-use detection.** Running executables from a tree → defer, not force (process-Path guard); invisible locks (session cwd handles, MCP servers inside `_npx`) → the "close these apps" prompt, made humane.
6. **Partial = visible.** Locked leftovers produce a `PARTIAL` state and a one-click resume — never a fake success message (the one real bug our scripts hit).

## 3. Feature set

**MVP (v0.1, Windows only)**

| # | Feature | Proven by |
|---|---|---|
| 1 | **Scan**: home + fixed-drives inventory of movable trees (dev caches, IDE data, SDKs) | `cache-sweep.ps1` (33 paths) |
| 2 | **Plan**: bubble-map UI (Cleanly Space Map pattern), per-tree size, label, conflict check, target drive pick | new UI |
| 3 | **Dev Drive setup**: create portable dynamic VHD → attach → ReFS `/DevDrv` format → trust → logon auto-attach | `devdrive-setup-wizard.sh` + `devdrive-launcher.ps1` |
| 4 | **Execute**: batch move → junction per tree; waves; pause/resume; idempotent re-runs | `devdrive-migrate.ps1`, `devdrive-resume.ps1`, `final-pass.ps1` |
| 5 | **Verify**: junction resolution map, speed test, "everything resolves" report | `final-pass.ps1` verification |
| 6 | **Backup/Restore**: detach VHD → dated copy → re-attach → trust | `backup-devdrive.ps1` |

**v0.2+**
- VHD expand/shrink UI (`devdrive-expand.ps1`)
- Env-var redundancy assistant (`CARGO_HOME`, `GRADLE_USER_HOME`, `npm_config_cache`, `PIP_CACHE_DIR`, `UV_CACHE_DIR`)
- WSL/Docker disk relocation guidance (guided click-path, like today's Docker move)
- Scheduled backups; low-space watch
- "New projects live on the Dev Drive" onboarding

**Explicitly out (MVP):** cleaning/deleting (Cleanly's job), cross-platform (Dev Drive is Windows-only), partition-flavor Dev Drives (portable VHD flavor is safer to automate and supports backup).

## 4. Architecture

Adopt Cleanly's proven layout shape (not its code — see license risk):

```
electron/
  services/    scanner.ts  planner.ts  mover.ts  devdrive.ts  backup.ts  verify.ts
src/          React + TypeScript screens (one per screen)
shared/types.ts   typed IPC contract
```

- **mover.ts** — robocopy via `child_process` (`/E /MOVE /R:1 /W:1 /XJ`), rc<8 gate, junction via Node `fs.symlink(target, path, 'junction')` — **junctions need no admin**, so ordinary moves run UAC-free.
- **devdrive.ts / backup.ts** — diskpart scripts + `fsutil devdrv` via a self-elevating helper with **baked parameters** (hard lesson: env vars don't survive the UAC boundary).
- **State** — local JSON plan files per migration (resumable, auditable). No cloud, no telemetry.
- **Elevation policy** — moves never elevate; only VHD create/expand/backup elevate, one UAC each.

## 5. Screens (Cleanly-inspired)

1. **Home** — "See where your space went": big scan button, drive cards (free space; Dev Drive health: attached? trusted? auto-attach scheduled?).
2. **Plan** — bubble map + checklist: label, size, ETA, conflicts ("close OpenCode to move this one"). Pick target per tree or in batch.
3. **Execute** — per-tree progress, pause, the "apps to close" dance as a friendly checklist, resume banner after interruption.
4. **Verify** — green junction map (`C:\x → V:\y`), speed numbers, per-tree rollback button.
5. **Dev Drive** — create / expand / backup / restore dashboard.

## 6. Landscape

| Tool | Move+junction | Batch/plan | Dev Drive lifecycle | Resume | VHD backup |
|---|---|---|---|---|---|
| Cleanly | — (refuses junctions) | — | — | — | — |
| Folder Move / Steam Mover / LSE | ✓ (one folder) | — | — | — | — |
| RoboMirror / ChoEazyCopy / WinRoboCopy | — (sync only) | — | — | — | — |
| jqknono script | ✓ (script) | ✓ caches | partition flavor, no VHD | skip-if-done | — |
| **Devvy** | ✓ | ✓ | ✓ (portable VHD + trust + auto-attach) | ✓ | ✓ |

## 7. Risks

- **License (blocking for a fork):** Cleanly ships no LICENSE → its code is all-rights-reserved. **Build fresh**; borrow patterns (bubble map, labels, honest tone), keep visual identity distinct. Re-check the repo before publishing anything that references it.
- **Unsigned binaries:** SmartScreen warnings early on (Cleanly has the same); document the click-through, budget for a cert post-alpha.
- **AV heuristics:** shelling out to robocopy/diskpart is benign but worth signing.
- **Invisible locks:** session-cwd-style handles are undetectable via Get-Process — the app must *ask humans to close apps* rather than pretend to detect (honest prompt > false green).
- **Dangling junctions after detach:** ship the auto-attach scheduled task with every Dev Drive + health check on app launch.

## 8. Milestones (solo dev + AI pair, rough)

- **M0 — Spike (week 1):** repo, Electron skeleton, scanner service, ONE manual tree move→junction→verify end-to-end in-app. *Exit: move `.konan` with a button.*
- **M1 — Planner + Executor (weeks 2–3):** plan files, batch waves, resume, PARTIAL gates, verify screen. *Exit: migrate a fresh machine's caches unattended.*
- **M2 — Dev Drive lifecycle (week 4):** setup/attach/trust/auto-attach + backup/restore ported from `reference/`. *Exit: create → backup → restore a Dev Drive on a VM or second PC.*
- **M3 — Alpha (weeks 5–6):** polish, onboarding, report export, installer. *Exit: a stranger succeeds without docs.*

Estimates assume part-time; AI writes boilerplate, the human reviews every safety-critical path.

## 9. Business model (options — defer to post-alpha)

1. **OSS core + paid Pro** (backup scheduling, expand UI) — trust-first; fits the safety story.
2. **One-time paid** — no subscription fatigue.
3. **Free-and-famous** — portfolio/funnel play.

## 10. Decision points

1. **Name** — ✅ chosen: **Devvy** (2026-11-19). Devvy over Devy: double-v reads unambiguously as "DEV-ee"; friendly, mascot-able, matches the approachable Cleanly-inspired UX. Collision check 2026-11-19: GitHub = 131 micro-repos (max 17★, none in the system-tool space); npm = only scoped `@devvy-ui/*` (a small third-party UI kit); bare `devvy` npm name unclaimed.
2. **Fresh build vs fork** — recommend **fresh build** (Cleanly has no license + identity should differ); Cleanly = design reference only.
3. **Stack** — recommend **Electron + React + TypeScript** (proven pattern for this genre, matches existing JS/TS skills). Tauri = smaller binaries, adds Rust.
4. **Business model** — defer.

## 11. Immediate next steps

1. ✅ **Rescue scripts** from ephemeral temp dirs into `reference/` (done 2026-11-19 — this folder holds every proven script from the migration).
2. ✅ Name picked: **Devvy** → this folder (renamed `V:\dev\devvy`) is the repo seed: `reference/` + this plan.
3. **M0 spike.**
4. Finish the still-pending VHD backup (its script is now archived here: run `reference\Run-backup.cmd`).
