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
