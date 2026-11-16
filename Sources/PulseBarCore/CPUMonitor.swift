import Foundation

/// Görev: host_processor_info ile çekirdek başına tick farkından kullanım hesapla (şu an yer tutucu).
public final class CPUMonitor {
    public init() {}
    /// İlk çağrıda önceki ölçüm yoksa 0 dönebilir; sonraki çağrılar son çağrıdan beri olan kullanımı verir.
    public func sample() -> CPUSample { CPUSample() }
}
