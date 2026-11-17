import Foundation

/// Görev: süreç bazında CPU, bellek ve ağ kullanımı; bağlı birimler (şu an yer tutucu).
public final class ProcessMonitor {
    public init() {}
    /// CPU'ya göre azalan, en çok `limit`
    public func topByCPU(limit: Int) -> [ProcessUsage] { [] }
    /// Belleğe göre azalan, en çok `limit`
    public func topByMemory(limit: Int) -> [ProcessUsage] { [] }
    /// Ağ hızına (indirme + yükleme) göre azalan; ilk çağrıda önceki sayaç yoksa hızlar 0, en çok `limit`
    public func topByNetwork(limit: Int) -> [ProcessUsage] { [] }
    /// Bağlı yerel birimler (kök birim önce)
    public func volumes() -> [VolumeUsage] { [] }
    /// `ps -axo pid=,pcpu=,rss=,comm=` çıktısı → süreçler (rss KB'den bayta)
    public static func parsePS(_ output: String) -> [ProcessUsage] { [] }
    /// `nettop -P -L 1 -x -J bytes_in,bytes_out` çıktısı → [pid: (ad, gelen, giden)] toplam baytlar
    public static func parseNettop(_ output: String) -> [Int32: (name: String, bytesIn: UInt64, bytesOut: UInt64)] { [:] }
}
