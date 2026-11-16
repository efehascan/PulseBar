import SwiftUI

/// Görev: renkli kare + ad + değer + yüzde satırı (şu an yer tutucu).
struct MetricRow: View {
    let color: Color
    let title: String
    let value: String
    let percent: String
    var detail: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 11, height: 11)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                if let detail {
                    Text(detail)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Text(percent)
                .font(.system(size: 12.5, weight: .medium))
                .monospacedDigit()
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }
}
