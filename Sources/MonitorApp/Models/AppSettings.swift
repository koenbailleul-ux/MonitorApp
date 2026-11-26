import Foundation
import SwiftUI
import AppKit

public enum AppearanceMode: String, CaseIterable, Sendable {
    case system = "system"
    case dark = "dark"
    case light = "light"
    
    public var displayName: String {
        switch self {
        case .system: return "Match System (Auto)"
        case .dark: return "Dark Mode"
        case .light: return "Light Mode"
        }
    }
    
    public var shortName: String {
        switch self {
        case .system: return "System"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
}

public enum MenuBarColor: String, CaseIterable, Sendable {
    case orange = "orange"
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case cyan = "cyan"
    case red = "red"
    case yellow = "yellow"
    case monochrome = "monochrome"
    
    public var displayName: String {
        switch self {
        case .orange: return "Vibrant Orange (High Contrast)"
        case .blue: return "Electric Blue"
        case .green: return "Emerald Green"
        case .purple: return "Purple"
        case .cyan: return "Cyan"
        case .red: return "Coral Red"
        case .yellow: return "Amber Yellow"
        case .monochrome: return "Monochrome (White)"
        }
    }
    
    public var shortName: String {
        switch self {
        case .orange: return "Orange"
        case .blue: return "Blue"
        case .green: return "Green"
        case .purple: return "Purple"
        case .cyan: return "Cyan"
        case .red: return "Red"
        case .yellow: return "Yellow"
        case .monochrome: return "White"
        }
    }
    
    public var nsColor: NSColor {
        switch self {
        case .orange: return NSColor(red: 1.00, green: 0.55, blue: 0.05, alpha: 1.0)
        case .blue: return NSColor(red: 0.30, green: 0.72, blue: 1.00, alpha: 1.0)
        case .green: return NSColor(red: 0.20, green: 0.84, blue: 0.45, alpha: 1.0)
        case .purple: return NSColor(red: 0.72, green: 0.45, blue: 1.00, alpha: 1.0)
        case .cyan: return NSColor(red: 0.15, green: 0.85, blue: 0.95, alpha: 1.0)
        case .red: return NSColor(red: 1.00, green: 0.33, blue: 0.33, alpha: 1.0)
        case .yellow: return NSColor(red: 1.00, green: 0.82, blue: 0.10, alpha: 1.0)
        case .monochrome: return NSColor(white: 0.96, alpha: 1.0)
        }
    }
    
    public var swiftUIColor: Color {
        Color(nsColor: nsColor)
    }
}

public enum MenuBarDisplayStyle: String, CaseIterable, Sendable {
    case text = "text"
    case bar = "bar"
    case history = "history"
    case barAndText = "barAndText"
    
    public var displayName: String {
        switch self {
        case .text: return "Text (Percentage / Rate)"
        case .bar: return "Progress Bar"
        case .history: return "History Graph"
        case .barAndText: return "Bar & Text"
        }
    }
    
    public var shortName: String {
        switch self {
        case .text: return "Text"
        case .bar: return "Bar"
        case .history: return "Graph"
        case .barAndText: return "Bar+Text"
        }
    }
    
    public var iconName: String {
        switch self {
        case .text: return "textformat.123"
        case .bar: return "chart.bar.fill"
        case .history: return "waveform.path.ecg"
        case .barAndText: return "chart.bar.xaxis"
        }
    }
}

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private enum Keys {
        static let refreshInterval = "refreshInterval"
        static let showNetworkAsPercentage = "showNetworkAsPercentage"
        static let showProcessList = "showProcessList"
        static let launchAtLogin = "launchAtLogin"
        static let appearanceMode = "appearanceMode"
        static let popupHeight = "popupHeight"
        static let menuBarStyle = "menuBarStyle"
        static let cpuDisplayStyle = "cpuDisplayStyle"
        static let memoryDisplayStyle = "memoryDisplayStyle"
        static let networkDisplayStyle = "networkDisplayStyle"
        static let enableHoverZoom = "enableHoverZoom"
        static let cpuColor = "cpuColor"
        static let highContrastGraph = "highContrastGraph"
    }
    
    @Published public var refreshInterval: Double {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: Keys.refreshInterval)
        }
    }
    
    @Published public var showNetworkAsPercentage: Bool {
        didSet {
            UserDefaults.standard.set(showNetworkAsPercentage, forKey: Keys.showNetworkAsPercentage)
        }
    }
    
    @Published public var showProcessList: Bool {
        didSet {
            UserDefaults.standard.set(showProcessList, forKey: Keys.showProcessList)
        }
    }
    
    @Published public var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
        }
    }
    
    @Published public var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
            applyAppearance()
        }
    }
    
    @Published public var popupHeight: Double {
        didSet {
            UserDefaults.standard.set(popupHeight, forKey: Keys.popupHeight)
        }
    }
    
    @Published public var menuBarStyle: MenuBarDisplayStyle {
        didSet {
            UserDefaults.standard.set(menuBarStyle.rawValue, forKey: Keys.menuBarStyle)
            cpuDisplayStyle = menuBarStyle
            memoryDisplayStyle = menuBarStyle
            networkDisplayStyle = menuBarStyle
        }
    }
    
    @Published public var cpuDisplayStyle: MenuBarDisplayStyle {
        didSet {
            UserDefaults.standard.set(cpuDisplayStyle.rawValue, forKey: Keys.cpuDisplayStyle)
        }
    }
    
    @Published public var memoryDisplayStyle: MenuBarDisplayStyle {
        didSet {
            UserDefaults.standard.set(memoryDisplayStyle.rawValue, forKey: Keys.memoryDisplayStyle)
        }
    }
    
    @Published public var networkDisplayStyle: MenuBarDisplayStyle {
        didSet {
            UserDefaults.standard.set(networkDisplayStyle.rawValue, forKey: Keys.networkDisplayStyle)
        }
    }
    
    @Published public var enableHoverZoom: Bool {
        didSet {
            UserDefaults.standard.set(enableHoverZoom, forKey: Keys.enableHoverZoom)
        }
    }
    
    @Published public var cpuColor: MenuBarColor {
        didSet {
            UserDefaults.standard.set(cpuColor.rawValue, forKey: Keys.cpuColor)
        }
    }
    
    @Published public var highContrastGraph: Bool {
        didSet {
            UserDefaults.standard.set(highContrastGraph, forKey: Keys.highContrastGraph)
        }
    }
    
    private init() {
        let defaults = UserDefaults.standard
        let interval = defaults.double(forKey: Keys.refreshInterval)
        self.refreshInterval = interval > 0.2 ? interval : 1.5
        
        if defaults.object(forKey: Keys.showNetworkAsPercentage) != nil {
            self.showNetworkAsPercentage = defaults.bool(forKey: Keys.showNetworkAsPercentage)
        } else {
            self.showNetworkAsPercentage = true
        }
        
        if defaults.object(forKey: Keys.showProcessList) != nil {
            self.showProcessList = defaults.bool(forKey: Keys.showProcessList)
        } else {
            self.showProcessList = true
        }
        
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        
        if let rawMode = defaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: rawMode) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .system
        }
        
        let savedHeight = defaults.double(forKey: Keys.popupHeight)
        self.popupHeight = (savedHeight >= 300.0 && savedHeight <= 1200.0) ? savedHeight : 460.0
        
        let initialStyle: MenuBarDisplayStyle
        if let rawStyle = defaults.string(forKey: Keys.menuBarStyle),
           let style = MenuBarDisplayStyle(rawValue: rawStyle) {
            initialStyle = style
        } else {
            initialStyle = .text
        }
        self.menuBarStyle = initialStyle
        
        if let rawCPU = defaults.string(forKey: Keys.cpuDisplayStyle),
           let style = MenuBarDisplayStyle(rawValue: rawCPU) {
            self.cpuDisplayStyle = style
        } else {
            self.cpuDisplayStyle = initialStyle
        }
        
        if let rawMem = defaults.string(forKey: Keys.memoryDisplayStyle),
           let style = MenuBarDisplayStyle(rawValue: rawMem) {
            self.memoryDisplayStyle = style
        } else {
            self.memoryDisplayStyle = initialStyle
        }
        
        if let rawNet = defaults.string(forKey: Keys.networkDisplayStyle),
           let style = MenuBarDisplayStyle(rawValue: rawNet) {
            self.networkDisplayStyle = style
        } else {
            self.networkDisplayStyle = initialStyle
        }
        
        if defaults.object(forKey: Keys.enableHoverZoom) != nil {
            self.enableHoverZoom = defaults.bool(forKey: Keys.enableHoverZoom)
        } else {
            self.enableHoverZoom = true
        }
        
        if let rawColor = defaults.string(forKey: Keys.cpuColor),
           let color = MenuBarColor(rawValue: rawColor) {
            self.cpuColor = color
        } else {
            self.cpuColor = .orange
        }
        
        if defaults.object(forKey: Keys.highContrastGraph) != nil {
            self.highContrastGraph = defaults.bool(forKey: Keys.highContrastGraph)
        } else {
            self.highContrastGraph = true
        }
    }
    
    public func applyAppearance() {
        DispatchQueue.main.async {
            switch self.appearanceMode {
            case .system:
                NSApp.appearance = nil
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            }
        }
    }
}
