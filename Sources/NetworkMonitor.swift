import Darwin
import Foundation

struct UsageSnapshot: Sendable {
    let bytesIn: UInt64
    let bytesOut: UInt64
    let timestamp: Date
}

struct SpeedReading: Sendable {
    let downloadBytesPerSec: Double
    let uploadBytesPerSec: Double
}

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var todayTotal = UsageSnapshot(bytesIn: 0, bytesOut: 0, timestamp: Date())
    @Published var monthTotal = UsageSnapshot(bytesIn: 0, bytesOut: 0, timestamp: Date())
    @Published var speed = SpeedReading(downloadBytesPerSec: 0, uploadBytesPerSec: 0)

    private let storage = Storage()
    private var timer: Timer?
    private var lastReading: (bytesIn: UInt64, bytesOut: UInt64, time: Date)?

    var onUpdate: (() -> Void)?

    func startMonitoring() {
        storage.initialize()
        refreshAggregates()

        // Take initial reading to establish baseline
        let (bytesIn, bytesOut) = Self.readSystemBytes()
        lastReading = (bytesIn, bytesOut, Date())

        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    private func poll() {
        let (currentIn, currentOut) = Self.readSystemBytes()
        let now = Date()

        guard let last = lastReading else {
            lastReading = (currentIn, currentOut, now)
            return
        }

        // Detect counter reset (reboot) — if current < last, counters wrapped
        let deltaIn: UInt64
        let deltaOut: UInt64

        if currentIn >= last.bytesIn {
            deltaIn = currentIn - last.bytesIn
        } else {
            // Counter reset — treat current as the delta from zero
            deltaIn = currentIn
        }

        if currentOut >= last.bytesOut {
            deltaOut = currentOut - last.bytesOut
        } else {
            deltaOut = currentOut
        }

        let elapsed = now.timeIntervalSince(last.time)

        // Update live speed
        if elapsed > 0 {
            speed = SpeedReading(
                downloadBytesPerSec: Double(deltaIn) / elapsed,
                uploadBytesPerSec: Double(deltaOut) / elapsed
            )
        }

        // Only store if there's actual traffic (ignore noise)
        if deltaIn > 0 || deltaOut > 0 {
            storage.recordUsage(bytesIn: deltaIn, bytesOut: deltaOut, at: now)
        }

        lastReading = (currentIn, currentOut, now)
        refreshAggregates()
        onUpdate?()
    }

    private func refreshAggregates() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        let startOfMonth = calendar.date(from: components) ?? startOfDay

        let (dayIn, dayOut) = storage.totalUsage(since: startOfDay)
        let (monthIn, monthOut) = storage.totalUsage(since: startOfMonth)

        todayTotal = UsageSnapshot(bytesIn: dayIn, bytesOut: dayOut, timestamp: now)
        monthTotal = UsageSnapshot(bytesIn: monthIn, bytesOut: monthOut, timestamp: now)
    }

    /// Reads cumulative byte counters from all active network interfaces
    nonisolated static func readSystemBytes() -> (bytesIn: UInt64, bytesOut: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let ptr = cursor {
            let iface = ptr.pointee
            let name = String(cString: iface.ifa_name)

            // en* = WiFi/Ethernet, pdp_ip* = cellular, utun* = VPN tunnels
            let isRelevant = name.hasPrefix("en") || name.hasPrefix("pdp_ip")

            if isRelevant, let data = iface.ifa_data,
               iface.ifa_addr?.pointee.sa_family == UInt8(AF_LINK) {
                let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                totalIn += UInt64(networkData.ifi_ibytes)
                totalOut += UInt64(networkData.ifi_obytes)
            }

            cursor = iface.ifa_next
        }

        return (totalIn, totalOut)
    }
}
