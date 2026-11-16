# PulseBar

Menü çubuğunda yaşayan, CPU, bellek, GPU, disk ve ağ kullanımını cam (Liquid Glass) tasarımlı bir panelde gösteren macOS uygulaması. Swift 6.4 araç zinciri, Swift 5 dil modu, SwiftUI, macOS 26+. Dış bağımlılık yok.

## Komutlar
- Kontrol: `scripts/check.sh` (derleme + bütün testler), tek test grubu: `scripts/check.sh MonitorTests/testCPU`
- Çalıştır: `swift run PulseBar` · Uygulama paketi: `scripts/make-app.sh` → `dist/PulseBar.app`
- Komut çalıştıramıyorsan kontrolü kullanıcıya bırak; "geçti" deme.

## Klasörler
- `Sources/PulseBarCore/`: ölçüm (monitörler), biçimlendirme, `SystemStore`. Arayüz kodu yok.
- `Sources/PulseBar/`: SwiftUI arayüzü (menü çubuğu etiketi, panel, satırlar).
- `Tests/PulseBarCoreTests/`: biçimlendirme testleri ve gerçek makinede çalışan monitör testleri.
- Harita: `docs/map/pulsebar.md`. Bir dosyaya dokunmadan önce oku.

## Kurallar
- Sadece görevin izin verdiği dosyaya dokun. Görev tek dosyaysa tek dosyaya.
- `Models.swift`'teki tipleri ve dosyalardaki public imzaları değiştirme; gövdeleri doldur.
- Dış paket ekleme. Sadece Foundation, Darwin, IOKit, SwiftUI, AppKit.
- Uyarı ya da hata susturma yok (`@preconcurrency`, `nonisolated(unsafe)`, `try!` ile geçiştirme, zorla unwrap ile kestirme).
- C API'lerinde bellek: `host_processor_info` dizisini `vm_deallocate` ile bırak, `getifaddrs` sonucunu `freeifaddrs` ile, IOKit nesnelerini `IOObjectRelease` ile.
- Testleri değiştirme.

## Teslim
- Bitince 1–3 cümle: ne yaptın, hangi dosya. Yapmadığın bir şeyi yaptım deme.

## Ajanlar için (Vardiya)
Bu proje Vardiya Mimarisi ile geliştiriliyor: Claude iskeleti ve arayüzleri yazar, Qwen tek dosyalık görevleri doldurur, kontroller (`scripts/check.sh`) ve Gemma incelemesi doğrular.
