import SwiftUI
import PulseBarCore

@main
struct PulseBarApp: App {
    @State private var store = SystemStore()

    init() {
        // Dock'ta görünmesin; sadece menü çubuğunda yaşar (paketlenmiş uygulamada LSUIElement de var)
        NSApplication.shared.setActivationPolicy(.accessory)
        Task { @MainActor in Snapshot.runIfRequested() }
    }

    var body: some Scene {
        MenuBarExtra {
            PanelView(store: store)
        } label: {
            MenuBarLabel(store: store)
                .task { store.start() }
        }
        .menuBarExtraStyle(.window)
    }
}
