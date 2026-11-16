import Foundation

/// Görev: bu dosyadaki fonksiyonları uygula (şu an yer tutucu).
public enum Fmt {
    /// Bayt → "512 B", "1,5 KB", "12,3 MB", "1,2 GB", "2,0 TB" (1024 tabanı, tek ondalık, virgül)
    public static func bytes(_ value: UInt64) -> String { "" }
    /// Bayt/saniye → "0 B/s", "1,5 KB/s", "12,3 MB/s"
    public static func speed(_ bytesPerSecond: Double) -> String { "" }
    /// 0...100 → "%42" (tam sayıya yuvarla); nil → "—"
    public static func percent(_ value: Double?) -> String { "" }
    /// Saniye → "3 gün 4 sa", "4 sa 12 dk", "12 dk"
    public static func uptime(_ seconds: TimeInterval) -> String { "" }
}
