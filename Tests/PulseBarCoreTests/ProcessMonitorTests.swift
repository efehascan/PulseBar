import XCTest
@testable import PulseBarCore

final class ProcessMonitorTests: XCTestCase {
    func testParsePS() {
        let out = """
          474  44.2 134160 /System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer
        27087 217.6 989776 node
          101   0,0    512 /Applications/Visual Studio Code.app/Contents/MacOS/Code Helper
        """
        let p = ProcessMonitor.parsePS(out)
        XCTAssertEqual(p.count, 3)
        XCTAssertEqual(p[0], ProcessUsage(id: 474, name: "WindowServer", cpu: 44.2, memory: 134160 * 1024))
        XCTAssertEqual(p[1].name, "node"); XCTAssertEqual(p[1].cpu, 217.6)
        XCTAssertEqual(p[2].name, "Code Helper"); XCTAssertEqual(p[2].cpu, 0)
    }
    func testParseNettop() {
        let out = """
        ,bytes_in,bytes_out,
        mDNSResponder.545,35256527,14447402,
        Google Chrome H.812,1000,200,
        bozuk satır
        """
        let n = ProcessMonitor.parseNettop(out)
        XCTAssertEqual(n.count, 2)
        XCTAssertEqual(n[545]?.name, "mDNSResponder"); XCTAssertEqual(n[545]?.bytesIn, 35256527)
        XCTAssertEqual(n[812]?.name, "Google Chrome H"); XCTAssertEqual(n[812]?.bytesOut, 200)
    }
    func testLive() {
        let m = ProcessMonitor()
        let cpu = m.topByCPU(limit: 5), mem = m.topByMemory(limit: 5)
        XCTAssertEqual(cpu.count, 5); XCTAssertEqual(mem.count, 5)
        XCTAssert(zip(mem, mem.dropFirst()).allSatisfy { $0.memory >= $1.memory })
        XCTAssert(zip(cpu, cpu.dropFirst()).allSatisfy { $0.cpu >= $1.cpu })
        let v = m.volumes()
        XCTAssertFalse(v.isEmpty); XCTAssertEqual(v[0].id, "/"); XCTAssert(v[0].total > v[0].free)
    }
    @MainActor func testStoreFocus() {
        let s = SystemStore()
        s.refresh()
        XCTAssertEqual(s.topProcesses, [])
        s.focus = .memory; s.refresh()
        XCTAssertFalse(s.topProcesses.isEmpty)
        XCTAssertEqual(s.memoryHistory.count, 2); XCTAssertEqual(s.gpuHistory.count, 2)
        s.focus = .disk; s.refresh()
        XCTAssertFalse(s.volumes.isEmpty)
    }
}
