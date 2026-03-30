import SwiftUI
import ServiceManagement

@main
struct InternetTrackerApp: App {
    @StateObject private var monitor = NetworkMonitor()

    init() {
        Log.info("Host app launched on macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")

        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                Log.info("Registered for launch at login")
            } catch {
                Log.error("Failed to register launch at login: \(error)")
            }
        }
    }

    var body: some Scene {
        // Invisible window — the host app just collects data in the background
        // The widget reads from the shared SQLite database
        Settings {
            VStack(spacing: 16) {
                Image(systemName: "network")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Internet Tracker")
                    .font(.title2.bold())
                Text("Running in background, collecting network data.")
                    .foregroundStyle(.secondary)

                let today = monitor.todayTotal
                let month = monitor.monthTotal
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today: \(ByteFormatter.format(today.bytesIn + today.bytesOut))")
                    Text("This month: \(ByteFormatter.format(month.bytesIn + month.bytesOut))")
                }
                .font(.system(.body, design: .monospaced))

                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(32)
            .frame(width: 320)
        }
    }
}
