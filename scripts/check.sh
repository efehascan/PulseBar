#!/bin/sh
# Kırpılmış kontrol: derleme + testler; sadece hata satırları. Kullanım: scripts/check.sh [TestFiltresi]
cd "$(dirname "$0")/.." || exit 1
out=$(swift build 2>&1); code=$?
if [ $code -ne 0 ]; then
  echo "build: BAŞARISIZ"; echo "$out" | grep -E "error:" | sed 's|^.*/Sources/|Sources/|' | sort -u | head -25; exit 1
fi
echo "build: OK"
if [ -n "$1" ]; then out=$(swift test --filter "$1" 2>&1); else out=$(swift test 2>&1); fi; code=$?
if [ $code -ne 0 ]; then
  # Sadece beklenen/gerçek değeri gösteren satırlar: model neyin yanlış olduğunu görsün
  echo "test: BAŞARISIZ"; echo "$out" | grep -E "error:" | sed -e 's|^.*/Tests/|Tests/|' -e 's|-\[PulseBarCoreTests\.||' -e 's|\] : | : |' | head -15; exit 1
fi
echo "test: OK"
