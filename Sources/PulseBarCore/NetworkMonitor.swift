import Foundation

/// Görev: getifaddrs ile arayüz bayt sayaçlarından indirme/yükleme hızı (şu an yer tutucu).
public final class NetworkMonitor {
    public init() {}
    public func sample() -> NetworkSample { NetworkSample() }
}
