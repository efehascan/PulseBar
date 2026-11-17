import SwiftUI
/// Görev: küçük geçmiş grafiği (şu an yer tutucu).
struct Sparkline: View {
    let values: [Double]      // en eski başta
    var maxValue: Double? = nil   // nil: değerlerin en büyüğü (en az 1)
    let color: Color
    var body: some View {
        GeometryReader { geo in
            content(for: geo.size)
        }
    }

    @ViewBuilder
    private func content(for size: CGSize) -> some View {
        let w = size.width
        let h = size.height
        if values.count < 2 {
            Rectangle()
                .fill(Theme.track)
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .bottom)
        } else {
            let peak = max(maxValue ?? (values.max() ?? 1), 1)
            let step = w / CGFloat(values.count - 1)
            let pts: [CGPoint] = values.enumerated().map { i, v in
                let x = CGFloat(i) * step
                let y = h - CGFloat(v / peak) * h
                return CGPoint(x: x, y: min(max(y, 0), h))
            }
            let linePath = Path { p in
                for (i, c) in pts.enumerated() {
                    if i == 0 { p.move(to: c) } else { p.addLine(to: c) }
                }
            }
            let fillPath = Path { p in
                for (i, c) in pts.enumerated() {
                    if i == 0 { p.move(to: c) } else { p.addLine(to: c) }
                }
                p.addLine(to: CGPoint(x: w, y: h))
                p.addLine(to: CGPoint(x: 0, y: h))
                p.closeSubpath()
            }
            let last = pts[pts.count - 1]
            ZStack(alignment: .topLeading) {
                fillPath
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.28), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                linePath
                    .stroke(color, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))

                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .position(x: last.x, y: last.y)
            }
        }
    }
}
