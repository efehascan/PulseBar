import SwiftUI
import PulseBarCore
/// Görev: bir kategorinin ayrıntı görünümü (şu an yer tutucu).
struct DetailView: View {
    let store: SystemStore
    let category: MetricCategory
    let onBack: () -> Void
    var body: some View { Button("Geri", action: onBack) }
}
