import SwiftUI

public struct MemoryDetailView: View {
    @ObservedObject var monitor = SystemMonitorService.shared
    
    private var memorySegments: [MemorySegment] {
        [
            MemorySegment(name: "Wired", bytes: monitor.memoryStats.wiredBytes, color: Color.purple),
            MemorySegment(name: "Active", bytes: monitor.memoryStats.activeBytes, color: Color.blue),
            MemorySegment(name: "Compressed", bytes: monitor.memoryStats.compressedBytes, color: Color.orange),
            MemorySegment(name: "Free", bytes: monitor.memoryStats.freeBytes, color: Color.green.opacity(0.8))
        ]
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // MARK: - Summary & Breakdown Card
                GlassCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            CircularGaugeView(
                                value: monitor.memoryStats.usedPercentage,
                                title: String(format: "%.0f%%", monitor.memoryStats.usedPercentage),
                                subtitle: "RAM",
                                tintColor: Color.teal,
                                size: 84
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Unified Memory")
                                    .font(.system(size: 13, weight: .bold))
                                
                                Text("\(SystemMonitorService.formatBytes(monitor.memoryStats.usedBytes)) used of \(SystemMonitorService.formatBytes(monitor.memoryStats.totalBytes))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    StatLabel(
                                        title: "Available",
                                        value: SystemMonitorService.formatBytes(monitor.memoryStats.freeBytes),
                                        color: .green
                                    )
                                    StatLabel(
                                        title: "Compressed",
                                        value: SystemMonitorService.formatBytes(monitor.memoryStats.compressedBytes),
                                        color: .orange
                                    )
                                }
                            }
                            Spacer()
                        }
                        
                        // Multi-Segment Bar
                        VStack(alignment: .leading, spacing: 4) {
                            SegmentedProgressBar(
                                segments: memorySegments,
                                totalBytes: monitor.memoryStats.totalBytes,
                                height: 8
                            )
                            
                            HStack {
                                LegendDot(title: "Wired", color: .purple)
                                Spacer()
                                LegendDot(title: "Active", color: .blue)
                                Spacer()
                                LegendDot(title: "Compressed", color: .orange)
                                Spacer()
                                LegendDot(title: "Free", color: .green)
                            }
                            .font(.system(size: 9))
                            .padding(.top, 2)
                        }
                    }
                }
                
                // MARK: - Required Focus Cards (Memory Pressure, Wired Memory, Swap)
                HStack(spacing: 8) {
                    // 1. Memory Pressure
                    GlassCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "gauge.with.needle.fill")
                                    .foregroundColor(monitor.memoryStats.pressureStatus.color)
                                    .font(.system(size: 13))
                                Text("Pressure")
                                    .font(.system(size: 11, weight: .semibold))
                                Spacer()
                                
                                // Pulsing status circle
                                Circle()
                                    .fill(monitor.memoryStats.pressureStatus.color)
                                    .frame(width: 8, height: 8)
                            }
                            
                            Text(monitor.memoryStats.pressureStatus.rawValue)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(monitor.memoryStats.pressureStatus.color)
                            
                            Text(String(format: "%.0f%% load", monitor.memoryStats.pressurePercentage))
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 2. Wired Memory
                    GlassCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 13))
                                Text("Wired")
                                    .font(.system(size: 11, weight: .semibold))
                                Spacer()
                            }
                            
                            Text(SystemMonitorService.formatBytes(monitor.memoryStats.wiredBytes))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.1f%% of RAM", monitor.memoryStats.wiredPercentage))
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 3. Swap Usage
                    GlassCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .foregroundColor(.indigo)
                                    .font(.system(size: 13))
                                Text("Swap")
                                    .font(.system(size: 11, weight: .semibold))
                                Spacer()
                            }
                            
                            Text(SystemMonitorService.formatBytes(monitor.memoryStats.swapUsedBytes))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(monitor.memoryStats.swapUsedBytes > 1024 * 1024 * 1024 ? .orange : .primary)
                            
                            Text("Total \(SystemMonitorService.formatBytes(monitor.memoryStats.swapTotalBytes))")
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Detailed Memory Metrics Table
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Memory Details", systemImage: "chart.bar.doc.horizontal.fill")
                            .font(.system(size: 12, weight: .bold))
                        
                        MemoryTableRow(
                            title: "Wired Memory",
                            subtitle: "Locked by kernel and drivers",
                            value: SystemMonitorService.formatBytes(monitor.memoryStats.wiredBytes),
                            color: .purple
                        )
                        Divider().opacity(0.15)
                        MemoryTableRow(
                            title: "Active Memory",
                            subtitle: "Used by running applications",
                            value: SystemMonitorService.formatBytes(monitor.memoryStats.activeBytes),
                            color: .blue
                        )
                        Divider().opacity(0.15)
                        MemoryTableRow(
                            title: "Inactive Memory",
                            subtitle: "Recently closed app cache",
                            value: SystemMonitorService.formatBytes(monitor.memoryStats.inactiveBytes),
                            color: .secondary
                        )
                        Divider().opacity(0.15)
                        MemoryTableRow(
                            title: "Compressed Memory",
                            subtitle: "Compacted RAM to avoid paging",
                            value: SystemMonitorService.formatBytes(monitor.memoryStats.compressedBytes),
                            color: .orange
                        )
                        Divider().opacity(0.15)
                        MemoryTableRow(
                            title: "Swap Memory",
                            subtitle: "Paged out to SSD disk",
                            value: "\(SystemMonitorService.formatBytes(monitor.memoryStats.swapUsedBytes)) used / \(SystemMonitorService.formatBytes(monitor.memoryStats.swapTotalBytes))",
                            color: .indigo
                        )
                    }
                }
                
                // MARK: - Top Memory Processes
                if AppSettings.shared.showProcessList && !monitor.topMemoryProcesses.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Top Memory Consumers", systemImage: "memorychip")
                                    .font(.system(size: 12, weight: .bold))
                                Spacer()
                            }
                            
                            ForEach(monitor.topMemoryProcesses) { proc in
                                ProcessRowView(item: proc, showMemory: true)
                                if proc.id != monitor.topMemoryProcesses.last?.id {
                                    Divider().opacity(0.15)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Subcomponents
private struct LegendDot: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 5.5, height: 5.5)
            Text(title)
                .foregroundColor(.secondary)
        }
    }
}

private struct MemoryTableRow: View {
    let title: String
    let subtitle: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(color)
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
