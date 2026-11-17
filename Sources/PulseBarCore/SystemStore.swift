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

    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let gpuMonitor = GPUMonitor()
    private let diskMonitor = DiskMonitor()
    private let networkMonitor = NetworkMonitor()
    private let systemInfoProvider = SystemInfoProvider()
    private let processMonitor = ProcessMonitor()

    private var timer: Timer?
    private var refreshCount = 0

    /// Detay görünümü için ek geçmiş (son 60 örnek): bellek %, GPU %
    public private(set) var memoryHistory: [Double] = []
    public private(set) var gpuHistory: [Double] = []
    /// Detay açıkken odaklanılan kategori; nil ise süreç listesi güncellenmez (gereksiz iş yok)
    public var focus: MetricCategory? = nil
    /// Odak kategorisinin en çok kullanan süreçleri (cpu, memory, network); disk ve gpu için boş
    public private(set) var topProcesses: [ProcessUsage] = []
    /// Disk odağında bağlı birimler
    public private(set) var volumes: [VolumeUsage] = []

    public init() {}

    public func start(interval: TimeInterval = 1) {
        guard timer == nil else { return }
        refresh()
        let t = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Bütün monitörleri bir kez örnekler (zamanlayıcı bunu çağırır)
    public func refresh() {
        cpu = cpuMonitor.sample()
        memory = memoryMonitor.sample()
        gpu = gpuMonitor.sample()
        disk = diskMonitor.sample()
        network = networkMonitor.sample()

        cpuHistory.append(cpu.usage)
        downHistory.append(network.downPerSecond)
        upHistory.append(network.upPerSecond)
        if cpuHistory.count > 60 { cpuHistory.removeFirst(cpuHistory.count - 60) }
        if downHistory.count > 60 { downHistory.removeFirst(downHistory.count - 60) }
        if upHistory.count > 60 { upHistory.removeFirst(upHistory.count - 60) }

        memoryHistory.append(memory.pressure)
        gpuHistory.append(gpu.utilization ?? 0)
        if memoryHistory.count > 60 { memoryHistory.removeFirst(memoryHistory.count - 60) }
        if gpuHistory.count > 60 { gpuHistory.removeFirst(gpuHistory.count - 60) }

        // Detay görünümü: sadece odak kategorisi için süreç/birim listesi güncellenir.
        switch focus {
        case .cpu:
            topProcesses = processMonitor.topByCPU(limit: 6)
        case .memory:
            topProcesses = processMonitor.topByMemory(limit: 6)
        case .network:
            topProcesses = processMonitor.topByNetwork(limit: 6)
        case .disk:
            volumes = processMonitor.volumes()
            topProcesses = []
        case .gpu, .none:
            topProcesses = []
        }

        refreshCount += 1
        if refreshCount % 10 == 1 {
            info = systemInfoProvider.sample()
        }
    }
}
