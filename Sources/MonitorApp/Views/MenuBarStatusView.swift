import AppKit
import Combine

public final class MenuBarStatusView: NSView {
    public var onSectionClicked: ((InspectorTab, NSRect) -> Void)?
    public var onRightClicked: (() -> Void)?
    
    // Crucial for NSStatusBarButton coordinate matching
    public override var isFlipped: Bool { true }
    
    private var hoveredSection: InspectorTab? = nil
    private var activeSection: InspectorTab? = nil
    
    private var cpuRect: NSRect = .zero
    private var memoryRect: NSRect = .zero
    private var networkRect: NSRect = .zero
    
    private var cancellables = Set<AnyCancellable>()
    private var trackingArea: NSTrackingArea?
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        
        // Subscribe to system monitor updates
        SystemMonitorService.shared.$cpuStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)
        
        SystemMonitorService.shared.$memoryStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)
        
        SystemMonitorService.shared.$networkStats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)
        
        AppSettings.shared.$showNetworkAsPercentage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLayout()
            }
            .store(in: &cancellables)
        
        updateLayout()
    }
    
    public func setActiveTab(_ tab: InspectorTab?) {
        self.activeSection = tab
        needsDisplay = true
    }
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.trackingArea = area
    }
    
    public func updateLayout() {
        let cpuText = SystemMonitorService.shared.cpuPercentString
        let memText = SystemMonitorService.shared.memoryPercentString
        let netText = AppSettings.shared.showNetworkAsPercentage
            ? SystemMonitorService.shared.networkPercentString
            : SystemMonitorService.shared.networkRateString
        
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        
        let cpuTextWidth = (cpuText as NSString).size(withAttributes: attrs).width
        let memTextWidth = (memText as NSString).size(withAttributes: attrs).width
        let netTextWidth = (netText as NSString).size(withAttributes: attrs).width
        
        let cpuW = max(56.0, ceil(cpuTextWidth + 26.0))
        let memW = max(56.0, ceil(memTextWidth + 26.0))
        let netW = max(58.0, ceil(netTextWidth + 26.0))
        
        let pillH: CGFloat = 19.0
        let h = bounds.height > 0 ? bounds.height : 22.0
        let pillY: CGFloat = max(1.0, (h - pillH) / 2.0)
        let spacing: CGFloat = 3.0
        let leftMargin: CGFloat = 4.0
        
        cpuRect = NSRect(x: leftMargin, y: pillY, width: cpuW, height: pillH)
        memoryRect = NSRect(x: cpuRect.maxX + spacing, y: pillY, width: memW, height: pillH)
        networkRect = NSRect(x: memoryRect.maxX + spacing, y: pillY, width: netW, height: pillH)
        
        let totalW = networkRect.maxX + leftMargin
        if frame.width != totalW {
            frame = NSRect(x: frame.origin.x, y: frame.origin.y, width: totalW, height: h)
        }
        needsDisplay = true
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let monitor = SystemMonitorService.shared
        let cpuText = monitor.cpuPercentString
        let memText = monitor.memoryPercentString
        let netText = AppSettings.shared.showNetworkAsPercentage
            ? monitor.networkPercentString
            : monitor.networkRateString
        
        // Draw CPU Pill
        drawPill(
            rect: cpuRect,
            iconName: "cpu",
            text: cpuText,
            tab: .cpu,
            tintColor: NSColor.systemBlue
        )
        
        // Memory Pressure Color: green, yellow or red
        let memPressureColor: NSColor
        switch monitor.memoryStats.pressureStatus {
        case .normal:
            memPressureColor = NSColor(red: 0.22, green: 0.82, blue: 0.45, alpha: 1.0)
        case .warning:
            memPressureColor = NSColor(red: 1.00, green: 0.70, blue: 0.00, alpha: 1.0)
        case .critical:
            memPressureColor = NSColor(red: 1.00, green: 0.30, blue: 0.30, alpha: 1.0)
        }
        
        // Draw Memory Pill
        drawPill(
            rect: memoryRect,
            iconName: "memorychip",
            text: memText,
            tab: .memory,
            tintColor: memPressureColor,
            customTextColor: memPressureColor
        )
        
        // Draw Network Pill
        drawPill(
            rect: networkRect,
            iconName: "arrow.up.arrow.down",
            text: netText,
            tab: .network,
            tintColor: NSColor.systemCyan
        )
    }
    
    private func drawPill(
        rect: NSRect,
        iconName: String,
        text: String,
        tab: InspectorTab,
        tintColor: NSColor,
        customTextColor: NSColor? = nil
    ) {
        let isHovered = (hoveredSection == tab)
        let isActive = (activeSection == tab)
        
        // Pill background
        let path = NSBezierPath(roundedRect: rect, xRadius: 4.5, yRadius: 4.5)
        if isActive {
            NSColor.controlAccentColor.withAlphaComponent(0.28).setFill()
            path.fill()
        } else if isHovered {
            NSColor.textColor.withAlphaComponent(0.12).setFill()
            path.fill()
        }
        
        // Draw icon
        let iconSize: CGFloat = 11.0
        let iconColor = isActive ? NSColor.controlAccentColor : tintColor
        let baseConfig = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
        let colorConfig = NSImage.SymbolConfiguration(paletteColors: [iconColor])
        let finalConfig = baseConfig.applying(colorConfig)
        
        if let icon = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?.withSymbolConfiguration(finalConfig) {
            let iconY = rect.origin.y + (rect.height - iconSize) / 2.0
            let iconRect = NSRect(x: rect.origin.x + 5.0, y: iconY, width: iconSize, height: iconSize)
            icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        // Draw text
        let font = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .semibold)
        let textColor: NSColor = customTextColor ?? (isActive ? NSColor.labelColor : NSColor.labelColor.withAlphaComponent(0.9))
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let textX = rect.origin.x + 5.0 + iconSize + 3.0
        let textSize = (text as NSString).size(withAttributes: attrs)
        let textY = rect.origin.y + (rect.height - textSize.height) / 2.0
        let textRect = NSRect(x: textX, y: textY, width: textSize.width, height: textSize.height)
        
        (text as NSString).draw(in: textRect, withAttributes: attrs)
    }
    
    // MARK: - Coordinate Helper
    // NSStatusBarWindow has an unusual coordinate space; using screen-space mouse location
    // relative to our own screen rect is more reliable than event.locationInWindow conversion.
    private func localX(from event: NSEvent) -> CGFloat {
        // Convert the view's own frame to screen coordinates
        guard let window = self.window else {
            // Fallback: use event location converted through view hierarchy
            return convert(event.locationInWindow, from: nil).x
        }
        let viewScreenRect = window.convertToScreen(convert(bounds, to: nil))
        let mouseScreenX = NSEvent.mouseLocation.x
        // Clamp to [0, width] so edge clicks still register
        return max(0, min(bounds.width, mouseScreenX - viewScreenRect.origin.x))
    }

    // MARK: - Mouse Events (Full-Column Responsive Hit-Testing)
    public override func mouseMoved(with event: NSEvent) {
        let x = localX(from: event)
        let previous = hoveredSection
        
        if x < memoryRect.minX {
            hoveredSection = .cpu
        } else if x < networkRect.minX {
            hoveredSection = .memory
        } else {
            hoveredSection = .network
        }
        
        if hoveredSection != previous {
            needsDisplay = true
        }
    }
    
    public override func mouseExited(with event: NSEvent) {
        if hoveredSection != nil {
            hoveredSection = nil
            needsDisplay = true
        }
    }
    
    public override func mouseDown(with event: NSEvent) {
        // Control + Left Click behaves as Right Click on macOS
        if event.modifierFlags.contains(.control) {
            onRightClicked?()
            return
        }
        
        let x = localX(from: event)
        
        // Full column hit testing (zero dead zones or gaps)
        if x < memoryRect.minX {
            onSectionClicked?(.cpu, cpuRect)
        } else if x < networkRect.minX {
            onSectionClicked?(.memory, memoryRect)
        } else {
            onSectionClicked?(.network, networkRect)
        }
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        onRightClicked?()
    }
}
