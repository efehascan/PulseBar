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
    var body: some View { Capsule().fill(Theme.track).frame(height: height) }
}
