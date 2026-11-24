// Uygulama ikonunu çizer: macOS ızgarasında yuvarlatılmış kare, renk geçişi, beyaz SF Symbol.
// Kullanım: swift scripts/make-icon.swift <githarbor|pulsebar|islet> <çıktı.png>
import AppKit

let args = CommandLine.arguments
guard args.count == 3 else { print("kullanım: make-icon.swift <ad> <çıktı.png>"); exit(1) }
let name = args[1], out = args[2]

func rgb(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: 1)
}

struct Design { let top: UInt32; let bottom: UInt32; let symbol: String; let scale: CGFloat }
let designs: [String: Design] = [
    "githarbor": Design(top: 0x3D8BFF, bottom: 0x0B2A6B, symbol: "sailboat.fill", scale: 0.56),
    "pulsebar": Design(top: 0x2EE6A6, bottom: 0x0A5C5A, symbol: "waveform.path.ecg", scale: 0.60),
    "islet": Design(top: 0x8E6BFF, bottom: 0x2A1460, symbol: "", scale: 0),
]
guard let d = designs[name] else { print("bilinmeyen ad: \(name)"); exit(1) }

let side = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// macOS ızgarası: 824 px kare, 100 px kenar boşluğu, ~185 px köşe.
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
shadow.shadowOffset = NSSize(width: 0, height: -12)
shadow.shadowBlurRadius = 28
NSGraphicsContext.saveGraphicsState()
shadow.set()
rgb(d.bottom).setFill()
shape.fill()
NSGraphicsContext.restoreGraphicsState()

NSGradient(starting: rgb(d.top), ending: rgb(d.bottom))!.draw(in: shape, angle: -90)

// Üstte hafif parlama.
NSGraphicsContext.saveGraphicsState()
shape.addClip()
NSGradient(colors: [NSColor.white.withAlphaComponent(0.22), NSColor.white.withAlphaComponent(0)])!
    .draw(in: NSRect(x: 100, y: 560, width: 824, height: 364), angle: -90)
NSGraphicsContext.restoreGraphicsState()

if name == "islet" {
    // Çentiğin altında yüzen ada: siyah kapsül ve içinde iki durum noktası.
    let pill = NSRect(x: 232, y: 452, width: 560, height: 172)
    NSGraphicsContext.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    glow.shadowOffset = NSSize(width: 0, height: -10)
    glow.shadowBlurRadius = 30
    glow.set()
    NSColor.black.setFill()
    NSBezierPath(roundedRect: pill, xRadius: 86, yRadius: 86).fill()
    NSGraphicsContext.restoreGraphicsState()
    rgb(0x34D399).setFill()
    NSBezierPath(ovalIn: NSRect(x: 292, y: 504, width: 68, height: 68)).fill()
    rgb(0xFBBF24).setFill()
    NSBezierPath(roundedRect: NSRect(x: 400, y: 524, width: 230, height: 28), xRadius: 14, yRadius: 14).fill()
    NSColor.white.withAlphaComponent(0.35).setFill()
    NSBezierPath(roundedRect: NSRect(x: 660, y: 524, width: 72, height: 28), xRadius: 14, yRadius: 14).fill()
    // Altta dalga: ada denizde.
    NSColor.white.withAlphaComponent(0.85).setStroke()
    let wave = NSBezierPath()
    wave.lineWidth = 26
    wave.lineCapStyle = .round
    wave.move(to: NSPoint(x: 262, y: 330))
    for i in 0..<4 {
        let x = 262 + CGFloat(i) * 125
        wave.curve(to: NSPoint(x: x + 125, y: 330), controlPoint1: NSPoint(x: x + 40, y: 380),
                   controlPoint2: NSPoint(x: x + 85, y: 280))
    }
    wave.stroke()
} else {
    let config = NSImage.SymbolConfiguration(pointSize: 824 * d.scale, weight: .semibold)
        .applying(.init(paletteColors: [.white]))
    let symbol = NSImage(systemSymbolName: d.symbol, accessibilityDescription: nil)!.withSymbolConfiguration(config)!
    let s = symbol.size
    let fit = min(824 * d.scale / s.width, 824 * d.scale / s.height)
    let w = s.width * fit, h = s.height * fit
    NSGraphicsContext.saveGraphicsState()
    let soft = NSShadow()
    soft.shadowColor = NSColor.black.withAlphaComponent(0.25)
    soft.shadowOffset = NSSize(width: 0, height: -8)
    soft.shadowBlurRadius = 18
    soft.set()
    symbol.draw(in: NSRect(x: (1024 - w) / 2, y: (1024 - h) / 2 - 10, width: w, height: h))
    NSGraphicsContext.restoreGraphicsState()
}

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print(out)
