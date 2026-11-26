import AppKit
import Combine

public final class MenuBarStatusView: NSView {
    public var onSectionClicked: ((InspectorTab, NSRect) -> Void)?
    public var onRightClicked: (() -> Void)?
    public var onSizeChanged: ((CGFloat) -> Void)?
    
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
        
        // Subscribe to display style and setting changes
        AppSettings.shared.$showNetworkAsPercentage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLayout()
            }
            .store(in: &cancellables)
        
        AppSettings.shared.$menuBarStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLayout()
            }
            .store(in: &cancellables)
        
        AppSettings.shared.$cpuDisplayStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLayout()
            }
            .store(in: &cancellables)
        
        AppSettings.shared.$memoryDisplayStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLayout()
            }
            .store(in: &cancellables)
        
        AppSettings.shared.$networkDisplayStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLayout()
            }
            .store(in: &cancellables)
        
        AppSettings.shared.$cpuColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)
        
        AppSettings.shared.$highContrastGraph
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
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
    
    public override func layout() {
        super.layout()
        updateLayout()
    }
    
    public func updateLayout() {
        let monitor = SystemMonitorService.shared
        let font = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        
        let cpuText = monitor.cpuPercentString
        let memText = monitor.memoryPercentString
        let netText = AppSettings.shared.showNetworkAsPercentage
            ? monitor.networkPercentString
            : monitor.networkRateString
        
        let cpuTextWidth = (cpuText as NSString).size(withAttributes: attrs).width
        let memTextWidth = (memText as NSString).size(withAttributes: attrs).width
        let netTextWidth = (netText as NSString).size(withAttributes: attrs).width
        
        let cpuStyle = AppSettings.shared.cpuDisplayStyle
        let memStyle = AppSettings.shared.memoryDisplayStyle
        let netStyle = AppSettings.shared.networkDisplayStyle
        
        let cpuW = calculatePillWidth(for: cpuStyle, textWidth: cpuTextWidth)
        let memW = calculatePillWidth(for: memStyle, textWidth: memTextWidth)
        let netW = calculatePillWidth(for: netStyle, textWidth: netTextWidth)
        
        let h = bounds.height > 0 ? bounds.height : NSStatusBar.system.thickness
        let pillH: CGFloat = h
        let pillY: CGFloat = 0.0
        let spacing: CGFloat = 3.0
        let leftMargin: CGFloat = 4.0
        
        cpuRect = NSRect(x: leftMargin, y: pillY, width: cpuW, height: pillH)
        memoryRect = NSRect(x: cpuRect.maxX + spacing, y: pillY, width: memW, height: pillH)
        networkRect = NSRect(x: memoryRect.maxX + spacing, y: pillY, width: netW, height: pillH)
        
        let totalW = networkRect.maxX + leftMargin
        if frame.width != totalW {
            frame = NSRect(x: frame.origin.x, y: frame.origin.y, width: totalW, height: h)
            onSizeChanged?(totalW)
        }
        needsDisplay = true
    }
    
    private func calculatePillWidth(for style: MenuBarDisplayStyle, textWidth: CGFloat) -> CGFloat {
        switch style {
        case .text:
            return max(54.0, ceil(textWidth + 24.0))
        case .bar:
            // Icon (11) + margin (5) + bar (30) + padding (8) = 54
            return 54.0
        case .barAndText:
            // Icon (11) + bar (24) + spacing (4) + text + padding = ~78+
            return ceil(textWidth + 48.0)
        case .history:
            // Icon (11) + margin (5) + mini sparkline (38) + padding (6) = 60
            return 60.0
        }
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let monitor = SystemMonitorService.shared
        let cpuText = monitor.cpuPercentString
        let memText = monitor.memoryPercentString
        let netText = AppSettings.shared.showNetworkAsPercentage
            ? monitor.networkPercentString
            : monitor.networkRateString
        
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
        
        // Draw CPU Pill
        drawPill(
            rect: cpuRect,
            iconName: "cpu",
            text: cpuText,
            tab: .cpu,
            tintColor: AppSettings.shared.cpuColor.nsColor,
            style: AppSettings.shared.cpuDisplayStyle,
            value: monitor.cpuStats.overallUsage,
            history: monitor.cpuStats.history
        )
        
        // Draw Memory Pill
        drawPill(
            rect: memoryRect,
            iconName: "memorychip",
            text: memText,
            tab: .memory,
            tintColor: memPressureColor,
            customTextColor: memPressureColor,
            style: AppSettings.shared.memoryDisplayStyle,
            value: monitor.memoryStats.usedPercentage,
            history: monitor.memoryStats.history
        )
        
        // Draw Network Pill
        let netHistory = AppSettings.shared.showNetworkAsPercentage
            ? monitor.networkStats.bandwidthHistory
            : monitor.networkStats.throughputHistory
        drawPill(
            rect: networkRect,
            iconName: "arrow.up.arrow.down",
            text: netText,
            tab: .network,
            tintColor: NSColor.systemCyan,
            style: AppSettings.shared.networkDisplayStyle,
            value: monitor.networkStats.bandwidthUsagePercentage,
            history: netHistory
        )
    }
    
    private func drawPill(
        rect: NSRect,
        iconName: String,
        text: String,
        tab: InspectorTab,
        tintColor: NSColor,
        customTextColor: NSColor? = nil,
        style: MenuBarDisplayStyle,
        value: Double,
        history: [Double]
    ) {
        let isHovered = (hoveredSection == tab)
        let isActive = (activeSection == tab)
        
        // Pill background
        let path = NSBezierPath(roundedRect: rect, xRadius: 4.5, yRadius: 4.5)
        if isActive {
            NSColor.controlAccentColor.withAlphaComponent(0.30).setFill()
            path.fill()
        } else if isHovered {
            NSColor.textColor.withAlphaComponent(0.18).setFill()
            path.fill()
            
            // Faint subtle outline to enhance hover responsiveness
            NSColor.textColor.withAlphaComponent(0.28).setStroke()
            path.lineWidth = 1.0
            path.stroke()
        }
        
        // Draw icon
        let iconSize: CGFloat = isHovered ? 11.5 : 11.0
        let iconColor = isActive ? NSColor.controlAccentColor : tintColor
        let baseConfig = NSImage.SymbolConfiguration(pointSize: iconSize, weight: isHovered ? .bold : .semibold)
        let colorConfig = NSImage.SymbolConfiguration(paletteColors: [iconColor])
        let finalConfig = baseConfig.applying(colorConfig)
        
        if let icon = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?.withSymbolConfiguration(finalConfig) {
            let iconY = rect.origin.y + (rect.height - iconSize) / 2.0
            let iconRect = NSRect(x: rect.origin.x + 5.0, y: iconY, width: iconSize, height: iconSize)
            icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        let contentX = rect.origin.x + 5.0 + iconSize + 3.5
        let availableWidth = rect.maxX - contentX - 5.0
        
        switch style {
        case .text:
            drawTextOnly(text: text, rect: rect, startX: contentX, isActive: isActive, customTextColor: customTextColor)
            
        case .bar:
            let barRect = NSRect(x: contentX, y: rect.origin.y + (rect.height - (isHovered ? 7.5 : 6.5)) / 2.0, width: availableWidth, height: isHovered ? 7.5 : 6.5)
            drawProgressBar(rect: barRect, value: value, tintColor: tintColor, isHovered: isHovered)
            
        case .barAndText:
            let barW: CGFloat = 20.0
            let barRect = NSRect(x: contentX, y: rect.origin.y + (rect.height - 6.0) / 2.0, width: barW, height: 6.0)
            drawProgressBar(rect: barRect, value: value, tintColor: tintColor, isHovered: isHovered)
            
            let textStartX = barRect.maxX + 4.0
            drawTextOnly(text: text, rect: rect, startX: textStartX, isActive: isActive, customTextColor: customTextColor)
            
        case .history:
            let graphH: CGFloat = max(14.0, rect.height - 1.0)
            let graphRect = NSRect(x: contentX, y: rect.origin.y + (rect.height - graphH) / 2.0, width: availableWidth, height: graphH)
            drawHistorySparkline(rect: graphRect, history: history, tintColor: tintColor, isHovered: isHovered, tab: tab)
        }
    }
    
    // MARK: - Mini Visual Elements
    private func drawTextOnly(text: String, rect: NSRect, startX: CGFloat, isActive: Bool, customTextColor: NSColor?) {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .bold)
        let textColor: NSColor = customTextColor ?? (isActive ? NSColor.labelColor : NSColor.labelColor.withAlphaComponent(0.95))
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let textSize = (text as NSString).size(withAttributes: attrs)
        let textY = rect.origin.y + (rect.height - textSize.height) / 2.0
        let textRect = NSRect(x: startX, y: textY, width: textSize.width, height: textSize.height)
        
        (text as NSString).draw(in: textRect, withAttributes: attrs)
    }
    
    private func drawProgressBar(rect: NSRect, value: Double, tintColor: NSColor, isHovered: Bool) {
        let isHighContrast = AppSettings.shared.highContrastGraph
        
        // Dark contrast backing track so it never blends into transparent / sky backgrounds
        let trackPath = NSBezierPath(roundedRect: rect, xRadius: 3.0, yRadius: 3.0)
        NSColor(white: 0.06, alpha: isHighContrast ? 0.72 : 0.40).setFill()
        trackPath.fill()
        
        if isHighContrast {
            NSColor.white.withAlphaComponent(0.22).setStroke()
            trackPath.lineWidth = 0.5
            trackPath.stroke()
        }
        
        // Fill
        let clamped = max(0.0, min(100.0, value))
        let fillFraction = CGFloat(clamped / 100.0)
        let fillW = max(3.0, rect.width * fillFraction)
        let fillRect = NSRect(x: rect.origin.x, y: rect.origin.y, width: fillW, height: rect.height)
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 3.0, yRadius: 3.0)
        
        let color = isHovered ? tintColor : tintColor.withAlphaComponent(0.95)
        color.setFill()
        fillPath.fill()
    }
    
    private func drawHistorySparkline(rect: NSRect, history: [Double], tintColor: NSColor, isHovered: Bool, tab: InspectorTab) {
        let isHighContrast = AppSettings.shared.highContrastGraph
        
        // Background container box: deep dark backdrop to eliminate wallpaper bleed-through (e.g. blue sky)
        let boxPath = NSBezierPath(roundedRect: rect, xRadius: 3.0, yRadius: 3.0)
        let bgAlpha: CGFloat = isHighContrast ? (isHovered ? 0.85 : 0.76) : (isHovered ? 0.60 : 0.45)
        NSColor(white: 0.06, alpha: bgAlpha).setFill()
        boxPath.fill()
        
        let strokeAlpha: CGFloat = isHighContrast ? 0.28 : 0.16
        NSColor.white.withAlphaComponent(strokeAlpha).setStroke()
        boxPath.lineWidth = 0.6
        boxPath.stroke()
        
        guard history.count >= 2 else { return }
        
        let count = history.count
        let stepX = rect.width / CGFloat(max(count - 1, 1))
        
        let maxVal: Double = (tab == .network && !AppSettings.shared.showNetworkAsPercentage)
            ? max(history.max() ?? 1024.0, 1024.0)
            : 100.0
        
        let topY = rect.minY + 1.5
        let bottomY = rect.maxY - 1.5
        let h = max(1.0, bottomY - topY)
        
        var points: [NSPoint] = []
        for (i, val) in history.enumerated() {
            let px = rect.minX + CGFloat(i) * stepX
            let clamped = max(0.0, min(val, maxVal))
            let py = bottomY - (CGFloat(clamped / maxVal) * h)
            points.append(NSPoint(x: px, y: py))
        }
        
        NSGraphicsContext.saveGraphicsState()
        boxPath.addClip()
        
        // Area Gradient Fill under curve
        let fillPath = NSBezierPath()
        fillPath.move(to: NSPoint(x: points[0].x, y: bottomY))
        for pt in points {
            fillPath.line(to: pt)
        }
        fillPath.line(to: NSPoint(x: points.last!.x, y: bottomY))
        fillPath.close()
        
        NSGraphicsContext.saveGraphicsState()
        fillPath.addClip()
        let gradient = NSGradient(
            starting: tintColor.withAlphaComponent(isHovered ? 0.68 : 0.52),
            ending: tintColor.withAlphaComponent(0.10)
        )
        gradient?.draw(in: rect, angle: 90.0) // 90 degrees in flipped coordinates is top to bottom
        NSGraphicsContext.restoreGraphicsState()
        
        // Dark contrast halo / shadow underlay behind the stroke line
        let haloPath = NSBezierPath()
        haloPath.move(to: points[0])
        for i in 1..<points.count {
            haloPath.line(to: points[i])
        }
        haloPath.lineWidth = (isHovered ? 1.9 : 1.6) + 1.2
        haloPath.lineCapStyle = .round
        haloPath.lineJoinStyle = .round
        NSColor.black.withAlphaComponent(isHighContrast ? 0.75 : 0.45).setStroke()
        haloPath.stroke()
        
        // Crisp stroked line along top
        let linePath = NSBezierPath()
        linePath.move(to: points[0])
        for i in 1..<points.count {
            linePath.line(to: points[i])
        }
        linePath.lineWidth = isHovered ? 1.9 : 1.6
        linePath.lineCapStyle = .round
        linePath.lineJoinStyle = .round
        tintColor.setStroke()
        linePath.stroke()
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    // MARK: - Coordinate Helper
    private func localX(from event: NSEvent) -> CGFloat {
        guard let window = self.window else {
            return convert(event.locationInWindow, from: nil).x
        }
        let viewScreenRect = window.convertToScreen(convert(bounds, to: nil))
        let mouseScreenX = NSEvent.mouseLocation.x
        return max(0, min(bounds.width, mouseScreenX - viewScreenRect.origin.x))
    }

    // MARK: - Mouse Events & Hover Zoom
    public override func mouseMoved(with event: NSEvent) {
        let x = localX(from: event)
        let previous = hoveredSection
        let newSection: InspectorTab
        let targetRect: NSRect
        
        if x < memoryRect.minX {
            newSection = .cpu
            targetRect = cpuRect
        } else if x < networkRect.minX {
            newSection = .memory
            targetRect = memoryRect
        } else {
            newSection = .network
            targetRect = networkRect
        }
        
        hoveredSection = newSection
        if hoveredSection != previous {
            needsDisplay = true
        }
        
        if let window = self.window {
            let screenRect = window.convertToScreen(convert(targetRect, to: nil))
            MenuBarHoverManager.shared.show(for: newSection, screenRect: screenRect)
        }
    }
    
    public override func mouseExited(with event: NSEvent) {
        if hoveredSection != nil {
            hoveredSection = nil
            needsDisplay = true
        }
        MenuBarHoverManager.shared.scheduleHide(delay: 0.15)
    }
    
    public override func mouseDown(with event: NSEvent) {
        MenuBarHoverManager.shared.hide(immediate: true)
        
        if event.modifierFlags.contains(.control) {
            onRightClicked?()
            return
        }
        
        let x = localX(from: event)
        if x < memoryRect.minX {
            onSectionClicked?(.cpu, cpuRect)
        } else if x < networkRect.minX {
            onSectionClicked?(.memory, memoryRect)
        } else {
            onSectionClicked?(.network, networkRect)
        }
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        MenuBarHoverManager.shared.hide(immediate: true)
        onRightClicked?()
    }
}
