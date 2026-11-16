import Foundation
import Darwin
import IOKit.ps

/// Görev: model, çip, macOS sürümü, açık kalma süresi, ısı durumu ve pil bilgisini oku.
public final class SystemInfoProvider {
    public init() {}

    public func sample() -> SystemInfo {
        let model = sysctlString("hw.model")
        let chip = sysctlString("machdep.cpu.brand_string")
        let osVersion = Self.osVersionString(ProcessInfo.processInfo.operatingSystemVersion)
        let uptime = ProcessInfo.processInfo.systemUptime
        let thermal = Self.mapThermal(ProcessInfo.processInfo.thermalState)
        let battery = readBattery()

        return SystemInfo(
            model: model,
            chip: chip,
            osVersion: osVersion,
            uptime: uptime,
            thermal: thermal,
            batteryPercent: battery?.percent,
            isCharging: battery?.isCharging
        )
    }

    /// sysctlbyname ile önce boyut, sonra tampon doldurup okur; başarısızsa boş string.
    private func sysctlString(_ name: String) -> String {
        var size = 0
        // İlk çağrı boyutu döndürür; ikinci çağrı tamponu doldurur.
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "" }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return "" }
        return String(cString: buffer)
    }

    /// Sürüm numarasını biçimlendirir; patch 0 ise atlanır ("macOS 27.2", "macOS 27.2.1").
    private static func osVersionString(_ v: OperatingSystemVersion) -> String {
        if v.patchVersion == 0 {
            return "macOS \(v.majorVersion).\(v.minorVersion)"
        }
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    /// Isı durumunu kendi enum'una çevirir; bilinmeyen değer .nominal sayılır.
    private static func mapThermal(_ state: ProcessInfo.ThermalState) -> ThermalLevel {
        switch state {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }

    /// Pil yüzdesi ve şarj durumu; pil yoksa nil.
    private func readBattery() -> (percent: Int, isCharging: Bool)? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] ?? []
        for ps in sources {
            guard let desc = IOPSGetPowerSourceDescription(info, ps) as? [String: Any] else { continue }
            // Kapasite ve şarj bilgisini bir arada tutalım; biri eksikse kaynak atlanır.
            guard
                let percent = (desc[kIOPSCurrentCapacityKey as String] as? NSNumber)?.intValue,
                let isCharging = (desc[kIOPSIsChargingKey as String] as? NSNumber)?.boolValue
            else { continue }
            return (percent, isCharging)
        }
        return nil
    }
}
