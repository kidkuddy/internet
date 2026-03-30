# Internet Tracker

A lightweight macOS network usage tracker. A background Swift app collects data, and an [Übersicht](https://tracesof.net/uebersicht/) widget displays it on your desktop.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange) ![Zero Dependencies](https://img.shields.io/badge/dependencies-0-green)

## Features

- **Desktop widget** — frosted glass card showing usage at a glance
- **Today & month totals** — download and upload broken down
- **Persistent history** — usage stored in local SQLite database, survives reboots
- **Zero dependencies** — host app uses only macOS system frameworks
- **Lightweight** — background daemon + shell-based widget, no Electron

## Install

### Prerequisites

- Xcode Command Line Tools (Swift 5.9+, macOS 14+)
- [Übersicht](https://tracesof.net/uebersicht/) (`brew install --cask ubersicht`)

### Setup

```sh
git clone https://github.com/kidkuddy/internet.git
cd internet
make install
```

Then copy the widget:

```sh
cp widgets/internet-tracker.jsx ~/Library/Application\ Support/Übersicht/widgets/
```

Launch `InternetTracker.app` from `/Applications` — it runs in the background with no Dock icon, collecting network data. The Übersicht widget reads from its database and updates every 10 seconds.

## Build from Source

```sh
make generate  # Generate .xcodeproj from project.yml (requires xcodegen)
make build     # Build release
make run       # Build and run
make install   # Install to /Applications
make clean     # Clean build artifacts
```

## How It Works

The host app reads network interface byte counters via `getifaddrs()` every 10 seconds, computes deltas, and stores them in SQLite. The Übersicht widget queries the database with `sqlite3` and renders the results.

Counter resets from reboots are handled automatically — if a new reading is smaller than the previous one, it's treated as a fresh start.

## Data Location

- **Database**: `~/Library/Group Containers/7PJ2KBXD4T.com.kidkuddy.internet-tracker.group/usage.db`
- **Logs**: `~/Library/Application Support/InternetTracker/app.log`
- **No network requests** — the app only reads local network interface stats

## License

MIT
