import Foundation

/// Görev: IOKit IOAccelerator "PerformanceStatistics" sözlüğünden GPU kullanımını oku (şu an yer tutucu).
public final class GPUMonitor {
    public init() {}
    public func sample() -> GPUSample { GPUSample() }
}
