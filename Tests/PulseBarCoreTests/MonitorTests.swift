import XCTest
@testable import PulseBarCore

/// Gerçek makinede çalışır; değerlerin akla yatkın aralıkta olduğunu kontrol eder.
final class MonitorTests: XCTestCase {
    func testCPU() {
        let m = CPUMonitor(); _ = m.sample()
        Thread.sleep(forTimeInterval: 0.3)
        let s = m.sample()
        XCTAssertFalse(s.cores.isEmpty)
        XCTAssertEqual(s.cores.count, ProcessInfo.processInfo.activeProcessorCount)
        XCTAssert((0...100).contains(s.usage))
        XCTAssert(s.cores.allSatisfy { (0...100).contains($0) })
        XCTAssertEqual(s.loadAverage.count, 3)
    }
    func testMemory() {
        let s = MemoryMonitor().sample()
        XCTAssertEqual(s.total, ProcessInfo.processInfo.physicalMemory)
        XCTAssert(s.used > 0 && s.used <= s.total)
        XCTAssert((0...100).contains(s.pressure) && s.pressure > 0)
    }
    func testGPU() {
        let s = GPUMonitor().sample()
        XCTAssertFalse(s.name.isEmpty)
        if let u = s.utilization { XCTAssert((0...100).contains(u)) }
    }
    func testDisk() {
        let m = DiskMonitor(); _ = m.sample()
        Thread.sleep(forTimeInterval: 0.3)
        let s = m.sample()
        XCTAssert(s.total > 0 && s.free > 0 && s.free < s.total)
        XCTAssert(s.readPerSecond >= 0 && s.writePerSecond >= 0)
    }
    func testNetwork() {
        let m = NetworkMonitor(); _ = m.sample()
        Thread.sleep(forTimeInterval: 0.3)
        let s = m.sample()
        XCTAssert(s.downPerSecond >= 0 && s.upPerSecond >= 0)
        XCTAssert(s.totalDown > 0)
        XCTAssertFalse(s.interface.isEmpty)
    }
    func testSystemInfo() {
        let s = SystemInfoProvider().sample()
        XCTAssertFalse(s.model.isEmpty)
        XCTAssertFalse(s.chip.isEmpty)
        XCTAssert(s.osVersion.hasPrefix("macOS "))
        XCTAssert(s.uptime > 0)
    }
    @MainActor func testStore() {
        let store = SystemStore()
        store.refresh(); store.refresh()
        XCTAssertEqual(store.cpuHistory.count, 2)
        XCTAssertEqual(store.memory.total, ProcessInfo.processInfo.physicalMemory)
        for _ in 0..<70 { store.refresh() }
        XCTAssertEqual(store.cpuHistory.count, 60)
    }
}
