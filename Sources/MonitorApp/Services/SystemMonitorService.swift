import Foundation
import SwiftUI
import Combine

@MainActor
public final class SystemMonitorService: ObservableObject {
    public static let shared = SystemMonitorService()
    
    @Published public private(set) var cpuStats: CPUStats = CPUStats()
    @Published public private(set) var memoryStats: MemoryStats = MemoryStats()
    @Published public private(set) var networkStats: NetworkStats = NetworkStats()
    @Published public private(set) var topCPUProcesses: [ProcessItem] = []
    @Published public private(set) var topMemoryProcesses: [ProcessItem] = []
    
    // Status item string getters
    public var cpuPercentString: String {
        String(format: "%.0f%%", cpuStats.overallUsage)
    }
    
    public var memoryPercentString: String {
        String(format: "%.0f%%", memoryStats.usedPercentage)
    }
    
    public var networkPercentString: String {
        String(format: "%.0f%%", networkStats.bandwidthUsagePercentage)
    }
    
    public var networkRateString: String {
        Self.formatThroughput(networkStats.downloadBytesPerSecond + networkStats.uploadBytesPerSecond)
    }
    
    nonisolated private let cpuMonitor = CPUMonitor()
    nonisolated private let memoryMonitor = MemoryMonitor()
    nonisolated private let networkMonitor = NetworkMonitor()
    nonisolated private let processMonitor = ProcessMonitor()
    
    private var timer: Timer?
    private var processCounter: Int = 0
    private var isSampling: Bool = false
    private let samplingQueue = DispatchQueue(label: "com.monitorapp.sampling", qos: .utility)
    
    private init() {
        start()
    }
    
    public func start() {
        stop()
        let interval = AppSettings.shared.refreshInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        tick()
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    public func updateInterval(_ newInterval: Double) {
        AppSettings.shared.refreshInterval = newInterval
        start()
    }
    
    public func tick() {
        guard !isSampling else { return }
        isSampling = true
        
        let shouldSampleProcesses = (processCounter % 2 == 0)
        processCounter += 1
        
        samplingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let cpu = self.cpuMonitor.sample()
            let mem = self.memoryMonitor.sample()
            let net = self.networkMonitor.sample()
            
            var procs: (topCPU: [ProcessItem], topMemory: [ProcessItem])? = nil
            if shouldSampleProcesses {
                procs = self.processMonitor.sample()
            }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Update CPU & history
                var newCpu = cpu
                var cpuHist = self.cpuStats.history
                cpuHist.append(cpu.overallUsage)
                if cpuHist.count > 30 { cpuHist.removeFirst() }
                newCpu.history = cpuHist
                self.cpuStats = newCpu
                
                // Update Memory & history
                var newMem = mem
                var memHist = self.memoryStats.history
                memHist.append(mem.usedPercentage)
                if memHist.count > 30 { memHist.removeFirst() }
                newMem.history = memHist
                self.memoryStats = newMem
                
                // Update Network & history
                var newNet = net
                var downHist = self.networkStats.downloadHistory
                downHist.append(net.downloadBytesPerSecond)
                if downHist.count > 30 { downHist.removeFirst() }
                newNet.downloadHistory = downHist
                
                var upHist = self.networkStats.uploadHistory
                upHist.append(net.uploadBytesPerSecond)
                if upHist.count > 30 { upHist.removeFirst() }
                newNet.uploadHistory = upHist
                self.networkStats = newNet
                
                if let procs = procs {
                    self.topCPUProcesses = procs.topCPU
                    self.topMemoryProcesses = procs.topMemory
                }
                
                self.isSampling = false
            }
        }
    }
    
    // MARK: - Formatters
    public static func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        if b >= 1_073_741_824.0 {
            return String(format: "%.2f GB", b / 1_073_741_824.0)
        } else if b >= 1_048_576.0 {
            return String(format: "%.1f MB", b / 1_048_576.0)
        } else if b >= 1024.0 {
            return String(format: "%.0f KB", b / 1024.0)
        } else {
            return "\(bytes) B"
        }
    }
    
    public static func formatThroughput(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1_048_576.0 {
            return String(format: "%.1f MB/s", bytesPerSec / 1_048_576.0)
        } else if bytesPerSec >= 1024.0 {
            return String(format: "%.0f KB/s", bytesPerSec / 1024.0)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }
}
