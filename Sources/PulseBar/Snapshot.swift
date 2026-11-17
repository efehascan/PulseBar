import SwiftUI
import AppKit
import PulseBarCore

/// `PulseBar --snapshot <yol.png> [--dark]`: paneli ekrana açmadan PNG olarak çizer ve çıkar.
/// Ajanların ve CI'ın arayüzü görsel kontrol etmesi için (ekran kaydı izni gerektirmez).
enum Snapshot {
    @MainActor static func runIfRequested() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count else { return }
        let url = URL(fileURLWithPath: args[i + 1])
        let appearance = NSAppearance(named: args.contains("--dark") ? .darkAqua : .aqua)
        let store = SystemStore()
        store.refresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            store.refresh()
            var detail: MetricCategory? = nil
            if let d = args.firstIndex(of: "--detail"), d + 1 < args.count { detail = MetricCategory(rawValue: args[d + 1]) }
            if let detail { store.focus = detail; store.refresh(); Thread.sleep(forTimeInterval: 1.0); store.refresh() }
            let view = Group {
                if let detail {
                    DetailView(store: store, category: detail, onBack: {})
                        .padding(12).frame(width: Theme.panelWidth).glassEffect(.regular, in: .rect(cornerRadius: 14))
                } else { PanelView(store: store) }
            }
                .padding(24)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, args.contains("--dark") ? .dark : .light)
            let host = NSHostingView(rootView: view)
            host.appearance = appearance
            host.frame = NSRect(origin: .zero, size: host.fittingSize)
            let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = appearance
            window.contentView = host
            host.layoutSubtreeIfNeeded()
            var ok = false
            if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                host.cacheDisplay(in: host.bounds, to: rep)
                if let data = rep.representation(using: .png, properties: [:]) {
                    ok = (try? data.write(to: url)) != nil
                }
            }
            print(ok ? "snapshot: \(url.path)" : "snapshot: yazılamadı")
            exit(ok ? 0 : 1)
        }
    }
}
