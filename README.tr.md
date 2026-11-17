# PulseBar

Menü çubuğunda CPU, bellek, GPU, disk ve ağ kullanımını cam tasarımlı bir panelde gösteren macOS uygulaması (macOS 26+).

```sh
swift run PulseBar          # geliştirme
scripts/make-app.sh         # dist/PulseBar.app
scripts/check.sh            # derleme + testler
.build/debug/PulseBar --snapshot panel.png [--dark]   # paneli PNG olarak çiz (görsel kontrol)
```

Vardiya Mimarisi ile geliştirildi: Claude iskeleti yazdı, Qwen 3.8 (local) dosyaları doldurdu, kontroller ve Gemma incelemesi doğruladı.
