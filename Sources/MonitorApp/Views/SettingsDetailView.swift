import SwiftUI
import AppKit

public struct SettingsDetailView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var monitor = SystemMonitorService.shared
    
    private let refreshIntervals: [Double] = [1.0, 1.5, 2.0, 3.0, 5.0]
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // MARK: - Menu Bar Representation Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Menu Bar Representation", systemImage: "menubar.rectangle")
                            .font(.system(size: 12, weight: .bold))
                        
                        // Preset / Master Display Style
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Display Style")
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text(settings.menuBarStyle.displayName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 3) {
                                ForEach(MenuBarDisplayStyle.allCases, id: \.self) { style in
                                    Button(action: {
                                        settings.menuBarStyle = style
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: style.iconName)
                                                .font(.system(size: 9.5))
                                            Text(style.shortName)
                                                .font(.system(size: 10.5, weight: settings.menuBarStyle == style ? .semibold : .regular))
                                        }
                                        .foregroundColor(settings.menuBarStyle == style ? .primary : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(settings.menuBarStyle == style ? Color(nsColor: .controlAccentColor).opacity(0.22) : Color.clear)
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
                        
                        // Individual Per-Metric Styles
                        VStack(spacing: 6) {
                            MetricStyleRow(
                                title: "CPU Metric",
                                icon: "cpu",
                                tintColor: .blue,
                                selection: $settings.cpuDisplayStyle
                            )
                            MetricStyleRow(
                                title: "Memory Metric",
                                icon: "memorychip",
                                tintColor: .green,
                                selection: $settings.memoryDisplayStyle
                            )
                            MetricStyleRow(
                                title: "Network Metric",
                                icon: "arrow.up.arrow.down",
                                tintColor: .cyan,
                                selection: $settings.networkDisplayStyle
                            )
                        }
                        .padding(.top, 2)
                        
                        Divider().opacity(0.15)
                        
                        // Hover Zoomed View Toggle
                        Toggle(isOn: $settings.enableHoverZoom) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkle.magnifyingglass")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 11))
                                    Text("Show Zoomed View on Hover")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                Text("Display enlarged real-time sparkline graph and metrics when hovering over the menu bar")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }
                
                // MARK: - Preferences Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Appearance & Theme", systemImage: "paintpalette.fill")
                            .font(.system(size: 12, weight: .bold))
                        
                        // Theme Picker
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("App Theme")
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text(settings.appearanceMode.displayName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 3) {
                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        settings.appearanceMode = mode
                                    }) {
                                        Text(mode.shortName)
                                            .font(.system(size: 10.5, weight: settings.appearanceMode == mode ? .semibold : .regular))
                                            .foregroundColor(settings.appearanceMode == mode ? .primary : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .fill(settings.appearanceMode == mode ? Color(nsColor: .controlAccentColor).opacity(0.22) : Color.clear)
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
                        
                        // Update Frequency
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Update Frequency")
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text(String(format: "%.1f seconds", settings.refreshInterval))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 3) {
                                ForEach(refreshIntervals, id: \.self) { interval in
                                    Button(action: {
                                        settings.refreshInterval = interval
                                        monitor.updateInterval(interval)
                                    }) {
                                        Text(String(format: "%.1fs", interval))
                                            .font(.system(size: 10.5, weight: settings.refreshInterval == interval ? .semibold : .regular))
                                            .foregroundColor(settings.refreshInterval == interval ? .primary : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .fill(settings.refreshInterval == interval ? Color(nsColor: .controlAccentColor).opacity(0.22) : Color.clear)
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
                        
                        // Network Menu Bar Display
                        Toggle(isOn: $settings.showNetworkAsPercentage) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Display Network in Percentage")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Show network as % of link bandwidth or raw KB/s")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Divider().opacity(0.15)
                        
                        // Process List
                        Toggle(isOn: $settings.showProcessList) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Top Processes")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Display top CPU and RAM processes in views")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }
                
                // MARK: - Quick Actions Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Quick Actions", systemImage: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                        
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
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        
                        Divider().opacity(0.15)
                        
                        Button(action: quitApp) {
                            HStack {
                                Image(systemName: "power")
                                    .foregroundColor(.red)
                                Text("Quit MonitorApp")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.red)
                                Spacer()
                                Text("⌘Q")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // MARK: - About Card
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MonitorApp")
                                .font(.system(size: 12, weight: .bold))
                            Text("Right-click menu bar item for context menu")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("v1.2.0")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
    
    private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

private struct MetricStyleRow: View {
    let title: String
    let icon: String
    let tintColor: Color
    @Binding var selection: MenuBarDisplayStyle
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(tintColor)
                .frame(width: 14)
            
            Text(title)
                .font(.system(size: 10.5, weight: .medium))
            
            Spacer()
            
            HStack(spacing: 2) {
                ForEach(MenuBarDisplayStyle.allCases, id: \.self) { style in
                    Button(action: {
                        selection = style
                    }) {
                        Text(style.shortName)
                            .font(.system(size: 9.5, weight: selection == style ? .semibold : .regular))
                            .foregroundColor(selection == style ? .primary : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(selection == style ? Color(nsColor: .controlAccentColor).opacity(0.20) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(1.5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }
}
