import Foundation

/// Bir ölçüm anı. Bütün monitörler bu tipleri döndürür; arayüz sadece bunları okur.

public struct CPUSample: Equatable, Sendable {
    /// Toplam kullanım, 0...100
    public var usage: Double
    /// Kullanıcı ve sistem payı, 0...100 (usage ≈ user + system)
    public var user: Double
    public var system: Double
    /// Çekirdek başına kullanım, 0...100
    public var cores: [Double]
    /// 1, 5, 15 dakikalık yük ortalaması
    public var loadAverage: [Double]

    public init(usage: Double = 0, user: Double = 0, system: Double = 0, cores: [Double] = [], loadAverage: [Double] = []) {
        self.usage = usage; self.user = user; self.system = system; self.cores = cores; self.loadAverage = loadAverage
    }
}

public struct MemorySample: Equatable, Sendable {
    /// Bayt cinsinden
    public var total: UInt64
    public var used: UInt64        // app + wired + compressed
    public var app: UInt64
    public var wired: UInt64
    public var compressed: UInt64
    public var free: UInt64
    public var swapUsed: UInt64
    /// Bellek baskısı, 0...100 (used / total)
    public var pressure: Double

    public init(total: UInt64 = 0, used: UInt64 = 0, app: UInt64 = 0, wired: UInt64 = 0, compressed: UInt64 = 0,
                free: UInt64 = 0, swapUsed: UInt64 = 0, pressure: Double = 0) {
        self.total = total; self.used = used; self.app = app; self.wired = wired; self.compressed = compressed
        self.free = free; self.swapUsed = swapUsed; self.pressure = pressure
    }
}

public struct GPUSample: Equatable, Sendable {
    /// Cihaz kullanımı, 0...100; okunamazsa nil
    public var utilization: Double?
    /// GPU'nun kullandığı bellek, bayt; okunamazsa nil
    public var memoryUsed: UInt64?
    public var name: String

    public init(utilization: Double? = nil, memoryUsed: UInt64? = nil, name: String = "GPU") {
        self.utilization = utilization; self.memoryUsed = memoryUsed; self.name = name
    }
}

public struct DiskSample: Equatable, Sendable {
    /// Ana birim (/), bayt
    public var total: UInt64
    public var free: UInt64
    /// Bütün diskler toplamı, bayt/saniye
    public var readPerSecond: Double
    public var writePerSecond: Double

    public var used: UInt64 { total > free ? total - free : 0 }
    public var usedPercent: Double { total == 0 ? 0 : Double(used) / Double(total) * 100 }

    public init(total: UInt64 = 0, free: UInt64 = 0, readPerSecond: Double = 0, writePerSecond: Double = 0) {
        self.total = total; self.free = free; self.readPerSecond = readPerSecond; self.writePerSecond = writePerSecond
    }
}

public struct NetworkSample: Equatable, Sendable {
    /// bayt/saniye
    public var downPerSecond: Double
    public var upPerSecond: Double
    /// Açılıştan beri toplam, bayt
    public var totalDown: UInt64
    public var totalUp: UInt64
    /// Ana arayüz adı (ör. en0); yoksa ""
    public var interface: String

    public init(downPerSecond: Double = 0, upPerSecond: Double = 0, totalDown: UInt64 = 0, totalUp: UInt64 = 0, interface: String = "") {
        self.downPerSecond = downPerSecond; self.upPerSecond = upPerSecond; self.totalDown = totalDown; self.totalUp = totalUp
        self.interface = interface
    }
}

public struct SystemInfo: Equatable, Sendable {
    public var model: String        // ör. "Mac16,7"
    public var chip: String         // ör. "Apple M5 Pro"
    public var osVersion: String    // ör. "macOS 27.2.1"
    public var uptime: TimeInterval
    public var thermal: ThermalLevel
    /// Pil yüzdesi 0...100; pil yoksa nil
    public var batteryPercent: Int?
    public var isCharging: Bool?

    public init(model: String = "", chip: String = "", osVersion: String = "", uptime: TimeInterval = 0,
                thermal: ThermalLevel = .nominal, batteryPercent: Int? = nil, isCharging: Bool? = nil) {
        self.model = model; self.chip = chip; self.osVersion = osVersion; self.uptime = uptime
        self.thermal = thermal; self.batteryPercent = batteryPercent; self.isCharging = isCharging
    }
}

public enum ThermalLevel: String, Sendable {
    case nominal, fair, serious, critical
}
