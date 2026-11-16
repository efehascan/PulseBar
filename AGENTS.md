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

## Test
Hızlı, deterministik, güvenilir. Tam politika: Vardiya `kurallar/test-politikasi.md`.
- Önce sadece değişikliğin etkilediği testleri çalıştır (`scripts/check.sh MonitorTests/testCPU` gibi); bütün paket sadece teslimden önce ya da arayüz / çok modüllü değişiklikte.
- Testte keyfi bekleme (`sleep`, sabit gecikme) yok: zamanı enjekte et ya da koşul bekle. İstisna: gerçek donanım sayacı ölçen testler.
- Test gerçek saate, rastgeleliğe, çalışma sırasına, paylaşılan duruma ya da ağa bağlı olmasın; geçici klasör ve sabit veri kullan.
- Kararsız (flaky) test hata sayılır: geçsin diye yeniden çalıştırma, sebebini bul ve yaz.
- Test başarısızsa: hata satırını oku, sebep üründe mi testte mi ortamda mı belirle, kök sebebi düzelt, sadece etkilenen testleri yeniden çalıştır.
- Hız için asla: assertion silme, beklentiyi gevşetme, testi atlama ya da kapatma, hatayı gizleme, gerçek entegrasyon testini mock'la değiştirme.
- Testleri değiştirmen gerekiyorsa (görev açıkça istemediyse) dur ve sor.

## Teslim
- Bitince 1–3 cümle: ne yaptın, hangi dosya. Yapmadığın bir şeyi yaptım deme.

## Ajanlar için (Vardiya)
Bu proje Vardiya Mimarisi ile geliştiriliyor: Claude iskeleti ve arayüzleri yazar, Qwen tek dosyalık görevleri doldurur, kontroller (`scripts/check.sh`) ve Gemma incelemesi doğrular.
