import SwiftUI
import PulseBarCore
/// Bir kategorinin ayrıntısı: ne kullanıyor, nasıl değişiyor.
struct DetailView: View {
    let store: SystemStore
    let category: MetricCategory
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            backButton
            titleRow
            chart
            stats
            listSection
        }
    }

    // MARK: - Geri

    private var backButton: some View {
        Button(action: onBack) {
            Label("Sistem", systemImage: "chevron.left")
                .font(.system(size: 11))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    // MARK: - Başlık + ana değer

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(mainValue)
                .font(.system(size: 20, weight: .light))
                .monospacedDigit()
        }
    }

    private var title: String {
        switch category {
        case .cpu: return "CPU"
        case .memory: return "Bellek"
        case .gpu: return "GPU"
        case .disk: return "Disk"
        case .network: return "Ağ"
        }
    }

    private var mainValue: String {
        switch category {
        case .cpu: return Fmt.percent(store.cpu.usage)
        case .memory: return Fmt.percent(store.memory.pressure)
        case .gpu: return Fmt.percent(store.gpu.utilization)
        case .disk: return Fmt.percent(store.disk.usedPercent)
        case .network: return "↓ " + Fmt.speed(store.network.downPerSecond)
        }
    }

    // MARK: - Grafik

    @ViewBuilder
    private var chart: some View {
        switch category {
        case .cpu:
            Sparkline(values: store.cpuHistory, maxValue: 100, color: Theme.cpu)
                .frame(height: 36)
        case .memory:
            Sparkline(values: store.memoryHistory, maxValue: 100, color: Theme.memory)
                .frame(height: 36)
        case .gpu:
            Sparkline(values: store.gpuHistory, maxValue: 100, color: Theme.gpu)
                .frame(height: 36)
        case .network:
            Sparkline(values: store.downHistory, maxValue: nil, color: Theme.network)
                .frame(height: 36)
        case .disk:
            EmptyView()
        }
    }

    // MARK: - İstatistikler

    private var stats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(statItems, id: \.label) { item in
                StatCell(label: item.label, value: item.value)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var statItems: [StatItem] {
        switch category {
        case .cpu:
            let load = store.cpu.loadAverage
                .map { String(format: "%.1f", $0) }
                .joined(separator: " · ")
            return [
                StatItem(label: "Kullanıcı", value: Fmt.percent(store.cpu.user)),
                StatItem(label: "Sistem", value: Fmt.percent(store.cpu.system)),
                StatItem(label: "Çekirdek", value: "\(store.cpu.cores.count)"),
                StatItem(label: "Yük (1/5/15 dk)", value: load),
            ]
        case .memory:
            return [
                StatItem(label: "Kullanılan", value: Fmt.bytes(store.memory.used)),
                StatItem(label: "Toplam", value: Fmt.bytes(store.memory.total)),
                StatItem(label: "Sıkıştırılmış", value: Fmt.bytes(store.memory.compressed)),
                StatItem(label: "Swap", value: Fmt.bytes(store.memory.swapUsed)),
            ]
        case .gpu:
            return [
                StatItem(label: "Ad", value: store.gpu.name),
                StatItem(label: "Bellek", value: store.gpu.memoryUsed.map(Fmt.bytes) ?? "—"),
            ]
        case .disk:
            return [
                StatItem(label: "Okuma", value: Fmt.speed(store.disk.readPerSecond)),
                StatItem(label: "Yazma", value: Fmt.speed(store.disk.writePerSecond)),
                StatItem(label: "Boş", value: Fmt.bytes(store.disk.free)),
                StatItem(label: "Toplam", value: Fmt.bytes(store.disk.total)),
            ]
        case .network:
            return [
                StatItem(label: "İndirme", value: Fmt.speed(store.network.downPerSecond)),
                StatItem(label: "Yükleme", value: Fmt.speed(store.network.upPerSecond)),
                StatItem(label: "Toplam ↓", value: Fmt.bytes(store.network.totalDown)),
                StatItem(label: "Arayüz", value: store.network.interface),
            ]
        }
    }

    // MARK: - Liste (süreçler / birimler)

    @ViewBuilder
    private var listSection: some View {
        switch category {
        case .disk:
            Text("BİRİMLER")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.6)
            if store.volumes.isEmpty {
                Text("Ölçülüyor…")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(store.volumes) { volume in
                    volumeRow(volume)
                }
            }
        case .gpu:
            Text("macOS süreç başına GPU kullanımını vermiyor")
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
        default:
            Text("EN ÇOK KULLANANLAR")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.6)
            if store.topProcesses.isEmpty {
                Text("Ölçülüyor…")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(store.topProcesses) { process in
                    processRow(process)
                }
            }
        }
    }

    // MARK: - Süreç satırı

    private func processRow(_ process: ProcessUsage) -> some View {
        let (label, fraction) = processMetric(for: process)
        return VStack(spacing: 3) {
            HStack {
                Text(process.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
                Spacer()
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressBar(fraction: fraction, color: themeColor)
        }
    }

    /// Bu sürecin görünen değeri ve listedeki en büyük değere oranı (tek süreçse 1).
    private func processMetric(for process: ProcessUsage) -> (String, Double) {
        switch category {
        case .cpu:
            let maxCpu = store.topProcesses.map { $0.cpu }.max() ?? 0
            return (Fmt.percent(process.cpu), maxCpu == 0 ? 0 : process.cpu / maxCpu)
        case .memory:
            let maxMem = store.topProcesses.map { $0.memory }.max() ?? 0
            return (Fmt.bytes(process.memory), maxMem == 0 ? 0 : Double(process.memory) / Double(maxMem))
        case .network:
            let maxNet = store.topProcesses.map { $0.downPerSecond + $0.upPerSecond }.max() ?? 0
            let own = process.downPerSecond + process.upPerSecond
            let label = "↓ \(Fmt.speed(process.downPerSecond)) ↑ \(Fmt.speed(process.upPerSecond))"
            return (label, maxNet == 0 ? 0 : own / maxNet)
        default:
            return ("", 0)
        }
    }

    // MARK: - Birim satırı

    private func volumeRow(_ volume: VolumeUsage) -> some View {
        let used = volume.total > volume.free ? volume.total - volume.free : 0
        let fraction = volume.total == 0 ? 0 : Double(used) / Double(volume.total)
        return VStack(spacing: 3) {
            HStack {
                Text(volume.name)
                    .font(.system(size: 11))
                    .lineLimit(1)
                Spacer()
                Text("\(Fmt.bytes(volume.free)) boş / \(Fmt.bytes(volume.total))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressBar(fraction: fraction, color: Theme.disk)
        }
    }

    // MARK: - Yardımcılar

    private var themeColor: Color {
        switch category {
        case .cpu: return Theme.cpu
        case .memory: return Theme.memory
        case .gpu: return Theme.gpu
        case .disk: return Theme.disk
        case .network: return Theme.network
        }
    }
}

// MARK: - Hücresel parçalar

/// Bir istatistik hücresinin içeriği.
private struct StatItem: Identifiable {
    let label: String
    let value: String
    var id: String { label }
}

/// İstatistik hücresi: küçük etiket üstte, değeri altta.
private struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9.5))
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.system(size: 11.5))
                .monospacedDigit()
        }
    }
}

/// İnce yatay ilerleme çubuğu: Track altında renkli Capsule, genişlik = oran.
private struct ProgressBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.track)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: 2)
    }
}
