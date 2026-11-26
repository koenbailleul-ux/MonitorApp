import SwiftUI
import AppKit

public struct MenuBarHoverZoomView: View {
    public let tab: InspectorTab
    @ObservedObject var monitor = SystemMonitorService.shared
    
    public init(tab: InspectorTab) {
        self.tab = tab
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch tab {
            case .cpu:
                cpuZoomedView
            case .memory:
                memoryZoomedView
            case .network:
                networkZoomedView
            default:
                EmptyView()
            }
        }
        .padding(14)
        .frame(width: 310)
        .background(LiquidGlassBackground(cornerRadius: 16))
    }
    
    // MARK: - CPU Zoomed View
    private var cpuZoomedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.20))
                        .frame(width: 26, height: 26)
                    Image(systemName: "cpu")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("CPU Load")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(.primary)
                    Text(monitor.cpuStats.chipName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary.opacity(0.80))
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", monitor.cpuStats.overallUsage))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.blue)
                    Text("%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
            }
            
            // Zoomed Sparkline Chart inside Liquid Glass Panel
            LiquidInnerCard {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("30s Load History")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary.opacity(0.92))
                        Spacer()
                        let peak = monitor.cpuStats.history.max() ?? 0.0
                        Text(String(format: "Peak: %.0f%%", peak))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(peak > 80 ? .orange : .primary.opacity(0.92))
                    }
                    
                    ZStack {
                        // Grid reference lines
                        VStack(spacing: 0) {
                            Divider().opacity(0.20)
                            Spacer()
                            Divider().opacity(0.12)
                            Spacer()
                            Divider().opacity(0.20)
                        }
                        
                        SparklineChartView(
                            data: monitor.cpuStats.history,
                            lineColor: .blue,
                            height: 52,
                            maxValue: 100.0
                        )
                    }
                    .frame(height: 52)
                }
            }
            
            // Breakdown Stats (High-Contrast Pills)
            HStack(spacing: 6) {
                BreakdownPill(title: "User", value: String(format: "%.1f%%", monitor.cpuStats.userUsage), valueColor: .blue)
                BreakdownPill(title: "System", value: String(format: "%.1f%%", monitor.cpuStats.systemUsage), valueColor: .purple)
                BreakdownPill(title: "Idle", value: String(format: "%.1f%%", monitor.cpuStats.idleUsage), valueColor: .primary.opacity(0.85))
            }
            
            // Mini core activity strip (first 8 cores)
            if !monitor.cpuStats.cores.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Active Cores (\(monitor.cpuStats.cores.count) Total)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary.opacity(0.90))
                        Spacer()
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(monitor.cpuStats.cores.prefix(8)) { core in
                            GeometryReader { geo in
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.primary.opacity(0.12))
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(coreColor(for: core))
                                        .frame(height: max(3, CGFloat(core.usage / 100.0) * geo.size.height))
                                }
                            }
                            .frame(height: 20)
                        }
                    }
                }
            }
            
            Divider().opacity(0.25)
            
            HStack {
                Text("Click to open full CPU Inspector")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.primary.opacity(0.72))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.primary.opacity(0.72))
            }
        }
    }
    
    // MARK: - Memory Zoomed View
    private var memoryZoomedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(monitor.memoryStats.pressureStatus.color.opacity(0.20))
                        .frame(width: 26, height: 26)
                    Image(systemName: "memorychip")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(monitor.memoryStats.pressureStatus.color)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Memory & RAM")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(.primary)
                    Text("\(SystemMonitorService.formatBytes(monitor.memoryStats.usedBytes)) of \(SystemMonitorService.formatBytes(monitor.memoryStats.totalBytes))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary.opacity(0.80))
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", monitor.memoryStats.usedPercentage))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(monitor.memoryStats.pressureStatus.color)
                    Text("%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(monitor.memoryStats.pressureStatus.color)
                }
            }
            
            // Zoomed Sparkline Chart inside Liquid Glass Panel
            LiquidInnerCard {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("30s Memory Trend")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary.opacity(0.92))
                        Spacer()
                        Text("Free: \(SystemMonitorService.formatBytes(monitor.memoryStats.freeBytes))")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    
                    ZStack {
                        VStack(spacing: 0) {
                            Divider().opacity(0.20)
                            Spacer()
                            Divider().opacity(0.12)
                            Spacer()
                            Divider().opacity(0.20)
                        }
                        
                        SparklineChartView(
                            data: monitor.memoryStats.history,
                            lineColor: monitor.memoryStats.pressureStatus.color,
                            height: 52,
                            maxValue: 100.0
                        )
                    }
                    .frame(height: 52)
                }
            }
            
            // Segmented Bar & Detailed Legend
            VStack(alignment: .leading, spacing: 4) {
                SegmentedProgressBar(
                    segments: [
                        MemorySegment(name: "Wired", bytes: monitor.memoryStats.wiredBytes, color: .purple),
                        MemorySegment(name: "Active", bytes: monitor.memoryStats.activeBytes, color: .blue),
                        MemorySegment(name: "Compressed", bytes: monitor.memoryStats.compressedBytes, color: .orange),
                        MemorySegment(name: "Free", bytes: monitor.memoryStats.freeBytes, color: .green.opacity(0.85))
                    ],
                    totalBytes: monitor.memoryStats.totalBytes,
                    height: 8
                )
                
                HStack {
                    HighContrastLegend(label: "Wired", value: SystemMonitorService.formatBytes(monitor.memoryStats.wiredBytes), color: .purple)
                    Spacer()
                    HighContrastLegend(label: "Active", value: SystemMonitorService.formatBytes(monitor.memoryStats.activeBytes), color: .blue)
                    Spacer()
                    HighContrastLegend(label: "Comp", value: SystemMonitorService.formatBytes(monitor.memoryStats.compressedBytes), color: .orange)
                    Spacer()
                    HighContrastLegend(label: "Free", value: SystemMonitorService.formatBytes(monitor.memoryStats.freeBytes), color: .green)
                }
                .padding(.top, 2)
            }
            
            Divider().opacity(0.25)
            
            HStack {
                Text("Click to open full Memory Inspector")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.primary.opacity(0.72))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.primary.opacity(0.72))
            }
        }
    }
    
    // MARK: - Network Zoomed View
    private var networkZoomedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.20))
                        .frame(width: 26, height: 26)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Network Activity")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(.primary)
                    Text("\(monitor.networkStats.interfaceName) • IP: \(monitor.networkStats.ipAddress)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary.opacity(0.80))
                }
                
                Spacer()
                
                Text(SystemMonitorService.formatThroughput(monitor.networkStats.downloadBytesPerSecond + monitor.networkStats.uploadBytesPerSecond))
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.cyan)
            }
            
            // Dual Zoomed Sparklines in Liquid Glass Cards
            HStack(spacing: 8) {
                // Download
                LiquidInnerCard {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 9.5))
                                .foregroundColor(.cyan)
                            Text("Download")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.primary.opacity(0.92))
                            Spacer()
                        }
                        
                        Text(SystemMonitorService.formatThroughput(monitor.networkStats.downloadBytesPerSecond))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.cyan)
                        
                        SparklineChartView(
                            data: monitor.networkStats.downloadHistory,
                            lineColor: .cyan,
                            height: 40
                        )
                    }
                }
                
                // Upload
                LiquidInnerCard {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 9.5))
                                .foregroundColor(.purple)
                            Text("Upload")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.primary.opacity(0.92))
                            Spacer()
                        }
                        
                        Text(SystemMonitorService.formatThroughput(monitor.networkStats.uploadBytesPerSecond))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.purple)
                        
                        SparklineChartView(
                            data: monitor.networkStats.uploadHistory,
                            lineColor: .purple,
                            height: 40
                        )
                    }
                }
            }
            
            // Cumulative totals
            HStack {
                Text("Total In: \(SystemMonitorService.formatBytes(monitor.networkStats.totalBytesDownloaded))")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
                Spacer()
                Text("Total Out: \(SystemMonitorService.formatBytes(monitor.networkStats.totalBytesUploaded))")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
            }
            
            Divider().opacity(0.25)
            
            HStack {
                Text("Click to open full Network Inspector")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.primary.opacity(0.72))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.primary.opacity(0.72))
            }
        }
    }
    
    private func coreColor(for core: CPUCoreInfo) -> Color {
        if core.usage > 80 {
            return .red
        } else if core.usage > 50 {
            return .orange
        } else {
            return core.type.color
        }
    }
}

// MARK: - Liquid Glass Background Component
public struct LiquidGlassBackground: View {
    public var cornerRadius: CGFloat = 16
    
    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        ZStack {
            // Native AppKit Vibrancy blur
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            
            // Tint base to ensure deep contrast against any wallpaper
            Color(nsColor: .windowBackgroundColor).opacity(0.72)
            
            // Liquid glass specular reflection gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(0.20),
                    Color.white.opacity(0.05),
                    Color.clear,
                    Color.black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Soft inner liquid glass rim / reflection border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            Color.white.opacity(0.15),
                            Color.clear,
                            Color.black.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Inner Liquid Glass Card for Charts & Meters
private struct LiquidInnerCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(9)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
                    
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.06),
                                Color.primary.opacity(0.06),
                                Color.black.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Mini High-Contrast Helper Components
private struct BreakdownPill: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(.primary.opacity(0.80))
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.50))
                
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.10), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.primary.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

private struct HighContrastLegend: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.primary.opacity(0.75))
            Text(value)
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)
        }
    }
}
