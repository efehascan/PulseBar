import SwiftUI
import PulseBarCore

/// Görev: menü çubuğundaki kısa etiket (şu an yer tutucu).
struct MenuBarLabel: View {
    let store: SystemStore
    var body: some View { Image(systemName: "gauge.with.dots.needle.33percent") }
}
