import SwiftUI

/// Görev: parçalı ince kullanım çubuğu (şu an yer tutucu).
struct UsageSegment: Identifiable {
    let id: String
    let fraction: Double   // 0...1
    let color: Color
}

struct UsageBar: View {
    let segments: [UsageSegment]
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                HStack(spacing: 2) {
                    ForEach(normalized) { segment in
                        Rectangle()
                            .fill(segment.color)
                            .frame(width: geo.size.width * segment.fraction)
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.4), value: segments.map(\.fraction))
    }

    /// Fraction'lar 0...1 aralığına sıkıştırılır; toplam 1'i geçerse orantılı küçültülür.
    /// fraction 0 olan segmentler çıkarılır.
    private var normalized: [UsageSegment] {
        let clamped = segments.map { segment in
            UsageSegment(
                id: segment.id,
                fraction: max(0, min(1, segment.fraction)),
                color: segment.color
            )
        }
        let total = clamped.reduce(0) { $0 + $1.fraction }
        guard total > 1 else {
            return clamped.filter { $0.fraction > 0 }
        }
        return clamped.map {
            UsageSegment(
                id: $0.id,
                fraction: $0.fraction / total,
                color: $0.color
            )
        }.filter { $0.fraction > 0 }
    }
}
