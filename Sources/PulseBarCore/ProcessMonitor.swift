import Foundation

/// Görev: süreç bazında CPU, bellek ve ağ kullanımı; bağlı birimler.
public final class ProcessMonitor {
    /// Önceki ağ sayaçları; ilk çağrıda boş.
    private var previousCounters: [Int32: (in: UInt64, out: UInt64)] = [:]
    private var previousTime: Date?

    public init() {}

    /// CPU'ya göre azalan, en çok `limit`
    public func topByCPU(limit: Int) -> [ProcessUsage] {
        guard limit > 0 else { return [] }
        let all = ProcessMonitor.parsePS(run("/bin/ps", ["-axo", "pid=,pcpu=,rss=,comm="]))
        return all.sorted { $0.cpu > $1.cpu }.prefix(limit).map { $0 }
    }

    /// Belleğe göre azalan, en çok `limit`
    public func topByMemory(limit: Int) -> [ProcessUsage] {
        guard limit > 0 else { return [] }
        let all = ProcessMonitor.parsePS(run("/bin/ps", ["-axo", "pid=,pcpu=,rss=,comm="]))
        return all.sorted { $0.memory > $1.memory }.prefix(limit).map { $0 }
    }

    /// Ağ hızına (indirme + yükleme) göre azalan; ilk çağrıda önceki sayaç yoksa hızlar 0, en çok `limit`
    public func topByNetwork(limit: Int) -> [ProcessUsage] {
        guard limit > 0 else { return [] }
        let now = Date()
        let current = ProcessMonitor.parseNettop(
            run("/usr/bin/nettop", ["-P", "-L", "1", "-x", "-J", "bytes_in,bytes_out"]))
        let elapsed: Double
        if let t = previousTime { elapsed = max(now.timeIntervalSince(t), 1e-9) } else { elapsed = 0 }
        let previous = previousCounters

        var result: [ProcessUsage] = []
        for (pid, c) in current {
            let pIn = previous[pid]?.in ?? c.bytesIn
            let pOut = previous[pid]?.out ?? c.bytesOut
            let dIn = c.bytesIn > pIn ? c.bytesIn - pIn : 0
            let dOut = c.bytesOut > pOut ? c.bytesOut - pOut : 0
            let down = elapsed == 0 ? 0 : Double(dIn) / elapsed
            let up = elapsed == 0 ? 0 : Double(dOut) / elapsed
            if down + up == 0 { continue }
            result.append(ProcessUsage(id: pid, name: c.name, downPerSecond: down, upPerSecond: up))
        }
        previousCounters = current.mapValues { (in: $0.bytesIn, out: $0.bytesOut) }
        previousTime = now
        return result.sorted { $0.downPerSecond + $0.upPerSecond > $1.downPerSecond + $1.upPerSecond }
            .prefix(limit).map { $0 }
    }

    /// Bağlı yerel birimler (kök birim önce)
    public func volumes() -> [VolumeUsage] {
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeTotalCapacityKey,
                                     .volumeAvailableCapacityForImportantUsageKey, .volumeIsLocalKey]
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else { return [] }

        var others: [VolumeUsage] = []
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { continue }
            guard values.volumeIsLocal ?? false else { continue }
            let total = values.volumeTotalCapacity ?? 0
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            let name = values.volumeName ?? url.lastPathComponent
            let v = VolumeUsage(id: url.path, name: name,
                                total: UInt64(bitPattern: Int64(total)),
                                free: UInt64(bitPattern: Int64(free)))
            if url.path == "/" {
                others = [v] + others
            } else {
                others.append(v)
            }
        }
        return others
    }

    /// Bir komutu çalıştırıp stdout'u metin olarak döndürür; çalışmazsa "".
    private func run(_ path: String, _ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// `ps -axo pid=,pcpu=,rss=,comm=` çıktısı → süreçler (rss KB'den bayta)
    public static func parsePS(_ output: String) -> [ProcessUsage] {
        var result: [ProcessUsage] = []
        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            let parts = trimmed.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
            guard parts.count == 4 else { continue }
            guard let pid = Int32(parts[0]) else { continue }
            let cpuText = parts[1].replacingOccurrences(of: ",", with: ".")
            guard let cpu = Double(cpuText) else { continue }
            guard let rss = UInt64(parts[2]) else { continue }
            let command = String(parts[3])
            let name = (command as NSString).lastPathComponent
            result.append(ProcessUsage(id: pid, name: name, cpu: cpu, memory: rss * 1024))
        }
        return result
    }

    /// `nettop -P -L 1 -x -J bytes_in,bytes_out` çıktısı → [pid: (ad, gelen, giden)] toplam baytlar
    public static func parseNettop(_ output: String) -> [Int32: (name: String, bytesIn: UInt64, bytesOut: UInt64)] {
        var result: [Int32: (name: String, bytesIn: UInt64, bytesOut: UInt64)] = [:]
        for line in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let fields = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 3, !fields[0].isEmpty else { continue }
            // İlk alanda SON "." karakterinden böl: solu ad, sağı pid.
            guard let dot = fields[0].lastIndex(of: ".") else { continue }
            let name = String(fields[0][fields[0].startIndex..<dot])
            guard let pid = Int32(fields[0][fields[0].index(after: dot)...]) else { continue }
            guard let bytesIn = UInt64(fields[1]) else { continue }
            guard let bytesOut = UInt64(fields[2]) else { continue }
            result[pid] = (name, bytesIn, bytesOut)
        }
        return result
    }
}
