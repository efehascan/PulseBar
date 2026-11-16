import SwiftUI
import PulseBarCore

/// Cam tasarımlı açılır panel.
struct PanelView: View {
    let store: SystemStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            UsageBar(segments: segments)
            rows
            Divider()
            footer
        }
        .padding(16)
        .frame(width: Theme.panelWidth)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Üst blok

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sistem")
                .font(.system(size: 15, weight: .semibold))
            HStack {
                Text("CPU \(Fmt.percent(store.cpu.usage))")
                    .font(.system(size: 22, weight: .medium))
                    .monospacedDigit()
                Spacer()
                Text(Fmt.bytes(store.memory.used) + " / " + Fmt.bytes(store.memory.total))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Parçalı çubuk

    /// Her ölçüm dörtte bir pay alır.
    private var segments: [UsageSegment] {
        [
            UsageSegment(id: "cpu", fraction: store.cpu.usage / 100 / 4, color: Theme.cpu),
            UsageSegment(id: "memory", fraction: store.memory.pressure / 100 / 4, color: Theme.memory),
            UsageSegment(id: "gpu", fraction: (store.gpu.utilization ?? 0) / 100 / 4, color: Theme.gpu),
            UsageSegment(id: "disk", fraction: store.disk.usedPercent / 100 / 4, color: Theme.disk),
        ]
    }

    // MARK: - Satırlar

    private var rows: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetricRow(
                color: Theme.cpu,
                title: "CPU",
                value: "\(store.cpu.cores.count) çekirdek",
                percent: Fmt.percent(store.cpu.usage),
                detail: "kullanıcı \(Fmt.percent(store.cpu.user)) · sistem \(Fmt.percent(store.cpu.system))"
            )
            MetricRow(
                color: Theme.memory,
                title: "Bellek",
                value: Fmt.bytes(store.memory.used),
                percent: Fmt.percent(store.memory.pressure),
                detail: "sıkıştırılmış \(Fmt.bytes(store.memory.compressed)) · swap \(Fmt.bytes(store.memory.swapUsed))"
            )
            MetricRow(
                color: Theme.gpu,
                title: "GPU",
                value: store.gpu.name,
                percent: Fmt.percent(store.gpu.utilization),
                detail: store.gpu.memoryUsed.map { "bellek \(Fmt.bytes($0))" }
            )
            MetricRow(
                color: Theme.disk,
                title: "Disk",
                value: "\(Fmt.bytes(store.disk.free)) boş",
                percent: Fmt.percent(store.disk.usedPercent),
                detail: "okuma \(Fmt.speed(store.disk.readPerSecond)) · yazma \(Fmt.speed(store.disk.writePerSecond))"
            )
            MetricRow(
                color: Theme.network,
                title: "Ağ",
                value: "↓ \(Fmt.speed(store.network.downPerSecond))  ↑ \(Fmt.speed(store.network.upPerSecond))",
                percent: store.network.interface,
                detail: "toplam ↓ \(Fmt.bytes(store.network.totalDown)) · ↑ \(Fmt.bytes(store.network.totalUp))"
            )
        }
    }

    // MARK: - Alt bilgi

    private var footer: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(store.info.chip) · \(store.info.osVersion)")
            Text(infoLine2 + batteryLine)
            HStack {
                Spacer()
                Button("Çık") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
    }

    private var infoLine2: String {
        "Açık \(Fmt.uptime(store.info.uptime)) · Isı \(thermalText)"
    }

    /// Pil yoksa boş; varsa " · Pil %N" (şarjdaysa " ⚡︎").
    private var batteryLine: String {
        guard let percent = store.info.batteryPercent else { return "" }
        let suffix = store.info.isCharging == true ? " ⚡︎" : ""
        return " · Pil %\(percent)\(suffix)"
    }

    private var thermalText: String {
        switch store.info.thermal {
        case .nominal:  return "normal"
        case .fair:     return "ılık"
        case .serious:  return "sıcak"
        case .critical: return "kritik"
        }
    }
}
