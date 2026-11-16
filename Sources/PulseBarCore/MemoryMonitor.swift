import Foundation

/// Görev: host_statistics64 (HOST_VM_INFO64) ve sysctl ile bellek kullanımını oku (şu an yer tutucu).
public final class MemoryMonitor {
    public init() {}
    public func sample() -> MemorySample { MemorySample() }
}
