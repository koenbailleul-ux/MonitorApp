import Foundation
import Darwin
import IOKit

public final class CPUMonitor: @unchecked Sendable {
    private var prevCpuLoadInfo: [processor_cpu_load_info] = []
    private var coreClassifications: [Int: CoreType] = [:]
    public private(set) var chipName: String = "Apple Silicon"
    public private(set) var coreCount: Int = 0
    
    public init() {
        self.chipName = Self.readBrandString()
        self.coreClassifications = Self.detectCoreClassifications()
        
        var ncpu: Int32 = 0
        var len = MemoryLayout<Int32>.size
        sysctlbyname("hw.logicalcpu", &ncpu, &len, nil, 0)
        self.coreCount = Int(ncpu > 0 ? ncpu : 8)
        
        // Prime initial sample
        _ = sample()
    }
    
    public func sample() -> CPUStats {
        var numCPUs: natural_t = 0
        var processorInfo: processor_info_array_t?
        var numProcessorInfo: mach_msg_type_number_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &processorInfo,
            &numProcessorInfo
        )
        
        guard result == KERN_SUCCESS, let info = processorInfo else {
            return CPUStats(overallUsage: 0.0, userUsage: 0.0, systemUsage: 0.0, idleUsage: 100.0, cores: [], chipName: chipName)
        }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numProcessorInfo * UInt32(MemoryLayout<integer_t>.size)))
        }
        
        let cpus = Int(numCPUs)
        let cpuLoadInfo = (0..<cpus).map { i -> processor_cpu_load_info in
            let offset = i * Int(CPU_STATE_MAX)
            let user = UInt32(info[offset + Int(CPU_STATE_USER)])
            let system = UInt32(info[offset + Int(CPU_STATE_SYSTEM)])
            let idle = UInt32(info[offset + Int(CPU_STATE_IDLE)])
            let nice = UInt32(info[offset + Int(CPU_STATE_NICE)])
            return processor_cpu_load_info(cpu_ticks: (user, system, idle, nice))
        }
        
        if prevCpuLoadInfo.isEmpty || prevCpuLoadInfo.count != cpus {
            prevCpuLoadInfo = cpuLoadInfo
            var cores: [CPUCoreInfo] = []
            for i in 0..<cpus {
                let type = coreClassifications[i] ?? .performance
                cores.append(CPUCoreInfo(id: i, name: "Core \(i + 1)", type: type, usage: 0.0))
            }
            return CPUStats(overallUsage: 0.0, userUsage: 0.0, systemUsage: 0.0, idleUsage: 100.0, cores: cores, chipName: chipName)
        }
        
        var totalUserDelta: UInt64 = 0
        var totalSystemDelta: UInt64 = 0
        var totalNiceDelta: UInt64 = 0
        var totalIdleDelta: UInt64 = 0
        
        var coreInfos: [CPUCoreInfo] = []
        coreInfos.reserveCapacity(cpus)
        
        for i in 0..<cpus {
            let current = cpuLoadInfo[i].cpu_ticks
            let previous = prevCpuLoadInfo[i].cpu_ticks
            
            let userDelta = UInt64(current.0 >= previous.0 ? current.0 - previous.0 : 0)
            let sysDelta = UInt64(current.1 >= previous.1 ? current.1 - previous.1 : 0)
            let idleDelta = UInt64(current.2 >= previous.2 ? current.2 - previous.2 : 0)
            let niceDelta = UInt64(current.3 >= previous.3 ? current.3 - previous.3 : 0)
            
            totalUserDelta += userDelta
            totalSystemDelta += sysDelta
            totalIdleDelta += idleDelta
            totalNiceDelta += niceDelta
            
            let coreTotal = userDelta + sysDelta + idleDelta + niceDelta
            let coreUsage: Double
            if coreTotal > 0 {
                coreUsage = min(100.0, max(0.0, Double(userDelta + sysDelta + niceDelta) / Double(coreTotal) * 100.0))
            } else {
                coreUsage = 0.0
            }
            
            let coreType = coreClassifications[i] ?? .performance
            coreInfos.append(CPUCoreInfo(id: i, name: "Core \(i + 1)", type: coreType, usage: coreUsage))
        }
        
        prevCpuLoadInfo = cpuLoadInfo
        
        let allDelta = totalUserDelta + totalSystemDelta + totalIdleDelta + totalNiceDelta
        var overallUsage = 0.0
        var userPct = 0.0
        var sysPct = 0.0
        var idlePct = 100.0
        
        if allDelta > 0 {
            userPct = Double(totalUserDelta + totalNiceDelta) / Double(allDelta) * 100.0
            sysPct = Double(totalSystemDelta) / Double(allDelta) * 100.0
            idlePct = Double(totalIdleDelta) / Double(allDelta) * 100.0
            overallUsage = min(100.0, max(0.0, userPct + sysPct))
        }
        
        return CPUStats(
            overallUsage: overallUsage,
            userUsage: userPct,
            systemUsage: sysPct,
            idleUsage: idlePct,
            cores: coreInfos,
            chipName: chipName
        )
    }
    
    private static func readBrandString() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else { return "Apple Silicon" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
        let brand = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        return brand.isEmpty ? "Apple Silicon" : brand
    }
    
    private static func detectCoreClassifications() -> [Int: CoreType] {
        var result: [Int: CoreType] = [:]
        
        // Inspect perflevel sysctl names
        var nperflevels: Int32 = 0
        var s = MemoryLayout<Int32>.size
        sysctlbyname("hw.nperflevels", &nperflevels, &s, nil, 0)
        
        var levelNames: [String] = []
        for i in 0..<nperflevels {
            var nameBuf = [CChar](repeating: 0, count: 64)
            var nameSize = nameBuf.count
            sysctlbyname("hw.perflevel\(i).name", &nameBuf, &nameSize, nil, 0)
            let name = String(cString: nameBuf).trimmingCharacters(in: .whitespacesAndNewlines)
            levelNames.append(name)
        }
        
        // Inspect IOKit IOPlatformDevice cpus
        var iterator = io_iterator_t()
        let matching = IOServiceMatching("IOPlatformDevice")
        if IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS {
            var entry = IOIteratorNext(iterator)
            while entry != 0 {
                var nameBuffer = [CChar](repeating: 0, count: 128)
                IORegistryEntryGetName(entry, &nameBuffer)
                let devName = String(cString: nameBuffer)
                if devName.hasPrefix("cpu") && !devName.contains("cpus") && !devName.contains("debug") {
                    var props: Unmanaged<CFMutableDictionary>?
                    if IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                       let dict = props?.takeRetainedValue() as? [String: Any] {
                        if let cpuId = dict["logical-cpu-id"] as? Int {
                            if let clusterData = dict["cluster-type"] as? Data,
                               let clusterStr = String(data: clusterData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) {
                                if clusterStr.contains("E") {
                                    result[cpuId] = .efficiency
                                } else if clusterStr.contains("M") {
                                    // Mid / Performance core
                                    result[cpuId] = .performance
                                } else if clusterStr.contains("P") {
                                    // Check if level0 is Super
                                    if levelNames.first?.localizedCaseInsensitiveContains("Super") == true {
                                        result[cpuId] = .superCore
                                    } else {
                                        result[cpuId] = .performance
                                    }
                                }
                            }
                        }
                    }
                }
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        
        // Fallback if IOKit didn't yield all cores
        var ncpu: Int32 = 0
        var len = MemoryLayout<Int32>.size
        sysctlbyname("hw.logicalcpu", &ncpu, &len, nil, 0)
        let total = Int(ncpu > 0 ? ncpu : 8)
        
        if result.count < total {
            if nperflevels >= 2 {
                var perf0Count: Int32 = 0
                sysctlbyname("hw.perflevel0.logicalcpu", &perf0Count, &s, nil, 0)
                let p0 = Int(perf0Count)
                let isLevel0Super = levelNames.first?.localizedCaseInsensitiveContains("Super") == true
                
                for id in 0..<total {
                    if result[id] == nil {
                        if id < p0 {
                            result[id] = isLevel0Super ? .superCore : .performance
                        } else {
                            result[id] = isLevel0Super ? .performance : .efficiency
                        }
                    }
                }
            } else {
                for id in 0..<total {
                    if result[id] == nil {
                        result[id] = .standard
                    }
                }
            }
        }
        
        return result
    }
}
