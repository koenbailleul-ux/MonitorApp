import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app (no Dock icon, status bar only)
        NSApp.setActivationPolicy(.accessory)
        
        // Restore user's appearance preference
        AppSettings.shared.applyAppearance()
        
        // Start monitor service
        SystemMonitorService.shared.start()
        
        // Initialize Menu Bar UI
        self.menuBarManager = MenuBarManager.shared
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        SystemMonitorService.shared.stop()
    }
}
