// Dibuja el icono de Mirro (1024x1024 PNG). Lo usa scripts/make-icon.sh (make icon).
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.dropFirst().first ?? "icon.png"

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
}

// Fondo: squircle con la rejilla de iconos de macOS (824pt dentro de 1024)
let bg = CGRect(x: 100, y: 100, width: 824, height: 824)
let bgPath = CGPath(roundedRect: bg, cornerWidth: 185, cornerHeight: 185, transform: nil)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
ctx.addPath(bgPath); ctx.setFillColor(color(0x000000)); ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(bgPath); ctx.clip()
ctx.drawLinearGradient(gradient([color(0x4BE39A), color(0x0E8C6B), color(0x0A5C55)]),
                       start: CGPoint(x: 200, y: 924), end: CGPoint(x: 824, y: 100), options: [])
// brillo superior
ctx.drawRadialGradient(gradient([color(0xFFFFFF, 0.28), color(0xFFFFFF, 0)]),
                       startCenter: CGPoint(x: 330, y: 860), startRadius: 0,
                       endCenter: CGPoint(x: 330, y: 860), endRadius: 560, options: [])
ctx.restoreGState()

// Teléfono
func phone(_ r: CGRect, body: CGColor, screen: [CGColor]?, shadow: Bool) {
    let p = CGPath(roundedRect: r, cornerWidth: 62, cornerHeight: 62, transform: nil)
    ctx.saveGState()
    if shadow { ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: color(0x00332B, 0.45)) }
    ctx.addPath(p); ctx.setFillColor(body); ctx.fillPath()
    ctx.restoreGState()

    guard let screen else { return }
    let s = r.insetBy(dx: 22, dy: 22)
    let sp = CGPath(roundedRect: s, cornerWidth: 42, cornerHeight: 42, transform: nil)
    ctx.saveGState()
    ctx.addPath(sp); ctx.clip()
    ctx.drawLinearGradient(gradient(screen), start: CGPoint(x: s.minX, y: s.maxY),
                           end: CGPoint(x: s.maxX, y: s.minY), options: [])
    ctx.restoreGState()
    // cámara perforada
    ctx.setFillColor(color(0x0B2B27))
    ctx.fillEllipse(in: CGRect(x: s.midX - 13, y: s.maxY - 44, width: 26, height: 26))
}

let w: CGFloat = 330, h: CGFloat = 580
// Copia "reflejada" detrás, desplazada a la derecha
phone(CGRect(x: 452, y: 250, width: w, height: h), body: color(0xFFFFFF, 0.30), screen: nil, shadow: false)
let inner = CGRect(x: 452, y: 250, width: w, height: h).insetBy(dx: 22, dy: 22)
ctx.addPath(CGPath(roundedRect: inner, cornerWidth: 42, cornerHeight: 42, transform: nil))
ctx.setFillColor(color(0xFFFFFF, 0.18)); ctx.fillPath()

// Teléfono principal
phone(CGRect(x: 242, y: 194, width: w, height: h), body: color(0xFFFFFF),
      screen: [color(0x1FCB8B), color(0x0D7A66)], shadow: true)

// Ondas de "proyección" en la pantalla
ctx.setStrokeColor(color(0xFFFFFF, 0.92))
ctx.setLineCap(.round)
let c = CGPoint(x: 242 + w / 2 - 60, y: 194 + h / 2 - 40)
for (i, radius) in [CGFloat(48), 96, 144].enumerated() {
    ctx.setLineWidth(26 - CGFloat(i) * 4)
    ctx.addArc(center: c, radius: radius, startAngle: .pi * 0.25, endAngle: -.pi * 0.25, clockwise: true)
    ctx.strokePath()
}
ctx.setFillColor(color(0xFFFFFF))
ctx.fillEllipse(in: CGRect(x: c.x - 22, y: c.y - 22, width: 44, height: 44))

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("✓ \(out)")
