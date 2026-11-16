import SwiftUI

/// Panelin renkleri: her ölçümün sabit bir rengi var (çubukta ve satırdaki karede aynı renk).
enum Theme {
    static let cpu = Color(red: 0.33, green: 0.56, blue: 0.96)      // mavi
    static let memory = Color(red: 0.89, green: 0.45, blue: 0.24)   // turuncu
    static let gpu = Color(red: 0.27, green: 0.68, blue: 0.56)      // yeşil
    static let disk = Color(red: 0.86, green: 0.67, blue: 0.20)     // sarı
    static let network = Color(red: 0.62, green: 0.48, blue: 0.86)  // mor
    static let muted = Color.secondary
    static let track = Color.primary.opacity(0.10)
    static let panelWidth: CGFloat = 400
}
