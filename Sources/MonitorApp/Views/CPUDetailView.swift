import SwiftUI

public struct CPUDetailView: View {
    @ObservedObject var monitor = SystemMonitorService.shared
    
    // 2-column adaptive grid for cores
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    // Super cores on top, followed by Performance cores, then Efficiency cores
    private var superCores: [CPUCoreInfo] {
        monitor.cpuStats.cores.filter { $0.type == .superCore }
    }
    
    private var performanceCores: [CPUCoreInfo] {
        monitor.cpuStats.cores.filter { $0.type == .performance }
    }
    
    private var efficiencyCores: [CPUCoreInfo] {
        monitor.cpuStats.cores.filter { $0.type == .efficiency }
    }
    
    private var standardCores: [CPUCoreInfo] {
        monitor.cpuStats.cores.filter { $0.type == .standard }
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // MARK: - Overview Card
                GlassCard {
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            CircularGaugeView(
                                value: monitor.cpuStats.overallUsage,
                                title: String(format: "%.0f%%", monitor.cpuStats.overallUsage),
                                subtitle: "CPU",
                                tintColor: Color.blue,
                                size: 84
                            )
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(monitor.cpuStats.chipName)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                                
                                HStack(spacing: 6) {
                                    CoreCountPill(title: "\(monitor.cpuStats.cores.count) Cores", color: .secondary)
                                    if monitor.cpuStats.superCount > 0 {
                                        CoreCountPill(title: "\(monitor.cpuStats.superCount) Super", color: CoreType.superCore.color)
                                    }
                                    if monitor.cpuStats.performanceCount > 0 {
                                        CoreCountPill(title: "\(monitor.cpuStats.performanceCount) Perf", color: CoreType.performance.color)
                                    }
                                    if monitor.cpuStats.efficiencyCount > 0 {
                                        CoreCountPill(title: "\(monitor.cpuStats.efficiencyCount) Eff", color: CoreType.efficiency.color)
                                    }
                                }
                                
                                Divider().opacity(0.3)
                                
                                HStack(spacing: 12) {
                                    StatLabel(title: "User", value: String(format: "%.1f%%", monitor.cpuStats.userUsage), color: .blue)
                                    StatLabel(title: "System", value: String(format: "%.1f%%", monitor.cpuStats.systemUsage), color: .purple)
                                    StatLabel(title: "Idle", value: String(format: "%.1f%%", monitor.cpuStats.idleUsage), color: .secondary)
                                }
                            }
                            Spacer()
                        }
                        
                        // History Sparkline
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("Usage History")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("30s")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            SparklineChartView(
                                data: monitor.cpuStats.history,
                                lineColor: .blue,
                                height: 58,
                                maxValue: 100.0
                            )
                        }
                    }
                }
                
                // MARK: - Cores Breakdown (Requirement: Super Cores displayed above Performance Cores)
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("CPU Cores & Architecture", systemImage: "cpu")
                                .font(.system(size: 12, weight: .bold))
                            
                            Spacer()
                            
                            Text("\(monitor.cpuStats.cores.count) Total Cores")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        // 1. Super Cores (Prominently displayed above)
                        if !superCores.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "bolt.shield.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(CoreType.superCore.color)
                                    Text("Super Cores (\(superCores.count))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(CoreType.superCore.color)
                                    Spacer()
                                }
                                .padding(.top, 2)
                                
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(superCores) { core in
                                        CoreMeterCard(core: core)
                                    }
                                }
                            }
                        }
                        
                        // 2. Performance Cores (Displayed below Super Cores)
                        if !performanceCores.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(CoreType.performance.color)
                                    Text("Performance Cores (\(performanceCores.count))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(CoreType.performance.color)
                                    Spacer()
                                }
                                .padding(.top, superCores.isEmpty ? 2 : 4)
                                
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(performanceCores) { core in
                                        CoreMeterCard(core: core)
                                    }
                                }
                            }
                        }
                        
                        // 3. Efficiency Cores (Displayed below Performance Cores if present)
                        if !efficiencyCores.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(CoreType.efficiency.color)
                                    Text("Efficiency Cores (\(efficiencyCores.count))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(CoreType.efficiency.color)
                                    Spacer()
                                }
                                .padding(.top, 4)
                                
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(efficiencyCores) { core in
                                        CoreMeterCard(core: core)
                                    }
                                }
                            }
                        }
                        
                        // 4. Standard Cores (Fallback for Intel or non-heterogeneous chips)
                        if !standardCores.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "cpu")
                                        .font(.system(size: 10))
                                        .foregroundColor(CoreType.standard.color)
                                    Text("Standard Cores (\(standardCores.count))")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(CoreType.standard.color)
                                    Spacer()
                                }
                                .padding(.top, (superCores.isEmpty && performanceCores.isEmpty && efficiencyCores.isEmpty) ? 2 : 4)
                                
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(standardCores) { core in
                                        CoreMeterCard(core: core)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Top CPU Processes
                if AppSettings.shared.showProcessList && !monitor.topCPUProcesses.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Top CPU Processes", systemImage: "flame.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Spacer()
                            }
                            
                            ForEach(monitor.topCPUProcesses) { proc in
                                ProcessRowView(item: proc, showMemory: false)
                                if proc.id != monitor.topCPUProcesses.last?.id {
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

// MARK: - Core Meter Card
private struct CoreMeterCard: View {
    let core: CPUCoreInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(core.name)
                    .font(.system(size: 11, weight: .semibold))
                
                Spacer()
                
                // Core Type Badge (Super, P-Core, E-Core)
                Text(core.type.badgeTitle)
                    .font(.system(size: 8.5, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(core.type.color.opacity(0.18))
                    .foregroundColor(core.type.color)
                    .clipShape(Capsule())
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(meterGradient(for: core.usage, typeColor: core.type.color))
                        .frame(width: max(0, CGFloat(core.usage / 100.0) * geo.size.width), height: 6)
                        .animation(.easeOut(duration: 0.2), value: core.usage)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text(core.type.displayName)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(String(format: "%.0f%%", core.usage))
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(core.usage > 80 ? .red : .primary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func meterGradient(for usage: Double, typeColor: Color) -> LinearGradient {
        if usage > 85 {
            return LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing)
        } else if usage > 60 {
            return LinearGradient(colors: [typeColor, Color.orange], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [typeColor.opacity(0.8), typeColor], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Mini Helper Views
private struct CoreCountPill: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.system(size: 9.5, weight: .semibold))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
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
