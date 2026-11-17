import SwiftUI
import PulseBarCore

/// Cam tasarımlı açılır panel.
struct PanelView: View {
    let store: SystemStore

    @State private var selected: MetricCategory? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let selected {
                DetailView(store: store, category: selected, onBack: goBack)
            } else {
                mainView
            }
        }
        .padding(12)
        .frame(width: Theme.panelWidth)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .onAppear {
            store.panelOpen = true
            store.refresh()                 // açılınca bellek/GPU/disk hemen güncel olsun
        }
        .onDisappear {
            store.panelOpen = false
            selected = nil
            store.focus = nil
        }
    }

    private func goBack() {
        withAnimation(.easeOut(duration: 0.18)) {
            selected = nil
            store.focus = nil
        }
    }

    // MARK: - Ana görünüm

    private var mainView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            UsageBar(segments: segments, height: 4)
            rows
            footer
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Sistem")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("CPU \(Fmt.percent(store.cpu.usage))  ·  Bellek \(Fmt.percent(store.memory.pressure))")
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundStyle(.secondary)
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
        VStack(spacing: 0) {
            metricRow(.cpu)
            metricRow(.memory)
            metricRow(.gpu)
            metricRow(.disk)
            metricRow(.network)
        }
    }

    @ViewBuilder
    private func metricRow(_ category: MetricCategory) -> some View {
        Group {
            switch category {
            case .cpu:
                MetricRow(
                    color: Theme.cpu,
                    title: "CPU",
                    value: "\(store.cpu.cores.count) çekirdek",
                    percent: Fmt.percent(store.cpu.usage),
                    detail: "kullanıcı \(Fmt.percent(store.cpu.user)) · sistem \(Fmt.percent(store.cpu.system))"
                )
            case .memory:
                MetricRow(
                    color: Theme.memory,
                    title: "Bellek",
                    value: Fmt.bytes(store.memory.used),
                    percent: Fmt.percent(store.memory.pressure),
                    detail: "sıkıştırılmış \(Fmt.bytes(store.memory.compressed)) · swap \(Fmt.bytes(store.memory.swapUsed))"
                )
            case .gpu:
                MetricRow(
                    color: Theme.gpu,
                    title: "GPU",
                    value: store.gpu.name,
                    percent: Fmt.percent(store.gpu.utilization),
                    detail: store.gpu.memoryUsed.map { "bellek \(Fmt.bytes($0))" }
                )
            case .disk:
                MetricRow(
                    color: Theme.disk,
                    title: "Disk",
                    value: "\(Fmt.bytes(store.disk.free)) boş",
                    percent: Fmt.percent(store.disk.usedPercent),
                    detail: "oku \(Fmt.speed(store.disk.readPerSecond)) · yaz \(Fmt.speed(store.disk.writePerSecond))"
                )
            case .network:
                MetricRow(
                    color: Theme.network,
                    title: "Ağ",
                    value: "↓ \(Fmt.speed(store.network.downPerSecond))",
                    percent: "↑ \(Fmt.speed(store.network.upPerSecond))",
                    detail: "\(store.network.interface) · toplam ↓ \(Fmt.bytes(store.network.totalDown)) ↑ \(Fmt.bytes(store.network.totalUp))"
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.18)) {
                selected = category
                store.focus = category
            }
            store.refresh()
        }
    }

    // MARK: - Alt bilgi

    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(store.info.chip) · açık \(Fmt.uptime(store.info.uptime))\(batteryText)")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            Spacer()
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
            .help("PulseBar'dan çık")
        }
    }

    /// Pil yoksa boş; varsa " · pil %N" (şarjdaysa "⚡︎" eki).
    private var batteryText: String {
        guard let percent = store.info.batteryPercent else { return "" }
        let suffix = store.info.isCharging == true ? "⚡︎" : ""
        return " · pil %\(percent)\(suffix)"
    }
}
