import SwiftUI
import AppKit

public struct ProcessRowView: View {
    public let item: ProcessItem
    public let showMemory: Bool
    
    public init(item: ProcessItem, showMemory: Bool = false) {
        self.item = item
        self.showMemory = showMemory
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
                    .foregroundColor(.secondary)
            }
            
            // Process Name & PID
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text("PID: \(item.id)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Metric Value
            if showMemory {
                Text(SystemMonitorService.formatBytes(item.memoryBytes))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
            } else {
                Text(String(format: "%.1f%%", item.cpuPercentage))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(item.cpuPercentage > 50 ? .red : (item.cpuPercentage > 20 ? .orange : .blue))
            }
        }
        .padding(.vertical, 3)
    }
}
