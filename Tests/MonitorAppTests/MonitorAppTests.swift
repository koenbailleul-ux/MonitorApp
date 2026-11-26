import XCTest
@testable import MonitorApp

final class MonitorAppTests: XCTestCase {
    
    func testMenuBarDisplayStyleCases() {
        XCTAssertEqual(MenuBarDisplayStyle.allCases.count, 4)
        XCTAssertEqual(MenuBarDisplayStyle.text.rawValue, "text")
        XCTAssertEqual(MenuBarDisplayStyle.bar.rawValue, "bar")
        XCTAssertEqual(MenuBarDisplayStyle.history.rawValue, "history")
        XCTAssertEqual(MenuBarDisplayStyle.barAndText.rawValue, "barAndText")
        
        XCTAssertFalse(MenuBarDisplayStyle.text.displayName.isEmpty)
        XCTAssertFalse(MenuBarDisplayStyle.bar.displayName.isEmpty)
        XCTAssertFalse(MenuBarDisplayStyle.history.displayName.isEmpty)
        XCTAssertFalse(MenuBarDisplayStyle.barAndText.displayName.isEmpty)
    }
    
    func testAppSettingsMenuBarStyles() {
        let settings = AppSettings.shared
        
        settings.menuBarStyle = .bar
        XCTAssertEqual(settings.cpuDisplayStyle, .bar)
        XCTAssertEqual(settings.memoryDisplayStyle, .bar)
        XCTAssertEqual(settings.networkDisplayStyle, .bar)
        
        settings.cpuDisplayStyle = .history
        XCTAssertEqual(settings.cpuDisplayStyle, .history)
        XCTAssertEqual(settings.memoryDisplayStyle, .bar)
        
        settings.enableHoverZoom = true
        XCTAssertTrue(settings.enableHoverZoom)
        settings.enableHoverZoom = false
        XCTAssertFalse(settings.enableHoverZoom)
        settings.enableHoverZoom = true
    }
    
    func testNetworkStatsHistoryBuffers() {
        var stats = NetworkStats()
        XCTAssertEqual(stats.bandwidthHistory.count, 30)
        XCTAssertEqual(stats.throughputHistory.count, 30)
        
        stats.bandwidthHistory.append(42.0)
        if stats.bandwidthHistory.count > 30 {
            stats.bandwidthHistory.removeFirst()
        }
        XCTAssertEqual(stats.bandwidthHistory.count, 30)
        XCTAssertEqual(stats.bandwidthHistory.last, 42.0)
    }
    
    func testCPUStatsHistory() {
        var cpu = CPUStats()
        XCTAssertEqual(cpu.history.count, 30)
        
        cpu.history.append(75.5)
        if cpu.history.count > 30 {
            cpu.history.removeFirst()
        }
        XCTAssertEqual(cpu.history.count, 30)
        XCTAssertEqual(cpu.history.last, 75.5)
    }
}
