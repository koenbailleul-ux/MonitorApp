import SwiftUI
import AppKit

public struct PopoverContentView: View {
    @ObservedObject var manager = MenuBarManager.shared
    @ObservedObject var monitor = SystemMonitorService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Bar & Tab Selector
            VStack(spacing: 8) {
                // Top Tab Bar
                HStack(spacing: 4) {
                    TabPillButton(
                        tab: .cpu,
                        selectedTab: $manager.currentTab,
                        title: "CPU",
                        icon: "cpu",
                        badge: monitor.cpuPercentString,
                        tintColor: .blue
                    )
                    
                    TabPillButton(
                        tab: .memory,
                        selectedTab: $manager.currentTab,
                        title: "Memory",
                        icon: "memorychip",
                        badge: monitor.memoryPercentString,
                        tintColor: .teal
                    )
                    
                    TabPillButton(
                        tab: .network,
                        selectedTab: $manager.currentTab,
                        title: "Network",
                        icon: "arrow.up.arrow.down",
                        badge: AppSettings.shared.showNetworkAsPercentage ? monitor.networkPercentString : monitor.networkRateString,
                        tintColor: .cyan
                    )
                    
                    Button(action: {
                        manager.currentTab = .settings
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(manager.currentTab == .settings ? .primary : .secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(manager.currentTab == .settings ? Color.primary.opacity(0.12) : Color.clear)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                Divider().opacity(0.2)
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
            
            // MARK: - Body Content
            Group {
                switch manager.currentTab {
                case .cpu:
                    CPUDetailView()
                case .memory:
                    MemoryDetailView()
                case .network:
                    NetworkDetailView()
                case .settings:
                    SettingsDetailView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // MARK: - Bottom Utility Bar & Resize Handle
            VStack(spacing: 0) {
                Divider().opacity(0.15)
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Live Monitoring")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(monitor.cpuStats.chipName) • \(monitor.cpuStats.cores.count) Cores")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 2)
                
                // Visual Resize Grabber Handle
                ResizeGripRepresentable()
                    .frame(height: 14)
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.45))
        }
        .frame(width: 375)
        .frame(minHeight: 320, maxHeight: .infinity)
        .background(VisualEffectView())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Bottom Resize Grip View
final class ResizeGripView: NSView {
    private var initialHeight: CGFloat = 0.0
    private var initialMouseScreenY: CGFloat = 0.0
    
    override var isFlipped: Bool { true }
    
    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .resizeUpDown)
    }
    
    override func mouseDown(with event: NSEvent) {
        initialHeight = CGFloat(AppSettings.shared.popupHeight)
        initialMouseScreenY = NSEvent.mouseLocation.y
    }
    
    override func mouseDragged(with event: NSEvent) {
        let currentMouseScreenY = NSEvent.mouseLocation.y
        let delta = initialMouseScreenY - currentMouseScreenY
        let newHeight = initialHeight + delta
        MenuBarManager.shared.resizePanel(newHeight: newHeight)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let w: CGFloat = 36.0
        let h: CGFloat = 4.0
        let rect = NSRect(x: (bounds.width - w) / 2.0, y: (bounds.height - h) / 2.0, width: w, height: h)
        let path = NSBezierPath(roundedRect: rect, xRadius: 2.0, yRadius: 2.0)
        NSColor.secondaryLabelColor.withAlphaComponent(0.35).setFill()
        path.fill()
    }
}

struct ResizeGripRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> ResizeGripView {
        ResizeGripView()
    }
    func updateNSView(_ nsView: ResizeGripView, context: Context) {}
}

// MARK: - Tab Button Component (Instant click responsiveness & complete contentShape)
private struct TabPillButton: View {
    let tab: InspectorTab
    @Binding var selectedTab: InspectorTab
    let title: String
    let icon: String
    let badge: String
    let tintColor: Color
    
    private var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? tintColor : .secondary)
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text(badge)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(isSelected ? tintColor.opacity(0.2) : Color.primary.opacity(0.06))
                    .foregroundColor(isSelected ? tintColor : .secondary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle()) // Entire rectangular pill area is clickable
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AppKit Visual Effect Blur
public struct VisualEffectView: NSViewRepresentable {
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .popover
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
