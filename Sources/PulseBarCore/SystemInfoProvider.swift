import Foundation

/// Görev: model, çip, macOS sürümü, açık kalma süresi, ısı durumu ve pil bilgisini oku (şu an yer tutucu).
public final class SystemInfoProvider {
    public init() {}
    public func sample() -> SystemInfo { SystemInfo() }
}
