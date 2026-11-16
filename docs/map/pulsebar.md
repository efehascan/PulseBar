# Harita: PulseBar
son doğrulama: (ilk commit)

## Dosyalar
- `Sources/PulseBarCore/Models.swift`: `CPUSample`, `MemorySample`, `GPUSample`, `DiskSample`, `NetworkSample`, `SystemInfo`, `ThermalLevel`. Değiştirilmez.
- Monitörler (her biri `public final class X { public init(); public func sample() -> XSample }`, durum tutabilir):
  `CPUMonitor`, `MemoryMonitor`, `GPUMonitor`, `DiskMonitor`, `NetworkMonitor`, `SystemInfoProvider`.
- `Formatting.swift`: `Fmt.bytes`, `Fmt.speed`, `Fmt.percent`, `Fmt.uptime` (Türkçe biçim, virgüllü ondalık).
- `SystemStore.swift`: `@MainActor @Observable`; monitörleri tutar, `refresh()` hepsini örnekler, geçmiş dizileri en çok 60.
- Arayüz: `PulseBarApp` (MenuBarExtra, .window), `MenuBarLabel` (menü çubuğu metni), `PanelView` (cam panel), `MetricRow` (renkli kare satırı), `UsageBar` (parçalı çubuk), `Theme` (renkler, panel genişliği 340).

## Kurallar
- Hız hesapları: önceki sayaç ile şimdiki sayacın farkı / geçen süre (`Date()` ya da `mach_absolute_time`). İlk çağrıda önceki yoksa hız 0.
- Sayaç sıfırlanır ya da küçülürse (arayüz değişti) farkı 0 say, negatif hız üretme.
- Bütün yüzdeler 0...100 aralığına sıkıştırılır.
- Panel sadece okur; ölçüm kodu arayüzde yok.

## macOS API notları
- CPU: `host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, &info, &infoCount)`; çekirdek başına `cpu_ticks` (USER, SYSTEM, IDLE, NICE). Yük ortalaması: `getloadavg`.
- Bellek: `host_statistics64(..., HOST_VM_INFO64, ...)` → `vm_statistics64`; sayfa boyutu `vm_kernel_page_size`. app ≈ (internal_page_count − purgeable_count) × sayfa, wired = wire_count × sayfa, compressed = compressor_page_count × sayfa. Swap: `sysctlbyname("vm.swapusage")` → `xsw_usage`.
- GPU: `IOServiceMatching("IOAccelerator")` → her serviste `IORegistryEntryCreateCFProperty(..., "PerformanceStatistics")` sözlüğü: "Device Utilization %", "In use system memory". Ad: "model" özelliği ya da "GPU".
- Disk kapasitesi: `URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])`. Hız: `IOServiceMatching("IOBlockStorageDriver")` → "Statistics" sözlüğü: "Bytes (Read)", "Bytes (Write)".
- Ağ: `getifaddrs`; `AF_LINK` girişlerinde `ifa_data` → `if_data` (`ifi_ibytes`, `ifi_obytes`). Sadece `en*` arayüzleri toplanır; ana arayüz en çok bayt alan `en*`.
- Sistem: `sysctlbyname("hw.model")`, `sysctlbyname("machdep.cpu.brand_string")`, `ProcessInfo.processInfo.operatingSystemVersion`, `ProcessInfo.processInfo.systemUptime`, `ProcessInfo.processInfo.thermalState`. Pil: IOKit `IOPSCopyPowerSourcesInfo` / `IOPSCopyPowerSourcesList` / `IOPSGetPowerSourceDescription` (`kIOPSCurrentCapacityKey`, `kIOPSIsChargingKey`); pil yoksa nil.

## Arayüz
- Cam: `.glassEffect(.regular, in: .rect(cornerRadius: 16))` (macOS 26). Panel arka planı cam, satırlar sade.
- Görsel dil: başlık + büyük yüzde + sağda "kullanılan / toplam", altında parçalı çubuk, altında satırlar: renkli kare · ad · değer · yüzde (sağa yaslı, `monospacedDigit`).
