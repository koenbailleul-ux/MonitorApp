import SwiftUI

public struct NetworkDetailView: View {
    @ObservedObject var monitor = SystemMonitorService.shared
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // MARK: - Overview Gauge & Throughput Card
                GlassCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            CircularGaugeView(
                                value: monitor.networkStats.bandwidthUsagePercentage,
                                title: String(format: "%.0f%%", monitor.networkStats.bandwidthUsagePercentage),
                                subtitle: "NET",
                                tintColor: Color.cyan,
                                size: 84
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: monitor.networkStats.isWifi ? "wifi" : "cable.connector")
                                        .foregroundColor(.cyan)
                                    Text("\(monitor.networkStats.interfaceName) Active")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                
                                Text("IP: \(monitor.networkStats.ipAddress)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    StatLabel(
                                        title: "Download",
                                        value: SystemMonitorService.formatThroughput(monitor.networkStats.downloadBytesPerSecond),
                                        color: .cyan
                                    )
                                    StatLabel(
                                        title: "Upload",
                                        value: SystemMonitorService.formatThroughput(monitor.networkStats.uploadBytesPerSecond),
                                        color: .purple
                                    )
                                }
                            }
                            Spacer()
                        }
                    }
                }
                
                // MARK: - Download & Upload Live Meters
                HStack(spacing: 8) {
                    // Download Card
                    GlassCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.cyan)
                                    .font(.system(size: 13))
                                Text("Download")
                                    .font(.system(size: 11, weight: .semibold))
                                Spacer()
                            }
                            
                            Text(SystemMonitorService.formatThroughput(monitor.networkStats.downloadBytesPerSecond))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.cyan)
                            
                            SparklineChartView(
                                data: monitor.networkStats.downloadHistory,
                                lineColor: .cyan,
                                height: 30
                            )
                        }
                    }
                    
                    // Upload Card
                    GlassCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 13))
                                Text("Upload")
                                    .font(.system(size: 11, weight: .semibold))
                                Spacer()
                            }
                            
                            Text(SystemMonitorService.formatThroughput(monitor.networkStats.uploadBytesPerSecond))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.purple)
                            
                            SparklineChartView(
                                data: monitor.networkStats.uploadHistory,
                                lineColor: .purple,
                                height: 30
                            )
                        }
                    }
                }
                
                // MARK: - Interface Details
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Network Interface Details", systemImage: "network")
                            .font(.system(size: 12, weight: .bold))
                        
                        NetworkTableRow(
                            title: "Interface Name",
                            value: monitor.networkStats.interfaceName
                        )
                        Divider().opacity(0.15)
                        NetworkTableRow(
                            title: "IPv4 Address",
                            value: monitor.networkStats.ipAddress
                        )
                        Divider().opacity(0.15)
                        NetworkTableRow(
                            title: "Link Speed (Baud)",
                            value: formatBaudRate(monitor.networkStats.linkBaudRate)
                        )
                        Divider().opacity(0.15)
                        NetworkTableRow(
                            title: "Total Received",
                            value: SystemMonitorService.formatBytes(monitor.networkStats.totalBytesDownloaded)
                        )
                        Divider().opacity(0.15)
                        NetworkTableRow(
                            title: "Total Transmitted",
                            value: SystemMonitorService.formatBytes(monitor.networkStats.totalBytesUploaded)
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
    
    private func formatBaudRate(_ baud: UInt64) -> String {
        let bps = Double(baud)
        if bps >= 1_000_000_000 {
            return String(format: "%.1f Gbps", bps / 1_000_000_000.0)
        } else if bps >= 1_000_000 {
            return String(format: "%.0f Mbps", bps / 1_000_000.0)
        } else {
            return "\(baud) bps"
        }
    }
}

private struct NetworkTableRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
    }
}

private struct StatLabel: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(color)
        }
    }
}
