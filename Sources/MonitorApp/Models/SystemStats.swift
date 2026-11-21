import Foundation
import SwiftUI
import AppKit

// MARK: - Core Classification
public enum CoreType: String, CaseIterable, Sendable {
    case superCore = "Super"
    case performance = "Performance"
    case efficiency = "Efficiency"
    case standard = "Standard"
    
    public var displayName: String {
        switch self {
        case .superCore: return "Super Core"
        case .performance: return "Performance Core"
        case .efficiency: return "Efficiency Core"
        case .standard: return "Standard Core"
        }
    }
    
    public var badgeTitle: String {
        switch self {
        case .superCore: return "SUPER"
        case .performance: return "P-CORE"
        case .efficiency: return "E-CORE"
        case .standard: return "CORE"
        }
    }
    
    public var color: Color {
        switch self {
        case .superCore:
            return Color(red: 0.65, green: 0.35, blue: 0.95) // Vibrant Violet/Purple
        case .performance:
            return Color(red: 1.0, green: 0.55, blue: 0.20) // Vibrant Orange/Amber
        case .efficiency:
            return Color(red: 0.20, green: 0.85, blue: 0.60) // Mint/Green
        case .standard:
            return Color(red: 0.25, green: 0.60, blue: 1.00) // Apple Blue
        }
    }
    
    public var icon: String {
        switch self {
        case .superCore: return "bolt.shield.fill"
        case .performance: return "bolt.fill"
        case .efficiency: return "leaf.fill"
        case .standard: return "cpu"
        }
    }
}

// MARK: - CPU Models
public struct CPUCoreInfo: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let type: CoreType
    public var usage: Double // 0.0 - 100.0
    
    public init(id: Int, name: String, type: CoreType, usage: Double) {
        self.id = id
        self.name = name
        self.type = type
        self.usage = usage
    }
}

public struct CPUStats: Sendable {
    public var overallUsage: Double = 0.0 // 0.0 - 100.0
    public var userUsage: Double = 0.0
    public var systemUsage: Double = 0.0
    public var idleUsage: Double = 100.0
    public var cores: [CPUCoreInfo] = []
    public var chipName: String = "Apple Silicon"
    public var history: [Double] = Array(repeating: 0.0, count: 30)
    
    public var superCount: Int {
        cores.filter { $0.type == .superCore }.count
    }
    public var performanceCount: Int {
        cores.filter { $0.type == .performance }.count
    }
    public var efficiencyCount: Int {
        cores.filter { $0.type == .efficiency }.count
    }
}

// MARK: - Memory Pressure Status
public enum MemoryPressureStatus: String, Sendable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    
    public var color: Color {
        switch self {
        case .normal: return Color(red: 0.22, green: 0.82, blue: 0.45) // Emerald
        case .warning: return Color(red: 1.00, green: 0.70, blue: 0.00) // Gold
        case .critical: return Color(red: 1.00, green: 0.30, blue: 0.30) // Coral Red
        }
    }
    
    public var description: String {
        switch self {
        case .normal: return "Memory pressure is low and normal."
        case .warning: return "Moderate pressure. Compressor active."
        case .critical: return "High memory pressure! System may page to disk."
        }
    }
}

// MARK: - Memory Models
public struct MemoryStats: Sendable {
    public var totalBytes: UInt64 = 0
    public var usedBytes: UInt64 = 0
    public var freeBytes: UInt64 = 0
    
    // Explicit user requirements
    public var wiredBytes: UInt64 = 0
    public var pressureLevel: Int32 = 1 // 1: Normal, 2: Warning, 4: Critical
    public var pressureStatus: MemoryPressureStatus = .normal
    public var pressurePercentage: Double = 0.0
    
    public var swapTotalBytes: UInt64 = 0
    public var swapUsedBytes: UInt64 = 0
    public var swapFreeBytes: UInt64 = 0
    public var swapPercentage: Double = 0.0
    
    // Detailed breakdown
    public var activeBytes: UInt64 = 0
    public var inactiveBytes: UInt64 = 0
    public var compressedBytes: UInt64 = 0
    public var purgeableBytes: UInt64 = 0
    
    public var usedPercentage: Double = 0.0 // (Active + Wired + Compressed) / Total memory
    public var activePercentage: Double { totalBytes > 0 ? (Double(activeBytes) / Double(totalBytes) * 100.0) : 0.0 }
    public var wiredPercentage: Double = 0.0
    public var history: [Double] = Array(repeating: 0.0, count: 30)
}

// MARK: - Network Models
public struct NetworkStats: Sendable {
    public var downloadBytesPerSecond: Double = 0.0
    public var uploadBytesPerSecond: Double = 0.0
    public var totalBytesDownloaded: UInt64 = 0
    public var totalBytesUploaded: UInt64 = 0
    public var linkBaudRate: UInt64 = 1_000_000_000 // 1 Gbps default fallback
    public var bandwidthUsagePercentage: Double = 0.0 // 0.0 - 100.0%
    public var interfaceName: String = "en0"
    public var ipAddress: String = "127.0.0.1"
    public var macAddress: String = ""
    public var isWifi: Bool = true
    
    public var downloadHistory: [Double] = Array(repeating: 0.0, count: 30)
    public var uploadHistory: [Double] = Array(repeating: 0.0, count: 30)
}

// MARK: - Process Item
public struct ProcessItem: Identifiable, Sendable {
    public let id: pid_t
    public let name: String
    public let cpuPercentage: Double
    public let memoryBytes: UInt64
    public let icon: NSImage?
    public var isNotResponding: Bool
    
    public init(id: pid_t, name: String, cpuPercentage: Double, memoryBytes: UInt64, icon: NSImage? = nil, isNotResponding: Bool = false) {
        self.id = id
        self.name = name
        self.cpuPercentage = cpuPercentage
        self.memoryBytes = memoryBytes
        self.icon = icon
        self.isNotResponding = isNotResponding
    }
}

// MARK: - Inspector Navigation Tab
public enum InspectorTab: String, CaseIterable, Identifiable, Sendable {
    case cpu = "CPU"
    case memory = "Memory"
    case network = "Network"
    case processes = "Processes"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .network: return "arrow.up.arrow.down"
        case .processes: return "list.bullet.rectangle"
        case .settings: return "gearshape.fill"
        }
    }
}
