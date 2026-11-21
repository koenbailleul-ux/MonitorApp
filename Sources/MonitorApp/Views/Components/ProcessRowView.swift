import SwiftUI
import AppKit

public struct ProcessRowView: View {
    public let item: ProcessItem
    public let showMemory: Bool
    @State private var isHovered = false
    @State private var isKillHovered = false
    
    public init(item: ProcessItem, showMemory: Bool = false) {
        self.item = item
        self.showMemory = showMemory
        self._isHovered = State(initialValue: false)
        self._isKillHovered = State(initialValue: false)
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // App Icon
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(item.isNotResponding ? .red : .secondary)
            }
            
            // Process Name, Not Responding Badge & PID
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 11, weight: item.isNotResponding ? .bold : .medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(item.isNotResponding ? Color(red: 1.0, green: 0.30, blue: 0.30) : .primary)
                    
                    if item.isNotResponding {
                        Text("Not Responding")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text("PID: \(item.id)")
                    .font(.system(size: 9))
                    .foregroundColor(item.isNotResponding ? Color.red.opacity(0.8) : .secondary)
            }
            
            Spacer()
            
            // Metric Value
            if showMemory {
                Text(SystemMonitorService.formatBytes(item.memoryBytes))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(item.isNotResponding ? Color(red: 1.0, green: 0.30, blue: 0.30) : .primary)
            } else {
                Text(String(format: "%.1f%%", item.cpuPercentage))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(item.isNotResponding ? Color(red: 1.0, green: 0.30, blue: 0.30) : (item.cpuPercentage > 50 ? .red : (item.cpuPercentage > 20 ? .orange : .blue)))
            }
            
            // Kill App Button (round button with a cross in it)
            Button(action: {
                SystemMonitorService.shared.killProcess(pid: item.id)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isKillHovered || item.isNotResponding ? Color.red : Color.secondary.opacity(0.6))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .onHover { isKillHovered = $0 }
            .help("Kill \(item.name) (PID: \(item.id))")
        }
        .padding(.vertical, 1.5)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(item.isNotResponding ? Color.red.opacity(0.12) : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
        )
        .onHover { isHovered = $0 }
    }
}
