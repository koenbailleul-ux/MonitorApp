import Foundation
import Darwin

public final class MemoryMonitor: @unchecked Sendable {
    private let hostPort: mach_port_t
    private let pageSize: vm_size_t
    public private(set) var totalRAM: UInt64 = 0
    
    public init() {
        self.hostPort = mach_host_self()
        var size: vm_size_t = 0
        host_page_size(hostPort, &size)
        self.pageSize = size > 0 ? size : 16384
        
        var memSize: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &memSize, &len, nil, 0)
        self.totalRAM = memSize > 0 ? memSize : (16 * 1024 * 1024 * 1024)
    }
    
    public func sample() -> MemoryStats {
        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let kr = withUnsafeMutablePointer(to: &vmStat) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }
        
        guard kr == KERN_SUCCESS else {
            return MemoryStats(totalBytes: totalRAM)
        }
        
        let pSize = UInt64(pageSize)
        let wired = UInt64(vmStat.wire_count) * pSize
        let active = UInt64(vmStat.active_count) * pSize
        let inactive = UInt64(vmStat.inactive_count) * pSize
        let compressed = UInt64(vmStat.compressor_page_count) * pSize
        let free = UInt64(vmStat.free_count) * pSize
        let purgeable = UInt64(vmStat.purgeable_count) * pSize
        
        // Memory used: Active + Wired + Compressed (all used memory excluding inactive cache and free RAM)
        let used = active + wired + compressed
        let safeUsed = min(totalRAM, used)
        let usedPct = totalRAM > 0 ? (Double(safeUsed) / Double(totalRAM) * 100.0) : 0.0
        let wiredPct = totalRAM > 0 ? (Double(wired) / Double(totalRAM) * 100.0) : 0.0
        
        // Memory Pressure Level
        var pressureLevel: Int32 = 1
        var presSize = MemoryLayout<Int32>.size
        sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureLevel, &presSize, nil, 0)
        
        let pressureStatus: MemoryPressureStatus
        switch pressureLevel {
        case 2:
            pressureStatus = .warning
        case 4:
            pressureStatus = .critical
        default:
            pressureStatus = .normal
        }
        
        // Calculate continuous pressure percentage
        // In macOS, free and purgeable represent the immediate headroom
        let headroom = Double(free + purgeable)
        let total = Double(totalRAM)
        let rawPressure = max(0.0, min(100.0, (1.0 - (headroom / total)) * 100.0))
        let pressurePct: Double
        if pressureLevel == 4 {
            pressurePct = max(80.0, rawPressure)
        } else if pressureLevel == 2 {
            pressurePct = max(55.0, min(79.0, rawPressure))
        } else {
            pressurePct = min(49.0, rawPressure * 0.65)
        }
        
        // Swap Usage
        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0)
        
        let swapTotal = UInt64(swap.xsu_total)
        let swapUsed = UInt64(swap.xsu_used)
        let swapAvail = UInt64(swap.xsu_avail)
        let swapPct = swapTotal > 0 ? (Double(swapUsed) / Double(swapTotal) * 100.0) : 0.0
        
        return MemoryStats(
            totalBytes: totalRAM,
            usedBytes: safeUsed,
            freeBytes: free,
            wiredBytes: wired,
            pressureLevel: pressureLevel,
            pressureStatus: pressureStatus,
            pressurePercentage: pressurePct,
            swapTotalBytes: swapTotal,
            swapUsedBytes: swapUsed,
            swapFreeBytes: swapAvail,
            swapPercentage: swapPct,
            activeBytes: active,
            inactiveBytes: inactive,
            compressedBytes: compressed,
            purgeableBytes: purgeable,
            usedPercentage: usedPct,
            wiredPercentage: wiredPct
        )
    }
}
