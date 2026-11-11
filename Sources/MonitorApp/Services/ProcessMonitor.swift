import Foundation
import AppKit
import Darwin

public final class ProcessMonitor: @unchecked Sendable {
    private struct PreviousProcTime {
        let timestamp: Date
        let cpuTime: UInt64
    }
    
    private var prevTimes: [pid_t: PreviousProcTime] = [:]
    
    public init() {}
    
    public func sample() -> (topCPU: [ProcessItem], topMemory: [ProcessItem]) {
        var pids = [pid_t](repeating: 0, count: 2048)
        let bytesReturned = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(MemoryLayout<pid_t>.size * pids.count))
        let count = Int(bytesReturned) / MemoryLayout<pid_t>.size
        guard count > 0 else { return ([], []) }
        
        let now = Date()
        var runningAppsMap: [pid_t: NSRunningApplication] = [:]
        for app in NSWorkspace.shared.runningApplications {
            runningAppsMap[app.processIdentifier] = app
        }
        
        var items: [ProcessItem] = []
        items.reserveCapacity(min(count, 512))
        
        for i in 0..<count {
            let pid = pids[i]
            guard pid > 0 else { continue }
            
            var taskInfo = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.size)
            let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, size)
            guard result == size else { continue }
            
            // Name & Icon
            let name: String
            let icon: NSImage?
            if let app = runningAppsMap[pid] {
                name = app.localizedName ?? "App (\(pid))"
                icon = app.icon
            } else {
                var nameBuf = [CChar](repeating: 0, count: 128)
                proc_name(pid, &nameBuf, 128)
                let procStr = String(cString: nameBuf).trimmingCharacters(in: .whitespacesAndNewlines)
                name = procStr.isEmpty ? "Process \(pid)" : procStr
                icon = nil
            }
            
            // CPU Calculation
            let totalCpuTime = taskInfo.pti_total_user + taskInfo.pti_total_system
            var cpuPct = 0.0
            if let prev = prevTimes[pid] {
                let dt = now.timeIntervalSince(prev.timestamp)
                if dt > 0.1 && totalCpuTime >= prev.cpuTime {
                    let deltaNanoseconds = Double(totalCpuTime - prev.cpuTime)
                    // Convert nanoseconds to percentage over dt seconds
                    let cpuSeconds = deltaNanoseconds / 1_000_000_000.0
                    cpuPct = min(800.0, max(0.0, (cpuSeconds / dt) * 100.0))
                }
            }
            prevTimes[pid] = PreviousProcTime(timestamp: now, cpuTime: totalCpuTime)
            
            let residentMem = UInt64(taskInfo.pti_resident_size)
            items.append(ProcessItem(id: pid, name: name, cpuPercentage: cpuPct, memoryBytes: residentMem, icon: icon))
        }
        
        // Clean up terminated pids
        if prevTimes.count > 3000 {
            prevTimes.removeAll()
        }
        
        let topCPU = items
            .filter { $0.cpuPercentage > 0.1 }
            .sorted { $0.cpuPercentage > $1.cpuPercentage }
            .prefix(5)
        
        let topMemory = items
            .filter { $0.memoryBytes > 5 * 1024 * 1024 } // > 5MB
            .sorted { $0.memoryBytes > $1.memoryBytes }
            .prefix(5)
        
        return (Array(topCPU), Array(topMemory))
    }
}
