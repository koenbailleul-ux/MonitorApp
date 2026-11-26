import AppKit
import SwiftUI

@MainActor
public final class MenuBarManager: NSObject, ObservableObject, NSMenuDelegate, NSWindowDelegate {
    public static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem!
    private var statusView: MenuBarStatusView!
    private var panel: NSPanel!
    private var contextMenu: NSMenu?
    
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    @Published public var currentTab: InspectorTab = .cpu
    public private(set) var isPanelShown: Bool = false
    private var pinnedTopY: CGFloat = 0.0
    private var panelContentInstalled: Bool = false
    
    public override init() {
        super.init()
        setupStatusItem()
        setupPanel()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem.button else { return }
        
        let initialWidth: CGFloat = 200.0
        let initialHeight: CGFloat = 22.0
        
        statusView = MenuBarStatusView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight))
        statusView.autoresizingMask = [.width, .height]
        
        statusView.onSectionClicked = { [weak self] tab, rect in
            self?.handleSectionClicked(tab: tab, rect: rect)
        }
        
        statusView.onRightClicked = { [weak self] in
            self?.showContextMenu()
        }
        
        statusView.onSizeChanged = { [weak self] newWidth in
            self?.statusItem.length = newWidth
        }
        
        button.addSubview(statusView)
        statusView.updateLayout()
        statusItem.length = statusView.frame.width
    }
    
    private func setupPanel() {
        let initialHeight = CGFloat(AppSettings.shared.popupHeight)
        
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 375, height: initialHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        panel.minSize = NSSize(width: 375, height: 320)
        panel.maxSize = NSSize(width: 375, height: 1000)
        panel.delegate = self
        // NOTE: contentView is NOT set here to avoid recursive MenuBarManager.shared access.
        // It is installed lazily on first openPanel() call.
    }
    
    /// Install SwiftUI content into the panel on first use (avoids init-time recursion).
    private func installPanelContentIfNeeded() {
        guard !panelContentInstalled else { return }
        panelContentInstalled = true
        let contentView = PopoverContentView()
        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView
    }
    
    public func handleSectionClicked(tab: InspectorTab, rect: NSRect) {
        MenuBarHoverManager.shared.hide(immediate: true)
        if isPanelShown {
            if currentTab == tab {
                closePanel()
                return
            } else {
                currentTab = tab
                statusView.setActiveTab(tab)
                return
            }
        }
        
        currentTab = tab
        statusView.setActiveTab(tab)
        openPanel(relativeTo: rect)
    }
    
    private func openPanel(relativeTo rect: NSRect) {
        installPanelContentIfNeeded()
        let mouseLoc = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) })
            ?? statusItem.button?.window?.screen
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        
        let menuBarBottomY = screen.visibleFrame.maxY
        let panelWidth: CGFloat = 375.0
        let panelHeight = CGFloat(AppSettings.shared.popupHeight)
        
        // Pin top 6 points below the menu bar
        let topY = menuBarBottomY - 6.0
        self.pinnedTopY = topY
        let originY = topY - panelHeight
        
        // Center horizontally under the clicked pill or mouse cursor
        let targetX: CGFloat
        if let button = statusItem.button, let buttonWindow = button.window, buttonWindow.frame.origin.x != 0 {
            let buttonScreenRect = buttonWindow.convertToScreen(rect)
            targetX = buttonScreenRect.midX - (panelWidth / 2.0)
        } else {
            targetX = mouseLoc.x - (panelWidth / 2.0)
        }
        
        let minX = screen.visibleFrame.minX + 12.0
        let maxX = screen.visibleFrame.maxX - panelWidth - 12.0
        let originX = max(minX, min(maxX, targetX))
        
        panel.setFrame(NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight), display: true)
        panel.alphaValue = 0.0
        panel.orderFrontRegardless()
        
        // Smooth entrance
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            panel.animator().alphaValue = 1.0
        }
        
        isPanelShown = true
        startEventMonitors()
    }
    
    public func closePanel() {
        guard isPanelShown else { return }
        stopEventMonitors()
        statusView.setActiveTab(nil)
        isPanelShown = false
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                if self?.isPanelShown == false {
                    self?.panel.orderOut(nil)
                }
            }
        })
    }
    
    public func resizePanel(newHeight: CGFloat) {
        let maxH = maxHeightForCurrentScreen()
        let clampedHeight = max(320.0, min(maxH, newHeight))
        let originY = pinnedTopY - clampedHeight
        panel.setFrame(NSRect(x: panel.frame.origin.x, y: originY, width: 375.0, height: clampedHeight), display: true)
        AppSettings.shared.popupHeight = Double(clampedHeight)
    }
    
    private func maxHeightForCurrentScreen() -> CGFloat {
        let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens[0]
        return max(500.0, screen.visibleFrame.height - 40.0)
    }
    
    // MARK: - NSWindowDelegate (Resizing & Top Pinning)
    public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let maxH = maxHeightForCurrentScreen()
        let clampedHeight = max(320.0, min(maxH, frameSize.height))
        return NSSize(width: 375.0, height: clampedHeight)
    }
    
    public func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        let currentHeight = window.frame.height
        let expectedOriginY = pinnedTopY - currentHeight
        if abs(window.frame.origin.y - expectedOriginY) > 0.5 {
            window.setFrameOrigin(NSPoint(x: window.frame.origin.x, y: expectedOriginY))
        }
        AppSettings.shared.popupHeight = Double(currentHeight)
    }
    
    private func startEventMonitors() {
        stopEventMonitors()
        
        // Dismiss when clicking outside (using convertToScreen to avoid status bar click drop)
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isPanelShown else { return }
            
            // Check if click occurred inside the status bar button on screen
            if let button = self.statusItem.button, let window = button.window {
                let mouseScreen = NSEvent.mouseLocation
                let screenRect = window.convertToScreen(button.bounds)
                if screenRect.contains(mouseScreen) {
                    return // Click landed on the status item itself: do not close here, let statusView handle it!
                }
            }
            self.closePanel()
        }
        
        // Dismiss on Escape key
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.closePanel()
                return nil
            }
            return event
        }
    }
    
    private func stopEventMonitors() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
    
    // MARK: - Context Menu (Right-Click)
    public func showContextMenu() {
        MenuBarHoverManager.shared.hide(immediate: true)
        closePanel()
        
        let menu = NSMenu(title: "MonitorApp Menu")
        menu.delegate = self
        self.contextMenu = menu
        
        // 1. Header Item
        let headerItem = NSMenuItem(title: "MonitorApp 1.2.0", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Menu Bar Representation Submenu
        let styleMenuItem = NSMenuItem(title: "Menu Bar Style", action: nil, keyEquivalent: "")
        styleMenuItem.image = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: nil)
        let styleSubmenu = NSMenu(title: "Menu Bar Style")
        
        let currentStyle = AppSettings.shared.menuBarStyle
        for style in MenuBarDisplayStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(didSelectMenuBarStyle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style
            item.image = NSImage(systemSymbolName: style.iconName, accessibilityDescription: nil)
            item.state = (style == currentStyle) ? .on : .off
            styleSubmenu.addItem(item)
        }
        styleMenuItem.submenu = styleSubmenu
        menu.addItem(styleMenuItem)
        
        // 3. Appearance Submenu
        let appearanceMenuItem = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        appearanceMenuItem.image = NSImage(systemSymbolName: "circle.lefthalf.filled", accessibilityDescription: nil)
        let appearanceSubmenu = NSMenu(title: "Appearance")
        
        let currentMode = AppSettings.shared.appearanceMode
        for mode in AppearanceMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(didSelectAppearanceMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            item.state = (mode == currentMode) ? .on : .off
            appearanceSubmenu.addItem(item)
        }
        appearanceMenuItem.submenu = appearanceSubmenu
        menu.addItem(appearanceMenuItem)
        
        // 4. Display Options Submenu
        let displayMenuItem = NSMenuItem(title: "Display Options", action: nil, keyEquivalent: "")
        displayMenuItem.image = NSImage(systemSymbolName: "gauge.with.needle", accessibilityDescription: nil)
        let displaySubmenu = NSMenu(title: "Display Options")
        
        let hoverZoomItem = NSMenuItem(title: "Show Zoomed View on Hover", action: #selector(toggleHoverZoom), keyEquivalent: "")
        hoverZoomItem.target = self
        hoverZoomItem.state = AppSettings.shared.enableHoverZoom ? .on : .off
        displaySubmenu.addItem(hoverZoomItem)
        
        displaySubmenu.addItem(NSMenuItem.separator())
        
        let netPercentItem = NSMenuItem(title: "Show Network as Percentage", action: #selector(toggleNetworkPercentage), keyEquivalent: "")
        netPercentItem.target = self
        netPercentItem.state = AppSettings.shared.showNetworkAsPercentage ? .on : .off
        displaySubmenu.addItem(netPercentItem)
        
        let procListItem = NSMenuItem(title: "Show Top Processes in Views", action: #selector(toggleProcessList), keyEquivalent: "")
        procListItem.target = self
        procListItem.state = AppSettings.shared.showProcessList ? .on : .off
        displaySubmenu.addItem(procListItem)
        
        displayMenuItem.submenu = displaySubmenu
        menu.addItem(displayMenuItem)
        
        // 4. Update Interval Submenu
        let intervalMenuItem = NSMenuItem(title: "Update Frequency", action: nil, keyEquivalent: "")
        intervalMenuItem.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
        let intervalSubmenu = NSMenu(title: "Update Frequency")
        
        let currentInterval = AppSettings.shared.refreshInterval
        let intervals: [(String, Double)] = [
            ("1.0 Second", 1.0),
            ("1.5 Seconds", 1.5),
            ("2.0 Seconds", 2.0),
            ("3.0 Seconds", 3.0),
            ("5.0 Seconds", 5.0)
        ]
        for (title, value) in intervals {
            let item = NSMenuItem(title: title, action: #selector(didSelectInterval(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = (abs(currentInterval - value) < 0.1) ? .on : .off
            intervalSubmenu.addItem(item)
        }
        intervalMenuItem.submenu = intervalSubmenu
        menu.addItem(intervalMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 5. Quick Inspectors
        let cpuItem = NSMenuItem(title: "Open CPU Inspector...", action: #selector(openCPUInspector), keyEquivalent: "1")
        cpuItem.target = self
        cpuItem.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: nil)
        menu.addItem(cpuItem)
        
        let memItem = NSMenuItem(title: "Open Memory Inspector...", action: #selector(openMemoryInspector), keyEquivalent: "2")
        memItem.target = self
        memItem.image = NSImage(systemSymbolName: "memorychip", accessibilityDescription: nil)
        menu.addItem(memItem)
        
        let netItem = NSMenuItem(title: "Open Network Inspector...", action: #selector(openNetworkInspector), keyEquivalent: "3")
        netItem.target = self
        netItem.image = NSImage(systemSymbolName: "arrow.up.arrow.down", accessibilityDescription: nil)
        menu.addItem(netItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 6. Activity Monitor
        let actItem = NSMenuItem(title: "Open Activity Monitor", action: #selector(openActivityMonitor), keyEquivalent: "")
        actItem.target = self
        actItem.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: nil)
        menu.addItem(actItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 7. Quit App
        let quitItem = NSMenuItem(title: "Quit MonitorApp", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quitItem)
        
        // Show menu via status item
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }
    
    // MARK: - Menu Actions
    @objc private func didSelectMenuBarStyle(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? MenuBarDisplayStyle else { return }
        AppSettings.shared.menuBarStyle = style
        statusView.updateLayout()
    }
    
    @objc private func toggleHoverZoom() {
        AppSettings.shared.enableHoverZoom.toggle()
        if !AppSettings.shared.enableHoverZoom {
            MenuBarHoverManager.shared.hide(immediate: true)
        }
    }
    
    @objc private func didSelectAppearanceMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? AppearanceMode else { return }
        AppSettings.shared.appearanceMode = mode
    }
    
    @objc private func toggleNetworkPercentage() {
        AppSettings.shared.showNetworkAsPercentage.toggle()
        statusView.updateLayout()
    }
    
    @objc private func toggleProcessList() {
        AppSettings.shared.showProcessList.toggle()
    }
    
    @objc private func didSelectInterval(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? Double else { return }
        SystemMonitorService.shared.updateInterval(interval)
    }
    
    @objc private func openCPUInspector() {
        handleSectionClicked(tab: .cpu, rect: NSRect(x: 4, y: 0, width: 56, height: 22))
    }
    
    @objc private func openMemoryInspector() {
        handleSectionClicked(tab: .memory, rect: NSRect(x: 64, y: 0, width: 56, height: 22))
    }
    
    @objc private func openNetworkInspector() {
        handleSectionClicked(tab: .network, rect: NSRect(x: 124, y: 0, width: 58, height: 22))
    }
    
    @objc private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - NSMenuDelegate
    public func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
        self.contextMenu = nil
    }
}
