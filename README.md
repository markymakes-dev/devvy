# Devvy — Dev Drive Migration Studio

Moves your heavy folders — package caches, IDE data, SDKs, whole dev trees — onto a Windows 11 Dev Drive (or any fast second volume) and links them back in place. Plan you can see, resume you can trust, backup that fits in one file.

**Status: planning → M0 spike.**

- [`PLAN.md`](./PLAN.md) — full product plan (problem, safety model, features, architecture, milestones, risks)
- [`reference/`](./reference/) — 16 proven PowerShell/bash scripts from the hand-built migration this app generalizes (migrate, resume, sweep, setup, expand, backup, final-pass, diskpart recipes)

## Safety model (the differentiator)

Never delete-first (copy → verify → junction → then remove). Labels: **Safe / Review / Permanent**. Junction-aware with honest verification. Partial states are visible, resume is idempotent.

## Stack

Electron + React + TypeScript. Junctions need no admin (`fs.symlink('junction')`); UAC only for VHD ops, with baked parameters.
