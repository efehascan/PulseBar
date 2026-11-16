import Foundation
import IOKit

/// Görev: IOKit IOAccelerator "PerformanceStatistics" sözlüğünden GPU kullanımını oku.
public final class GPUMonitor {
    public init() {}

    public func sample() -> GPUSample {
        var iter = io_iterator_t()
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iter)
        guard result == KERN_SUCCESS else {
            return GPUSample(utilization: nil, memoryUsed: nil, name: "GPU")
        }

        defer { IOObjectRelease(iter) }

        var service = IOIteratorNext(iter)
        while service != 0 {
            if let stats = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)
                .takeRetainedValue() as? [String: Any] {
                var utilization: Double?
                if let value = stats["Device Utilization %"] as? NSNumber {
                    utilization = min(100, max(0, value.doubleValue))
                }

                var memoryUsed: UInt64?
                if let value = stats["In use system memory"] as? NSNumber {
                    memoryUsed = value.uint64Value
                }

                let name = Self.deviceName(service)
                IOObjectRelease(service)

                return GPUSample(
                    utilization: utilization,
                    memoryUsed: memoryUsed,
                    name: name
                )
            }

            IOObjectRelease(service)
            service = IOIteratorNext(iter)
        }

        return GPUSample(utilization: nil, memoryUsed: nil, name: "GPU")
    }

    /// "model" özelliğini String ya da Data olarak okur; okunamazsa "GPU".
    private static func deviceName(_ service: io_service_t) -> String {
        guard let cf = modelProperty(service) else {
            return "GPU"
        }
        if let data = cf as? Data {
            return trimNul(String(decoding: data, as: UTF8.self))
        }
        if let string = cf as? String {
            return string
        }
        return "GPU"
    }

    /// "model" özellik CF nesnesini optional olarak alır; okunamazsa nil.
    private static func modelProperty(_ service: io_service_t) -> AnyObject? {
        let property = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)
        return property?.takeRetainedValue()
    }

    private static func trimNul(_ string: String) -> String {
        var end = string.endIndex
        while end > string.startIndex, string[string.index(before: end)] == "\0" {
            end = string.index(before: end)
        }
        return String(string[string.startIndex..<end])
    }
}
