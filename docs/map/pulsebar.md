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

## Detay görünümü (v2)
- `Models.swift`: `MetricCategory` (cpu, memory, gpu, disk, network), `ProcessUsage`, `VolumeUsage`.
- `ProcessMonitor.swift`: `topByCPU/topByMemory/topByNetwork(limit:)`, `volumes()`, `static parsePS`, `static parseNettop`.
  - Süreçler: `/bin/ps -axo pid=,pcpu=,rss=,comm=` (rss KB; pcpu Türkçe yerelde virgüllü olabilir: "," → "."); ad = komutun son yol parçası (boşluk içerebilir).
  - Ağ: `/usr/bin/nettop -P -L 1 -x -J bytes_in,bytes_out` → satırlar "ad.pid,gelen,giden," (ilk satır başlık); hız = önceki çağrıya göre fark / süre.
  - Birimler: `FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys:options: [.skipHiddenVolumes])`, yerel olanlar; "/" önce.
- `SystemStore`: `focus` nil değilse `refresh()` odak kategorisinin süreçlerini (`topProcesses`, en çok 6) ya da birimleri (`volumes`) de günceller. `memoryHistory`, `gpuHistory` (60).
- Arayüz: `PanelView` satıra tıklayınca `DetailView(category:)` gösterir (panelin içinde, geri düğmesiyle); `Sparkline` geçmiş grafiği.

## Görsel dil (v2: sade ve küçük)
- Panel 300 pt, dolgu 12, köşe 14, cam. Yazılar küçük: başlık 11 semibold `.secondary`, satır 11.5, değer 11 `.secondary`, yüzde 11 medium; hepsi `monospacedDigit`.
- Satır yüksekliği ~24, renkli kare 7×7 köşe 2, satırlar arası ince ayırıcı yok; üstüne gelince hafif arka plan (`Color.primary.opacity(0.06)`, köşe 6) ve sağda küçük `chevron.right`.
- Detay: üstte "‹ Sistem" geri düğmesi (11), kategori adı 13 semibold + büyük değer 20 light, `Sparkline` (yükseklik 36), sonra 2 sütunlu küçük istatistikler, sonra süreç listesi (ad · değer · ince oransal çubuk).
