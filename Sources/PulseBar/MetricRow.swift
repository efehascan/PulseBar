import SwiftUI

/// Görev: renkli kare + ad + değer + yüzde satırı (sade, küçük, tıklanabilir görünüm).
struct MetricRow: View {
    let color: Color
    let title: String
    let value: String
    let percent: String
    var detail: String? = nil

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 7, height: 7)

            Text(title)
                .font(.system(size: 11.5))

            Spacer(minLength: 6)

            Text(value)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .monospacedDigit()

            Text(percent)
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
                .frame(minWidth: 52, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.tertiary)
                .opacity(hovering ? 1 : 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(hovering ? Color.primary.opacity(0.06) : .clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
        .help(detail ?? "")
    }
}
