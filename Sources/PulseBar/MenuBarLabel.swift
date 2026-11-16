import SwiftUI
import PulseBarCore

/// Görev: menü çubuğundaki kısa etiket (şu an yer tutucu).
struct MenuBarLabel: View {
    let store: SystemStore
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "cpu")
            Text(Fmt.percent(store.cpu.usage))
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
                .fixedSize()
            Image(systemName: "arrow.down")
            Text(Fmt.speed(store.network.downPerSecond))
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
                .fixedSize()
        }
    }
}
