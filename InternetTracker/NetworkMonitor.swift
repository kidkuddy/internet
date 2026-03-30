import Darwin
import Foundation

struct UsageSnapshot {
    let bytesIn: UInt64
    let bytesOut: UInt64
    var total: UInt64 { bytesIn + bytesOut }
}

struct SpeedReading: Sendable {
    let downloadBytesPerSec: Double
    let uploadBytesPerSec: Double
}

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var todayTotal = UsageSnapshot(bytesIn: 0, bytesOut: 0)
    @Published var monthTotal = UsageSnapshot(bytesIn: 0, bytesOut: 0)
    @Published var speed = SpeedReading(downloadBytesPerSec: 0, uploadBytesPerSec: 0)

    private let storage = Storage()
    private var timer: Timer?
    private var lastReading: (bytesIn: UInt64, bytesOut: UInt64, time: Date)?
    private var started = false

    init() {
        storage.initialize()
        refreshAggregates()

        let (bytesIn, bytesOut) = Self.readSystemBytes()
        Log.info("Initial reading: in=\(bytesIn) out=\(bytesOut)")
        lastReading = (bytesIn, bytesOut, Date())

        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
        Log.info("Monitoring started")
    }

    private func poll() {
        let (currentIn, currentOut) = Self.readSystemBytes()
        let now = Date()

        guard let last = lastReading else {
            lastReading = (currentIn, currentOut, now)
            return
        }

        let deltaIn: UInt64 = currentIn >= last.bytesIn ? currentIn - last.bytesIn : currentIn
        let deltaOut: UInt64 = currentOut >= last.bytesOut ? currentOut - last.bytesOut : currentOut

        let elapsed = now.timeIntervalSince(last.time)
        if elapsed > 0 {
            speed = SpeedReading(
                downloadBytesPerSec: Double(deltaIn) / elapsed,
                uploadBytesPerSec: Double(deltaOut) / elapsed
            )
        }

        if deltaIn > 0 || deltaOut > 0 {
            storage.recordUsage(bytesIn: deltaIn, bytesOut: deltaOut, at: now)
        }

        lastReading = (currentIn, currentOut, now)
        refreshAggregates()
    }

    private func refreshAggregates() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = 1
        let startOfMonth = calendar.date(from: components) ?? startOfDay

        let (dayIn, dayOut) = storage.totalUsage(since: startOfDay)
        let (monthIn, monthOut) = storage.totalUsage(since: startOfMonth)

        todayTotal = UsageSnapshot(bytesIn: dayIn, bytesOut: dayOut)
        monthTotal = UsageSnapshot(bytesIn: monthIn, bytesOut: monthOut)
    }

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
