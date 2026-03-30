import AppKit
import ServiceManagement
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let networkMonitor = NetworkMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.info("App launched")

        // Register to launch at login
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                Log.info("Registered for launch at login")
            } catch {
                Log.error("Failed to register launch at login: \(error)")
            }
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateMenuBarTitle()
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 340)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(monitor: networkMonitor)
        )

        networkMonitor.onUpdate = { [weak self] in
            self?.updateMenuBarTitle()
        }
        networkMonitor.startMonitoring()
        Log.info("Monitoring started")
    }

    private func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }
        let today = networkMonitor.todayTotal
        let totalBytes = today.bytesIn + today.bytesOut
        let formatted = ByteFormatter.format(totalBytes)

        let attachment = NSTextAttachment()
        attachment.image = NSImage(
            systemSymbolName: "arrow.up.arrow.down.circle.fill",
            accessibilityDescription: "Internet Tracker"
        )
        let imageSize = NSSize(width: 14, height: 14)
        attachment.bounds = CGRect(
            x: 0, y: -2, width: imageSize.width, height: imageSize.height
        )

        let attributedString = NSMutableAttributedString(attachment: attachment)
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        attributedString.append(NSAttributedString(
            string: " \(formatted)",
            attributes: [.font: font, .baselineOffset: 0.5]
        ))

        button.attributedTitle = attributedString
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

@main
struct InternetTrackerApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
