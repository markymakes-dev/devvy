# Devvy UI Language — design references & rules

*How Devvy should look, feel, and talk. Every claim cited; add new references with the playbook in §6.*

## 1. Ground rules (anti-slop)

Source: [unslop.site](https://unslop.site/) — "the anti-slop design archive": 219 design references, 12 categories, built for "choosing a direction, briefing an AI agent, and getting past generic first drafts" (1-click agent briefs). Same philosophy as this environment's `antislop-design` skill, which is the enforcement tool.

**Banned defaults (the slop set):** purple gradient hero · Inter as the identity font · 3-card feature grids · glassmorphism · emoji icons · invented proof/numbers · generic dashboard shell.

**Required:** pick a direction *before* building (brief first, code second) · one idea per screen · real content in every mockup · honest empty states.

## 2. What we borrow from Cleanly (patterns, not pixels)

PLAN.md decision #2: fresh build (Cleanly ships no license) — mechanisms yes, identity no.

| Cleanly pattern | Devvy use |
|---|---|
| Space Map (size bubbles) | Plan screen: movable trees as clickable bubbles |
| Safe / Review / Permanent labels | Same three labels on every tree; Permanent = never offered |
| Honest refusal messaging | Blocked move → say why + what to close (the "close OpenCode" dance, made humane) |
| Review before destructive | Execute screen: waves shown as a checklist before the first robocopy |
| Assistant (optional AI, own key) | **No equivalent** — Devvy has no AI features; local-only is the trust stance |

## 3. Visual identity direction (to pick at M1, not settled)

[design.dev](https://design.dev/) is a curated shop of AI-era design resources — distinctive paid fonts (Oviform, Clinamen, Lenitane, Nockward, …, $39/license) and "tools to direct AI agents and check what they ship."

Working direction (decide at M1): a distinctive sans from design.dev for display + a system monospace (Cascadia/JetBrains) for **paths and numbers** — paths and GB figures *are* this app's content, so a monospace-forward look fits naturally and is inherently unslop. Budget if adopted: ~$80 for two licenses. Dark-first (dev tool) vs auto theme: decide with it.

## 4. Screen intents (from PLAN.md §5)

1. **Home** — two big numbers (C: free / V: free), one scan button, Dev Drive health dots. No card grid.
2. **Plan** — bubble map + labels; conflicts as humane checklists.
3. **Execute** — waves; **PARTIAL is a first-class visible state** with one-click resume (the one real bug our scripts hit).
4. **Verify** — green junction map `C:\x → V:\y`, speed numbers, per-tree rollback.
5. **Dev Drive** — create / expand / backup / restore; every dangerous action shows its undo first.

## 5. Tone

Cleanly's "honest tone," generalized: the app never pretends. PARTIAL says PARTIAL. Refusals give reasons. No invented progress bars, no fake success messages.

## 6. Playbook: turning any reference into a Devvy reference

1. **Fetch the source** (raw README/site text — webfetch, not memory).
2. **Distill into this file's format:** principle → how Devvy uses it → link. One row per mechanism, not prose.
3. **Cite the URL.** Unsourced numbers get marked "unsourced."
4. **If it's a mechanism** (e.g. LoopForge's human-gate, FastMCP's elicitation), it belongs in a patterns table like §2.
5. For reusable *workflow* knowledge, promote it to a skill (`C:\Users\markl\.agents\skills\<name>\SKILL.md`) — as done for `devvy-ui`.

Note: repos exist that auto-convert sites/docs into agent skills (scrape → chunk → SKILL.md; the pattern behind unslop.site's "1-click agent brief"). For a handful of references, hand-distillation per this playbook is higher quality; the exact repo name couldn't be confirmed on 2026-11-20 (search quota exhausted — HTTP 402), marked unsourced.

## 7. Prior-art register (already evaluated — don't re-research)

| Reference | Verdict | Where recorded |
|---|---|---|
| Cleanly (0xCodez) | Design reference only; no license; refuses junctions | PLAN.md §2, §7 |
| LoopForge (Tencent) | SOP/gate patterns → comment on javabytes#18 | issue #18 comment 6967181767 |
| FastMCP (PrefectHQ) | 4 steals; never swap protocol | memory + #18/#16 notes |
| jqknono script | Prior-art validation of junction workflow | research/stack-decision.md §6 |
| Steam Mover / LSE / RoboMirror / ChoEazyCopy / WinRoboCopy | Single-primitive tools; workflow layer unclaimed | PLAN.md §6 |
| modern-web-guidance (GoogleChrome) | **Adopted** — execution-quality layer, CLI on-demand | §8 below |

## 8. Execution-quality layer (adopted 2026-11-20)

**[GoogleChrome/modern-web-guidance](https://github.com/GoogleChrome/modern-web-guidance)** — 23,424★, Apache-2.0, stewarded by the Chrome/Edge/Firefox/MDN teams, actively maintained (pushed 2026-11-17). 262 modern web features + 204 real-world use-case guides, token-efficient (evals prune what models already know). CLI-driven, on-demand: `npx modern-web-guidance@latest install` (interactive — run in the Devvy session) / `search "<topic>"` / `retrieve "<id>"` / `legacy-scan .`.

Why it fits Devvy specifically: Devvy is Electron = bundled Chromium, so the modern APIs it teaches (view transitions, container queries, popover, `oklch`, anchor positioning, `:user-invalid`) are natively available — check each against Electron's Chromium version. A11y guides are part of the bar, not polish.

**Layering — four layers, no overlap:**

| Layer | Tool |
|---|---|
| Direction / taste (Devvy-specific) | `devvy-ui` skill + this folder |
| Ban filter (what NOT to ship) | `antislop-design` skill / unslop.site |
| Aesthetic principles | `frontend-design` skill (Anthropic official, already installed) |
| Platform-correct execution | `modern-web-guidance` CLI (search/retrieve/legacy-scan) |

Trending landscape checked 2026-11-20 (GitHub API, star-ranked; websearch quota exhausted): Ilm-Alan/frontend-design 179★ (eight aesthetic anchors) · ara-mkr/claude-artisan 84★ (224 styles) · AgriciDaniel/gogh 70★ (aggregates six design skills) · aladicf/better-web-ui 53★ · Moddingflow/better-design 52★ (MIT) · pbakaus/impeccable (independent notable, impeccable.style). All redundant with the four layers above for Devvy; consult if we ever want a style bank.
