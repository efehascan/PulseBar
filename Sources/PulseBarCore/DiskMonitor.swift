import Foundation

/// Görev: / biriminin kapasitesi ve IOKit IOBlockStorageDriver istatistiklerinden okuma/yazma hızı (şu an yer tutucu).
public final class DiskMonitor {
    public init() {}
    public func sample() -> DiskSample { DiskSample() }
}
