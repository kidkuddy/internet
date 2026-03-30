# Internet Tracker

macOS network usage tracker. Swift daemon collects data, Übersicht widget displays it.

## Architecture

Two components:

1. **Swift host app** (background daemon) — polls `getifaddrs()` every 10s, stores deltas in SQLite.
2. **Übersicht widget** (display) — reads SQLite, renders usage card on desktop.

### Host App (`InternetTracker/` + `Shared/`)

- **Entry point**: `InternetTracker/App.swift` — SwiftUI App with Settings scene. Runs as `LSUIElement` (no Dock icon). Registers for launch at login via `SMAppService`.
- **Network monitoring**: `InternetTracker/NetworkMonitor.swift` — polls `getifaddrs()` every 10 seconds. Reads cumulative byte counters from `en*` (WiFi/Ethernet) and `pdp_ip*` (cellular) interfaces. Computes deltas between readings.
- **Storage**: `Shared/Storage.swift` — SQLite3 (system library, zero deps). Uses App Group container for shared access.
- **Formatting**: `Shared/ByteFormatter.swift` — human-readable byte/speed formatting.
- **Logging**: `Shared/Logger.swift` — file + OS unified log.

### Übersicht Widget (`widgets/internet-tracker.jsx`)

- JSX widget that shells out to `sqlite3` to query usage data.
- Refreshes every 10 seconds.
- Renders a frosted glass card with today/month totals and up/down breakdown.

## Build & Run

```sh
make build     # Build with xcodebuild
make run       # Build + run
make install   # Copy .app to /Applications
make clean     # Remove build artifacts
make generate  # Regenerate .xcodeproj from project.yml
```

The Übersicht widget auto-loads from `~/Library/Application Support/Übersicht/widgets/`. Copy `widgets/internet-tracker.jsx` there, or symlink it.

## Logging & Debugging

- **File log**: `~/Library/Application Support/InternetTracker/app.log` — timestamped, leveled (INFO/ERROR/DEBUG).
- **OS log**: Also writes to unified logging (`Console.app`), subsystem `com.kidkuddy.internet-tracker`.
- **Watch live**: `tail -f ~/Library/Application\ Support/InternetTracker/app.log`
- **Console.app filter**: process = `InternetTracker`
- **Database**: `~/Library/Group Containers/7PJ2KBXD4T.com.kidkuddy.internet-tracker.group/usage.db` — inspect with `sqlite3`
- **Kill running instance**: `pkill -f InternetTracker`

## Database

Location: `~/Library/Group Containers/7PJ2KBXD4T.com.kidkuddy.internet-tracker.group/usage.db`

Fallback: `~/Library/Application Support/InternetTracker/usage.db`

Schema:
```sql
CREATE TABLE usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp REAL NOT NULL,      -- Unix epoch seconds
    bytes_in INTEGER NOT NULL,    -- download delta in bytes
    bytes_out INTEGER NOT NULL    -- upload delta in bytes
);
CREATE INDEX idx_usage_timestamp ON usage(timestamp);
```

## Key Design Decisions

- **`getifaddrs()` over `nettop`/`netstat`**: Direct C system call, no process spawning. Fast and reliable.
- **Delta-based storage**: System byte counters reset on reboot. We store deltas between polls, so reboots don't lose history.
- **Counter reset detection**: If a new reading is less than the previous one, we assume a reboot occurred and treat the new value as a fresh delta from zero.
- **10-second poll interval**: Balance between responsiveness and resource usage.
- **Übersicht over WidgetKit**: WidgetKit requires paid Apple Developer signing. Übersicht is free, scriptable, and works on macOS Tahoe without signing.
- **No external dependencies**: Host app uses only macOS system frameworks (AppKit, SwiftUI, SQLite3, Darwin, ServiceManagement).
- **Launch at login**: Uses `SMAppService.mainApp.register()` (macOS 13+). Requires the app to be in `/Applications` or signed.

## Future Ideas

- Per-app breakdown using `proc_pidinfo` or Network Extension
- Daily/weekly/monthly charts in the widget
- Usage alerts (e.g., "you've used 50 GB this month")
- Export data as CSV
- Log rotation (truncate/archive when log file gets large)
