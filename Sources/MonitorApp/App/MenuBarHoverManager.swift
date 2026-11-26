import AppKit
import SwiftUI

@MainActor
public final class MenuBarHoverManager: NSObject {
    public static let shared = MenuBarHoverManager()
    
    private var panel: NSPanel!
    private var hostingView: NSHostingView<MenuBarHoverZoomView>?
    private var currentTab: InspectorTab?
    private var isVisible: Bool = false
    private var dismissTimer: Timer?
    
    public override init() {
        super.init()
        setupPanel()
    }
    
    private func setupPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 310, height: 245),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
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
        panel.ignoresMouseEvents = true // Allows clicks to pass through or be handled smoothly by status bar
    }
    
    public func show(for tab: InspectorTab, screenRect: NSRect) {
        guard AppSettings.shared.enableHoverZoom else {
            hide(immediate: true)
            return
        }
        
        // Don't show hover zoom if the main inspector panel is currently open
        if MenuBarManager.shared.isPanelShown {
            hide(immediate: true)
            return
        }
        
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        
        let menuBarBottomY = screen.visibleFrame.maxY
        let panelW: CGFloat = 310.0
        let panelH: CGFloat = 245.0
        
        let targetX = screenRect.midX - (panelW / 2.0)
        let minX = screen.visibleFrame.minX + 8.0
        let maxX = screen.visibleFrame.maxX - panelW - 8.0
        let originX = max(minX, min(maxX, targetX))
        let originY = menuBarBottomY - panelH - 4.0
        
        let frame = NSRect(x: originX, y: originY, width: panelW, height: panelH)
        
        if isVisible && currentTab == tab {
            // Already showing this tab; ensure frame matches
            panel.setFrame(frame, display: true)
            return
        }
        
        currentTab = tab
        
        let zoomView = MenuBarHoverZoomView(tab: tab)
        if let existingHost = hostingView {
            existingHost.rootView = zoomView
        } else {
            let host = NSHostingView(rootView: zoomView)
            panel.contentView = host
            self.hostingView = host
        }
        
        panel.setFrame(frame, display: true)
        
        if !isVisible {
            panel.alphaValue = 0.0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                panel.animator().alphaValue = 1.0
            }
            isVisible = true
        }
    }
    
    public func scheduleHide(delay: TimeInterval = 0.15) {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.hide(immediate: false)
            }
        }
    }
    
    public func hide(immediate: Bool = false) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        guard isVisible else { return }
        isVisible = false
        currentTab = nil
        
        if immediate {
            panel.alphaValue = 0.0
            panel.orderOut(nil)
        } else {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.10
                panel.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    if self?.isVisible == false {
                        self?.panel.orderOut(nil)
                    }
                }
            })
        }
    }
}
