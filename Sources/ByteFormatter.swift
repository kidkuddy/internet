import Foundation

enum ByteFormatter {
    static func format(_ bytes: UInt64) -> String {
        let units: [(String, Double)] = [
            ("TB", 1_099_511_627_776),
            ("GB", 1_073_741_824),
            ("MB", 1_048_576),
            ("KB", 1_024),
        ]

        for (unit, threshold) in units {
            if Double(bytes) >= threshold {
                let value = Double(bytes) / threshold
                if value >= 100 {
                    return String(format: "%.0f %@", value, unit)
                } else if value >= 10 {
                    return String(format: "%.1f %@", value, unit)
                } else {
                    return String(format: "%.2f %@", value, unit)
                }
            }
        }

        return "\(bytes) B"
    }

    static func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1 {
            return "0 B/s"
        }
        return format(UInt64(bytesPerSec)) + "/s"
    }
}
