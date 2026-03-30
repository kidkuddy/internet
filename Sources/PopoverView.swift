import SwiftUI

struct PopoverView: View {
    @ObservedObject var monitor: NetworkMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "network")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Internet Tracker")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 12)

            // Today
            UsageSection(
                title: "TODAY",
                icon: "calendar",
                bytesIn: monitor.todayTotal.bytesIn,
                bytesOut: monitor.todayTotal.bytesOut
            )

            Divider()
                .padding(.horizontal, 12)

            // This Month
            UsageSection(
                title: "THIS MONTH",
                icon: "calendar.badge.clock",
                bytesIn: monitor.monthTotal.bytesIn,
                bytesOut: monitor.monthTotal.bytesOut
            )

            Divider()
                .padding(.horizontal, 12)

            // Live Speed
            VStack(alignment: .leading, spacing: 8) {
                Label("LIVE", systemImage: "bolt.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)

                HStack(spacing: 20) {
                    SpeedIndicator(
                        direction: "arrow.down",
                        label: ByteFormatter.formatSpeed(monitor.speed.downloadBytesPerSec),
                        color: .blue
                    )
                    SpeedIndicator(
                        direction: "arrow.up",
                        label: ByteFormatter.formatSpeed(monitor.speed.uploadBytesPerSec),
                        color: .orange
                    )
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Spacer()

            Divider()
                .padding(.horizontal, 12)

            // Footer
            HStack {
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 300, height: 340)
    }
}

struct UsageSection: View {
    let title: String
    let icon: String
    let bytesIn: UInt64
    let bytesOut: UInt64

    private var total: UInt64 { bytesIn + bytesOut }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)

            Text(ByteFormatter.format(total))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.blue)
                    Text(ByteFormatter.format(bytesIn))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                    Text(ByteFormatter.format(bytesOut))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SpeedIndicator: View {
    let direction: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}
