import SwiftUI

/// Görev: renkli kare + ad + değer + yüzde satırı (şu an yer tutucu).
struct MetricRow: View {
    let color: Color
    let title: String
    let value: String
    let percent: String
    var detail: String? = nil
    var body: some View { Text(title) }
}
