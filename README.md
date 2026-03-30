# Internet Tracker

A lightweight macOS menu bar app that tracks your network usage. Shows how much data you've used today and this month, with a live speed indicator.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9+-orange) ![Zero Dependencies](https://img.shields.io/badge/dependencies-0-green)

## Features

- **Menu bar display** — shows total data used today, always visible
- **Today & month totals** — download and upload broken down
- **Live speed** — current download/upload speed updated every 10 seconds
- **Persistent history** — usage stored in local SQLite database, survives reboots
- **Zero dependencies** — uses only macOS system frameworks
- **Lightweight** — no Electron, no web views, pure native Swift

## Install

```sh
git clone https://github.com/kidkuddy/internet.git
cd internet
make install
```

This builds a release binary and copies `InternetTracker.app` to `/Applications`.

## Usage

Launch from `/Applications/InternetTracker.app` or run directly:

```sh
make run
```

Click the menu bar icon to see the popover with detailed usage stats.

## Build from Source

Requires Xcode Command Line Tools (Swift 5.9+, macOS 14+).

```sh
make build   # Build .app bundle
make run     # Build and run
make install # Install to /Applications
make clean   # Clean build artifacts
```

## How It Works

The app reads network interface byte counters directly via the `getifaddrs()` system call every 10 seconds. It computes the delta between readings and stores them in a local SQLite database at `~/Library/Application Support/InternetTracker/usage.db`.

Counter resets (from reboots) are detected automatically — if a new reading is smaller than the previous one, it's treated as a fresh start rather than a massive negative delta.

## Data Location

All data is stored locally:
- **Database**: `~/Library/Application Support/InternetTracker/usage.db`
- **No network requests** — the app only reads your local network interface stats

## License

MIT
