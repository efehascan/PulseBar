import Foundation

/// getifaddrs ile en* arayüzlerinin bayt sayaçlarından indirme/yükleme hızı ölçer.
/// Önceki sayaç ve zamanı tutar; hız = (şimdiki − önceki) / geçen saniye.
public final class NetworkMonitor {
    private var previousIn: UInt64?
    private var previousOut: UInt64?
    private var previousTime: Date?

    public init() {}

    public func sample() -> NetworkSample {
        var head: UnsafeMutablePointer<ifaddrs>?
        getifaddrs(&head)
        guard let addrs = head else {
            return NetworkSample()
        }
        defer { freeifaddrs(addrs) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var interface = ""
        var interfaceIn: UInt64 = 0

        var current: UnsafeMutablePointer<ifaddrs> = addrs
        while true {
            let entry = current.pointee
            if entry.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               let nameStr = String(validatingUTF8: entry.ifa_name),
               nameStr.hasPrefix("en") {
                if let data = entry.ifa_data {
                    let net = data.assumingMemoryBound(to: if_data.self)
                    let inBytes = UInt64(net.pointee.ifi_ibytes)
                    let outBytes = UInt64(net.pointee.ifi_obytes)
                    totalIn += inBytes
                    totalOut += outBytes
                    if inBytes >= interfaceIn {
                        interfaceIn = inBytes
                        interface = nameStr
                    }
                }
            }
            guard let next = entry.ifa_next else { break }
            current = next
        }

        let now = Date()
        var downPerSecond = 0.0
        var upPerSecond = 0.0

        if let prevIn = previousIn, let prevOut = previousOut, let prevTime = previousTime {
            let interval = now.timeIntervalSince(prevTime)
            if interval > 0 {
                if totalIn >= prevIn {
                    downPerSecond = Double(totalIn - prevIn) / interval
                }
                if totalOut >= prevOut {
                    upPerSecond = Double(totalOut - prevOut) / interval
                }
            }
        }

        previousIn = totalIn
        previousOut = totalOut
        previousTime = now

        return NetworkSample(downPerSecond: downPerSecond,
                             upPerSecond: upPerSecond,
                             totalDown: totalIn,
                             totalUp: totalOut,
                             interface: interface)
    }
}
