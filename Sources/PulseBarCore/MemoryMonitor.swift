import Foundation
import Darwin

/// Görev: host_statistics64 (HOST_VM_INFO64) ve sysctl ile bellek kullanımını oku.
public final class MemoryMonitor {
    public init() {}

    public func sample() -> MemorySample {
        let total = ProcessInfo.processInfo.physicalMemory
        var sample = MemorySample()
        sample.total = total

        guard let stats = readVMStatistics() else {
            // host_statistics64 başarısız: sadece total dolu bir örnek döndür.
            sample.swapUsed = readSwapUsed()
            return sample
        }

        let page = UInt64(vm_kernel_page_size)
        // app = (internal − purgeable) × sayfa; negatif olursa 0.
        let appPages = stats.internal_page_count > stats.purgeable_count
            ? UInt64(stats.internal_page_count - stats.purgeable_count)
            : UInt64(0)
        let app = appPages * page
        let wired = UInt64(stats.wire_count) * page
        let compressed = UInt64(stats.compressor_page_count) * page
        let free = UInt64(stats.free_count) * page

        // used = app + wired + compressed; toplamı geçemez.
        var used = app + wired + compressed
        if used > total { used = total }

        // pressure = used / total × 100, 0...100 aralığına sıkıştırılır.
        let pressure = total == 0 ? 0 : min(max(Double(used) / Double(total) * 100, 0), 100)

        sample.app = app
        sample.wired = wired
        sample.compressed = compressed
        sample.free = free
        sample.used = used
        sample.pressure = pressure
        sample.swapUsed = readSwapUsed()
        return sample
    }

    /// host_statistics64 ile vm_statistics64 okur; başarısızsa nil döndürür.
    private func readVMStatistics() -> vm_statistics64? {
        var stats = vm_statistics64()

        // host_statistics64 sayacı integer_t (32 bit) eleman sayısı olarak bekler:
        // HOST_VM_INFO64_COUNT = sizeof(vm_statistics64) / sizeof(integer_t).
        // (8 bayta bölmek yapının yalnızca yarısını doldurur; Gemma incelemesi yakaladı.)
        let count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        var infoCount = count

        let result = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    intPtr,
                    &infoCount
                )
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return stats
    }

    /// sysctlbyname("vm.swapusage") ile kullanımdaki swap (bayt) okur.
    private func readSwapUsed() -> UInt64 {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        let result = withUnsafeMutablePointer(to: &usage) { usagePtr in
            usagePtr.withMemoryRebound(to: UInt8.self, capacity: size) { bytes in
                sysctlbyname("vm.swapusage", bytes, &size, nil, 0)
            }
        }
        guard result == 0 else { return 0 }
        return UInt64(usage.xsu_used)
    }
}
