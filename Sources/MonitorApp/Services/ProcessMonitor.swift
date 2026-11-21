import Foundation
import AppKit
import Darwin
import ApplicationServices

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
        
        let isAXTrusted = AXIsProcessTrusted()
        var items: [ProcessItem] = []
        items.reserveCapacity(min(count, 512))
        
        for i in 0..<count {
            let pid = pids[i]
            guard pid > 0 else { continue }
            
            var taskInfo = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.size)
            let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, size)
            guard result == size else { continue }
            
            // Name, Icon & Responsiveness
            let name: String
            let icon: NSImage?
            var isNotResponding = false
            
            // Check process BSD state (stopped or zombie)
            var bsdInfo = proc_bsdinfo()
            let bsdSize = Int32(MemoryLayout<proc_bsdinfo>.size)
            if proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, bsdSize) == bsdSize {
                // SSTOP = 4, SZOMB = 5
                if bsdInfo.pbi_status == 4 || bsdInfo.pbi_status == 5 {
                    isNotResponding = true
                }
            }
            
            if let app = runningAppsMap[pid] {
                name = app.localizedName ?? "App (\(pid))"
                icon = app.icon
                
                // If GUI app, check accessibility event responsiveness
                if !isNotResponding && isAXTrusted && app.activationPolicy == .regular {
                    let axApp = AXUIElementCreateApplication(pid)
                    AXUIElementSetMessagingTimeout(axApp, 0.1) // 100ms timeout
                    var role: CFTypeRef?
                    let axErr = AXUIElementCopyAttributeValue(axApp, kAXRoleAttribute as CFString, &role)
                    if axErr == .cannotComplete {
                        isNotResponding = true
                    }
                }
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
            items.append(ProcessItem(id: pid, name: name, cpuPercentage: cpuPct, memoryBytes: residentMem, icon: icon, isNotResponding: isNotResponding))
        }
        
        // Clean up terminated pids
        if prevTimes.count > 3000 {
            prevTimes.removeAll()
        }
        
        let topCPU = items
            .sorted {
                if $0.isNotResponding != $1.isNotResponding {
                    return $0.isNotResponding && !$1.isNotResponding
                }
                return $0.cpuPercentage > $1.cpuPercentage
            }
            .prefix(25)
        
        let topMemory = items
            .sorted {
                if $0.isNotResponding != $1.isNotResponding {
                    return $0.isNotResponding && !$1.isNotResponding
                }
                return $0.memoryBytes > $1.memoryBytes
            }
            .prefix(25)
        
        return (Array(topCPU), Array(topMemory))
    }
}
