import Foundation
import Darwin

/// Görev: host_processor_info ile çekirdek başına tick farkından kullanım hesapla.
public final class CPUMonitor {
    /// Bir çekirdeğin (user, system, idle, nice) sayaçları.
    private struct Counts {
        var user: UInt64
        var system: UInt64
        var idle: UInt64
        var nice: UInt64
    }
    /// Önceki örnekleme anındaki sayaçlar; ilk çağrıda boş.
    private var previous: [Counts]?

    public init() {}

    /// İlk çağrıda açılıştan beri ortalama; sonraki çağrılarda son çağrıdan beri olan kullanımı verir.
    public func sample() -> CPUSample {
        guard let current = readTicks() else { return CPUSample() }
        // Yük ortalaması her çağrıda hesaplanabilir.
        var load = [Double](repeating: 0, count: 3)
        getloadavg(&load, 3)

        // Önceki yoksa mutlak tick'lerden (açılıştan beri ortalama) hesapla.
        let prev = previous ?? current.map { _ in Counts(user: 0, system: 0, idle: 0, nice: 0) }
        // Uzunluktaki uyumsuzluğu kes; fazla/eksik olan çekirdek için fark 0 alınır.
        let n = min(prev.count, current.count)

        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalNice: UInt64 = 0
        var totalIdle: UInt64 = 0
        var cores: [Double] = []
        cores.reserveCapacity(current.count)

        for i in 0..<current.count {
            let p = i < n ? prev[i] : Counts(user: 0, system: 0, idle: 0, nice: 0)
            let c = current[i]
            // Sayaç küçülürse (reset) fark 0 say; negatif hız üretme.
            let du = c.user > p.user ? c.user - p.user : 0
            let ds = c.system > p.system ? c.system - p.system : 0
            let di = c.idle > p.idle ? c.idle - p.idle : 0
            let dn = c.nice > p.nice ? c.nice - p.nice : 0
            let busy = du + ds + dn
            let total = busy + di
            let usage = total == 0 ? 0 : Double(busy) / Double(total) * 100
            cores.append(clamp(usage))
            totalUser += du
            totalSystem += ds
            totalNice += dn
            totalIdle += di
        }

        let tBusy = totalUser + totalSystem + totalNice
        let tTotal = tBusy + totalIdle
        let usage = tTotal == 0 ? 0 : Double(tBusy) / Double(tTotal) * 100
        let user = tTotal == 0 ? 0 : Double(totalUser) / Double(tTotal) * 100
        let system = tTotal == 0 ? 0 : Double(totalSystem) / Double(tTotal) * 100

        // Önceki sayaçları güncelle; sonraki çağrı fark alacak.
        previous = current

        return CPUSample(
            usage: clamp(usage),
            user: clamp(user),
            system: clamp(system),
            cores: cores,
            loadAverage: load
        )
    }

    /// Her çekirdeğin cpu_ticks değerlerini okur; başarısızsa nil döndürür.
    private func readTicks() -> [Counts]? {
        var cpuCount: mach_msg_type_number_t = 0
        var info: processor_info_array_t? = nil
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &info,
            &infoCount
        )
        guard result == KERN_SUCCESS, let info = info else { return nil }

        // info, Mach kütüphanesi tarafından tahsis edilmiş; okuduktan sonra bırakılmalı.
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: info),
                vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            )
        }

        // Her çekirdeğin satırı CPU_STATE_MAX=4 elemanlık; son satır da tam bu uzunluktadır.
        // integer_t 32-bit olduğundan tick değerlerini 32 bit olarak okuruz; sayaçlar
        // teorik olarak taşabilir, bu yüzden aynı bitleri işaretli sayıya yeniden
        // yorumlamadan UInt32 alıyoruz (taşan sayaç doğal olarak sarmalanır, crash yok).
        let stride = Int(CPU_STATE_MAX)
        let count = Int(infoCount) / stride
        var ticks = [UInt32](repeating: 0, count: Int(infoCount))
        _ = ticks.withUnsafeMutableBufferPointer { buffer in
            memcpy(buffer.baseAddress, info, Int(infoCount) * MemoryLayout<UInt32>.stride)
        }
        var counts: [Counts] = []
        counts.reserveCapacity(count)
        for i in 0..<count {
            let base = i * stride
            counts.append(Counts(
                user: UInt64(ticks[base + Int(CPU_STATE_USER)]),
                system: UInt64(ticks[base + Int(CPU_STATE_SYSTEM)]),
                idle: UInt64(ticks[base + Int(CPU_STATE_IDLE)]),
                nice: UInt64(ticks[base + Int(CPU_STATE_NICE)])
            ))
        }
        return counts
    }

    /// 0...100 aralığına sıkıştırır.
    private func clamp(_ v: Double) -> Double {
        return min(max(v, 0), 100)
    }
}
