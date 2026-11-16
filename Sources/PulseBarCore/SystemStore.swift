import Foundation
import Observation

/// Görev: monitörleri saniyede bir örnekleyen, son 60 örneği tutan gözlemlenebilir depo (şu an yer tutucu).
@MainActor
@Observable
public final class SystemStore {
    public private(set) var cpu = CPUSample()
    public private(set) var memory = MemorySample()
    public private(set) var gpu = GPUSample()
    public private(set) var disk = DiskSample()
    public private(set) var network = NetworkSample()
    public private(set) var info = SystemInfo()
    /// Son 60 örnek (en eski başta): CPU %, indirme B/s, yükleme B/s
    public private(set) var cpuHistory: [Double] = []
    public private(set) var downHistory: [Double] = []
    public private(set) var upHistory: [Double] = []

    public init() {}
    public func start(interval: TimeInterval = 1) {}
    public func stop() {}
    /// Bütün monitörleri bir kez örnekler (zamanlayıcı bunu çağırır)
    public func refresh() {}
}
