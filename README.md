# Nostr Station — Omarchy Plugin

Self-hosted Nostr dev station for the Omarchy desktop. Brings a local
relay, Blossom server, project scaffolding, nsite publishing, and ngit
workflows into Omarchy without rebuilding the existing web UI.

## Install

```bash
omarchy plugin add https://github.com/jared-logan/omarchy-nostr-station.git --enable
```

The plugin will install [nostr-station](https://github.com/jared-logan/nostr-station)
automatically the first time you start it.

## Usage

A "NS" icon appears in the Omarchy bar. Click it to open the control panel:

- **Start** — boots the in-process relay, Blossom server, and dashboard.
- **Stop** — cleanly shuts everything down.
- **Restart** — stop + start.
- **Open Dashboard** — opens the existing nostr-station dashboard as an
  Omarchy web app.

The first time you start it, the plugin downloads and builds nostr-station
in `~/nostr-station`. Subsequent starts are instant.

## Shell IPC

Agents and scripts can control the plugin via `omarchy-shell`:

```bash
omarchy-shell nostr.station status
omarchy-shell nostr.station start
omarchy-shell nostr.station stop
omarchy-shell nostr.station restart
omarchy-shell nostr.station open
```

## Identity and signing

Nostr Station keeps doing what it already does: your `nsec` never touches
the machine. Pair Amber (or any NIP-46 signer) from the dashboard, and all
signing flows through your phone.

## License

MIT
