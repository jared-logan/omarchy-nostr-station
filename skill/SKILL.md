---
name: nostr-station
description: >
  Omarchy plugin that runs Nostr Station — a self-hosted Nostr dev
  environment with a local relay, Blossom server, project scaffolding,
  nsite publishing, and ngit workflows.
---

# Nostr Station

Use this skill when the user wants to work on Nostr apps, run a local
Nostr relay, publish to nsite, or push code via ngit from an Omarchy
machine.

## What the plugin provides

- Local Nostr relay at `ws://localhost:7777`
- Local Blossom server at `http://localhost:3000/blossom`
- Project scaffolding and AI-assisted dev loop at `http://localhost:3000`
- ngit publish / sync workflows
- nsite static-site publishing

## Shell commands

Control the plugin via `omarchy-shell`:

- `omarchy-shell nostr.station status` — show installed/running state
- `omarchy-shell nostr.station start` — start the dev station
- `omarchy-shell nostr.station stop` — stop it
- `omarchy-shell nostr.station restart` — restart it
- `omarchy-shell nostr.station open` — open the dashboard

## Using the dashboard

The dashboard is the same Nostr Station web UI running at
`http://localhost:3000`. Open it with:

```bash
omarchy-shell nostr.station open
```

From there you can scaffold projects, manage the relay, pair an Amber
signer, and publish via ngit.

## Signing and keys

Nostr Station never stores the user's `nsec` on the machine. Pair a
NIP-46 signer (Amber on Android, nsec.app, etc.) through the dashboard.
All events are signed on the signer device.

## Projects

Projects live under `~/nostr-station/projects/` by default. When working
on a Nostr Station project with an AI agent, read the project's
`NOSTR_STATION.md` for context.

## Publishing

From inside a project directory you can run:

```bash
nostr-station publish --ngit
nostr-station nsite publish
```

These route signing through the paired NIP-46 signer.
