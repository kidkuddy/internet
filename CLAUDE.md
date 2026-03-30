# Internet Tracker

macOS menu bar app that tracks network usage. Built with Swift, AppKit, and SwiftUI.

## Architecture

- **Entry point**: `Sources/App.swift` — sets up `NSStatusItem` (menu bar icon) + `NSPopover` (click panel). Uses `.accessory` activation policy to hide from Dock.
- **Network monitoring**: `Sources/NetworkMonitor.swift` — polls `getifaddrs()` every 10 seconds to read cumulative byte counters from network interfaces (`en*` for WiFi/Ethernet, `pdp_ip*` for cellular). Computes deltas between readings and stores them.
- **Storage**: `Sources/Storage.swift` — SQLite3 (system library, zero deps). Stores usage deltas in `~/Library/Application Support/InternetTracker/usage.db`. Single table: `usage(timestamp, bytes_in, bytes_out)`.
- **UI**: `Sources/PopoverView.swift` — SwiftUI views hosted in `NSHostingController`. Shows today total, month total, and live speed.
- **Formatting**: `Sources/ByteFormatter.swift` — human-readable byte/speed formatting.

## Build & Run

```sh
make build   # Builds release binary + .app bundle
make run     # Build + run directly
make install # Copy .app to /Applications
make clean   # Remove build artifacts
```

The Makefile wraps `swift build -c release` and assembles the `.app` bundle with `Info.plist` (required for `LSUIElement` to hide Dock icon).

## Key Design Decisions

- **`getifaddrs()` over `nettop`/`netstat`**: Direct C system call, no process spawning. Fast and reliable.
- **Delta-based storage**: System byte counters reset on reboot. We store deltas between polls, so reboots don't lose history.
- **Counter reset detection**: If a new reading is less than the previous one, we assume a reboot occurred and treat the new value as a fresh delta from zero.
- **10-second poll interval**: Balance between responsiveness and resource usage. Aggregates to SQLite every poll.
- **No external dependencies**: Uses only macOS system frameworks (AppKit, SwiftUI, SQLite3, Darwin, ServiceManagement).
- **Launch at login**: Uses `SMAppService.mainApp.register()` (macOS 13+). Requires the app to be in `/Applications` or signed.

## Logging & Debugging

- **File log**: `~/Library/Application Support/InternetTracker/app.log` — timestamped, leveled (INFO/ERROR/DEBUG).
- **OS log**: Also writes to unified logging (`Console.app`), subsystem `com.kidkuddy.internet-tracker`.
- **Watch live**: `tail -f ~/Library/Application\ Support/InternetTracker/app.log`
- **Console.app filter**: process = `InternetTracker`
- **Database**: `~/Library/Application Support/InternetTracker/usage.db` — inspect with `sqlite3`
- **Kill running instance**: `pkill -f InternetTracker`

## Database

Location: `~/Library/Application Support/InternetTracker/usage.db`

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

## Future Ideas

- Per-app breakdown using `proc_pidinfo` or Network Extension
- Daily/weekly/monthly charts in the popover
- Usage alerts (e.g., "you've used 50 GB this month")
- Export data as CSV
- Log rotation (truncate/archive when log file gets large)
