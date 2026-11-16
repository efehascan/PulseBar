import Foundation
import IOKit

/// Görev: / biriminin kapasitesi ve IOKit IOBlockStorageDriver istatistiklerinden okuma/yazma hızı.
/// Önceki sayaç ve zamanı tutar; hız = (şimdiki − önceki) / geçen saniye.
public final class DiskMonitor {
    private var previousRead: UInt64?
    private var previousWrite: UInt64?
    private var previousTime: Date?

    public init() {}

    public func sample() -> DiskSample {
        // Kapasite: / biriminin toplam ve boş alanı. Hata olursa 0.
        var total: UInt64 = 0
        var free: UInt64 = 0
        if let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
           let totalCap = values.volumeTotalCapacity,
           let freeCap = values.volumeAvailableCapacityForImportantUsage {
            total = UInt64(totalCap)
            free = UInt64(freeCap)
        }

        // IOKit IOBlockStorageDriver sayaçları (tüm diskler toplamı).
        var readBytes: UInt64 = 0
        var writeBytes: UInt64 = 0

        var iterator: io_iterator_t = 0
        let matched = IOServiceGetMatchingServices(kIOMainPortDefault,
                                                  IOServiceMatching("IOBlockStorageDriver"),
                                                  &iterator)
        if matched == KERN_SUCCESS {
            var service = IOIteratorNext(iterator)
            while service != 0 {
                defer { IOObjectRelease(service) }
                if let cf = IORegistryEntryCreateCFProperty(service, "Statistics" as CFString, kCFAllocatorDefault, 0) {
                    let stats = cf.takeRetainedValue() as? [String: Any]
                    if let read = stats?["Bytes (Read)"] as? NSNumber {
                        readBytes += read.uint64Value
                    }
                    if let write = stats?["Bytes (Write)"] as? NSNumber {
                        writeBytes += write.uint64Value
                    }
                }
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }

        // Hız: önceki sayaçla fark / geçen saniye. İlk çağrıda 0, sayaç küçüldüyse 0.
        let now = Date()
        var readPerSecond = 0.0
        var writePerSecond = 0.0

        if let prevRead = previousRead, let prevWrite = previousWrite, let prevTime = previousTime {
            let interval = now.timeIntervalSince(prevTime)
            if interval > 0 {
                if readBytes >= prevRead {
                    readPerSecond = Double(readBytes - prevRead) / interval
                }
                if writeBytes >= prevWrite {
                    writePerSecond = Double(writeBytes - prevWrite) / interval
                }
            }
        }

        previousRead = readBytes
        previousWrite = writeBytes
        previousTime = now

        return DiskSample(total: total, free: free, readPerSecond: readPerSecond, writePerSecond: writePerSecond)
    }
}
