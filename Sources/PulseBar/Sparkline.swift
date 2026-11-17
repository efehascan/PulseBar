import SwiftUI
/// Görev: küçük geçmiş grafiği (şu an yer tutucu).
struct Sparkline: View {
    let values: [Double]      // en eski başta
    var maxValue: Double? = nil   // nil: değerlerin en büyüğü (en az 1)
    let color: Color
    var body: some View { Rectangle().fill(Theme.track) }
}
