import Foundation

/// Görev: bu dosyadaki fonksiyonları uygula (şu an yer tutucu).
public enum Fmt {
    /// Bayt → "512 B", "1,5 KB", "12,3 MB", "1,2 GB", "2,0 TB" (1024 tabanı, tek ondalık, virgül)
    public static func bytes(_ value: UInt64) -> String {
        let k: UInt64 = 1024
        let units = ["B", "KB", "MB", "GB", "TB"]
        var remaining = Double(value)
        var index = 0
        while remaining >= 1024, index < units.count - 1 {
            remaining /= Double(k)
            index += 1
        }
        if index == 0 {
            return "\(value) B"
        }
        let text = String(format: "%.1f", remaining).replacingOccurrences(of: ".", with: ",")
        return "\(text) \(units[index])"
    }

    /// Bayt/saniye → "0 B/s", "1,5 KB/s", "12,3 MB/s"
    public static func speed(_ bytesPerSecond: Double) -> String {
        let clamped = bytesPerSecond < 0 ? 0 : bytesPerSecond
        let rounded = UInt64(clamped.rounded())
        return bytes(rounded) + "/s"
    }

    /// 0...100 → "%42" (tam sayıya yuvarla); nil → "—"
    public static func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "%\(Int(value.rounded()))"
    }

    /// Saniye → "3 gün 4 sa", "4 sa 12 dk", "12 dk"
    public static func uptime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let days = total / 86_400
        let hours = (total % 86_400) / 3_600
        let minutes = (total % 3_600) / 60
        if days > 0 {
            return "\(days) gün \(hours) sa"
        }
        if hours > 0 {
            return "\(hours) sa \(minutes) dk"
        }
        return "\(minutes) dk"
    }
}
