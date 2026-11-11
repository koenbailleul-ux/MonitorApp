import Foundation
import Darwin

public final class NetworkMonitor: @unchecked Sendable {
    private var lastSampleDate: Date = Date()
    private var prevInBytes: UInt64 = 0
    private var prevOutBytes: UInt64 = 0
    private var isFirstSample: Bool = true
    
    public init() {
        _ = sample()
    }
    
    public func sample() -> NetworkStats {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else {
            return NetworkStats()
        }
        defer { freeifaddrs(ifaddrPtr) }
        
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var primaryInterface: String = "en0"
        var primaryBaudRate: UInt64 = 1_000_000_000 // 1 Gbps default
        var ipAddress: String = "127.0.0.1"
        var maxInterfaceBytes: UInt64 = 0
        
        var interfaceIPs: [String: String] = [:]
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let ifa = ptr.pointee
            guard let addr = ifa.ifa_addr else { continue }
            let name = String(cString: ifa.ifa_name)
            
            // Collect IPv4 address
            if addr.pointee.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ip = String(cString: hostname)
                    interfaceIPs[name] = ip
                }
            }
            
            // Link layer bytes
            if addr.pointee.sa_family == UInt8(AF_LINK) {
                guard name != "lo0" && !name.hasPrefix("gif") && !name.hasPrefix("stf") else { continue }
                if let data = ifa.ifa_data {
                    let netData = data.assumingMemoryBound(to: if_data.self).pointee
                    let inBytes = UInt64(netData.ifi_ibytes)
                    let outBytes = UInt64(netData.ifi_obytes)
                    totalIn += inBytes
                    totalOut += outBytes
                    
                    let combined = inBytes + outBytes
                    if combined > maxInterfaceBytes {
                        maxInterfaceBytes = combined
                        primaryInterface = name
                        if netData.ifi_baudrate > 0 {
                            primaryBaudRate = UInt64(netData.ifi_baudrate)
                        }
                    }
                }
            }
        }
        
        if let ip = interfaceIPs[primaryInterface] ?? interfaceIPs["en0"] {
            ipAddress = ip
        }
        
        let now = Date()
        let dt = max(0.2, now.timeIntervalSince(lastSampleDate))
        lastSampleDate = now
        
        if isFirstSample {
            prevInBytes = totalIn
            prevOutBytes = totalOut
            isFirstSample = false
            return NetworkStats(
                totalBytesDownloaded: totalIn,
                totalBytesUploaded: totalOut,
                linkBaudRate: primaryBaudRate,
                interfaceName: primaryInterface,
                ipAddress: ipAddress,
                isWifi: primaryInterface == "en0"
            )
        }
        
        let deltaIn = totalIn >= prevInBytes ? totalIn - prevInBytes : 0
        let deltaOut = totalOut >= prevOutBytes ? totalOut - prevOutBytes : 0
        
        prevInBytes = totalIn
        prevOutBytes = totalOut
        
        let downBytesPerSec = Double(deltaIn) / dt
        let upBytesPerSec = Double(deltaOut) / dt
        
        // Bandwidth percentage: bits/sec / baudrate * 100
        let totalBitsPerSec = (downBytesPerSec + upBytesPerSec) * 8.0
        let linkBaud = Double(max(10_000_000, primaryBaudRate))
        let rawUsagePct = (totalBitsPerSec / linkBaud) * 100.0
        let bandwidthPct = min(100.0, max(0.0, rawUsagePct))
        
        return NetworkStats(
            downloadBytesPerSecond: downBytesPerSec,
            uploadBytesPerSecond: upBytesPerSec,
            totalBytesDownloaded: totalIn,
            totalBytesUploaded: totalOut,
            linkBaudRate: primaryBaudRate,
            bandwidthUsagePercentage: bandwidthPct,
            interfaceName: primaryInterface,
            ipAddress: ipAddress,
            isWifi: primaryInterface == "en0"
        )
    }
}
