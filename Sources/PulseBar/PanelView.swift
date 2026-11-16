import SwiftUI
import PulseBarCore

/// Görev: cam tasarımlı açılır panel (şu an yer tutucu).
struct PanelView: View {
    let store: SystemStore
    var body: some View { Text("PulseBar").padding().frame(width: Theme.panelWidth) }
}
