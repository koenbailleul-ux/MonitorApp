import SwiftUI
import AppKit

public struct ProcessesDetailView: View {
    @ObservedObject var monitor = SystemMonitorService.shared
    @State private var selectedSort: ProcessSortOption = .cpu
    
    private enum ProcessSortOption: String, CaseIterable, Identifiable {
        case cpu = "CPU"
        case memory = "Memory"
        case name = "Name"
        
        var id: String { rawValue }
    }
    
    private var processes: [ProcessItem] {
        switch selectedSort {
        case .cpu:
            return monitor.topCPUProcesses
        case .memory:
            return monitor.topMemoryProcesses
        case .name:
            var result: [ProcessItem] = []
            var seen = Set<pid_t>()
            for p in (monitor.topCPUProcesses + monitor.topMemoryProcesses) {
                if !seen.contains(p.id) {
                    seen.insert(p.id)
                    result.append(p)
                }
            }
            return result.sorted {
                if $0.isNotResponding != $1.isNotResponding {
                    return $0.isNotResponding && !$1.isNotResponding
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }
    
    private var notRespondingProcesses: [ProcessItem] {
        let cpuHung = monitor.topCPUProcesses.filter { $0.isNotResponding }
        let memHung = monitor.topMemoryProcesses.filter { $0.isNotResponding }
        var result: [ProcessItem] = []
        var seenPids = Set<pid_t>()
        for p in (cpuHung + memHung) {
            if !seenPids.contains(p.id) {
                seenPids.insert(p.id)
                result.append(p)
            }
        }
        return result
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // MARK: - Not Responding Banner (if any)
            if !notRespondingProcesses.isEmpty {
                GlassCard(padding: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Not Responding Programs (\(notRespondingProcesses.count))")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 0) {
                            ForEach(notRespondingProcesses) { proc in
                                ProcessRowView(item: proc, showMemory: selectedSort == .memory)
                                if proc.id != notRespondingProcesses.last?.id {
                                    Divider().opacity(0.1)
                                        .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
            }
            
            // MARK: - Process List Card (fills available vertical space)
            GlassCard(padding: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Active Processes", systemImage: "list.bullet.rectangle")
                            .font(.system(size: 12, weight: .bold))
                        
                        Spacer()
                        
                        // Segmented Selector
                        HStack(spacing: 2) {
                            ForEach(ProcessSortOption.allCases) { option in
                                Button(action: { selectedSort = option }) {
                                    Text(option.rawValue)
                                        .font(.system(size: 10.5, weight: selectedSort == option ? .semibold : .regular))
                                        .foregroundColor(selectedSort == option ? .primary : .secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(selectedSort == option ? Color(nsColor: .controlAccentColor).opacity(0.22) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(2)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                    }
                    
                    Divider().opacity(0.15)
                    
                    if processes.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("Sampling processes...")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 0) {
                                ForEach(processes) { proc in
                                    ProcessRowView(item: proc, showMemory: selectedSort == .memory)
                                    if proc.id != processes.last?.id {
                                        Divider().opacity(0.1)
                                            .padding(.vertical, 2)
                                    }
                                }
                            }
                            .padding(.trailing, 2)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // MARK: - Quick Action (bottom docked)
            GlassCard(padding: 8) {
                Button(action: openActivityMonitor) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.blue)
                        Text("Open Activity Monitor")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
