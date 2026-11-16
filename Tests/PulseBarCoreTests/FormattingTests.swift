import XCTest
@testable import PulseBarCore

final class FormattingTests: XCTestCase {
    func testBytes() {
        XCTAssertEqual(Fmt.bytes(0), "0 B")
        XCTAssertEqual(Fmt.bytes(512), "512 B")
        XCTAssertEqual(Fmt.bytes(1536), "1,5 KB")
        XCTAssertEqual(Fmt.bytes(12_897_485), "12,3 MB")
        XCTAssertEqual(Fmt.bytes(1_288_490_188), "1,2 GB")
        XCTAssertEqual(Fmt.bytes(2_199_023_255_552), "2,0 TB")
    }
    func testSpeed() {
        XCTAssertEqual(Fmt.speed(0), "0 B/s")
        XCTAssertEqual(Fmt.speed(1536), "1,5 KB/s")
        XCTAssertEqual(Fmt.speed(12_897_485), "12,3 MB/s")
    }
    func testPercent() {
        XCTAssertEqual(Fmt.percent(42.4), "%42")
        XCTAssertEqual(Fmt.percent(42.6), "%43")
        XCTAssertEqual(Fmt.percent(nil), "—")
    }
    func testUptime() {
        XCTAssertEqual(Fmt.uptime(12 * 60 + 30), "12 dk")
        XCTAssertEqual(Fmt.uptime(4 * 3600 + 12 * 60), "4 sa 12 dk")
        XCTAssertEqual(Fmt.uptime(3 * 86400 + 4 * 3600 + 59 * 60), "3 gün 4 sa")
    }
}
