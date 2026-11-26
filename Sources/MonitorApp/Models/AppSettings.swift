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
