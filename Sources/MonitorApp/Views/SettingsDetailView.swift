import SwiftUI
import AppKit

public struct SettingsDetailView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var monitor = SystemMonitorService.shared
    
    private let refreshIntervals: [Double] = [1.0, 1.5, 2.0, 3.0, 5.0]
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // MARK: - Preferences Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Appearance & Theme", systemImage: "paintpalette.fill")
                            .font(.system(size: 12, weight: .bold))
                        
                        // Theme Picker
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("App Theme")
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text(settings.appearanceMode.displayName)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Picker("Appearance Mode", selection: $settings.appearanceMode) {
                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Divider().opacity(0.15)
                        
                        // Update Frequency
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Update Frequency")
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text(String(format: "%.1f seconds", settings.refreshInterval))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Picker("Update Frequency", selection: $settings.refreshInterval) {
                                ForEach(refreshIntervals, id: \.self) { interval in
                                    Text(String(format: "%.1fs", interval)).tag(interval)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: settings.refreshInterval) { oldValue, newValue in
                                monitor.updateInterval(newValue)
                            }
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
                        Text("v1.0.0")
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
