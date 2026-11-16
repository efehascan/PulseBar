#!/bin/sh
# Kırpılmış kontrol: derleme + testler; sadece hata satırları. Kullanım: scripts/check.sh [TestFiltresi]
cd "$(dirname "$0")/.." || exit 1
out=$(swift build 2>&1 | sed 's/\x1b\[[0-9;]*m//g'); code=$?
out_status=$(swift build >/dev/null 2>&1; echo $?)
if [ "$out_status" -ne 0 ]; then
  # Sadece "dosya:satır:sütun: error: mesaj" satırları (renk kodu ve kaynak işaretçisi yok)
  echo "build: BAŞARISIZ"; echo "$out" | grep -E "^/.*:[0-9]+:[0-9]+: error:" | sed 's|^.*/Sources/|Sources/|' | sort -u | head -20; exit 1
fi
warn=$(echo "$out" | grep -E "^/.*:[0-9]+:[0-9]+: warning:" | sed 's|^.*/Sources/|Sources/|' | sort -u)
if [ -n "$warn" ]; then
  # Uyarılar başarısızlık sayılmaz ama gösterilir: "always fails" gibi uyarılar gerçek hata olabilir
  echo "build: OK, $(echo "$warn" | wc -l | tr -d ' ') uyarı"; echo "$warn" | head -10
else
  echo "build: OK"
fi
if [ -n "$1" ]; then out=$(swift test --filter "$1" 2>&1); else out=$(swift test 2>&1); fi; code=$?
if [ $code -ne 0 ]; then
  # Sadece beklenen/gerçek değeri gösteren satırlar: model neyin yanlış olduğunu görsün
  echo "test: BAŞARISIZ"; echo "$out" | grep -E "error:" | sed -e 's|^.*/Tests/|Tests/|' -e 's|-\[PulseBarCoreTests\.||' -e 's|\] : | : |' | head -15; exit 1
fi
echo "test: OK"
