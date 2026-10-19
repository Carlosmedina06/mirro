import AppKit

/// Icono de la barra de estado dibujado a mano: teléfono + ondas, como el icono de la app.
/// Es una imagen "template", así que macOS la tiñe sola en modo claro/oscuro.
enum StatusIcon {
    enum Style { case idle, mirroring, warning }

    static func image(_ style: Style) -> NSImage {
        let img = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            draw(style)
            return true
        }
        img.isTemplate = true
        img.accessibilityDescription = "Mirro"
        return img
    }

    private static func draw(_ style: Style) {
        NSColor.black.set()

        // Teléfono
        let phone = NSRect(x: 2.5, y: 1, width: 8, height: 16)
        if style == .mirroring {
            NSBezierPath(roundedRect: phone, xRadius: 2.4, yRadius: 2.4).fill()
            // Cámara perforada (recorte transparente)
            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(ovalIn: NSRect(x: phone.midX - 0.85, y: phone.maxY - 3.3, width: 1.7, height: 1.7)).fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver
        } else {
            let p = NSBezierPath(roundedRect: phone.insetBy(dx: 0.7, dy: 0.7), xRadius: 1.9, yRadius: 1.9)
            p.lineWidth = 1.4
            p.stroke()
            NSBezierPath(ovalIn: NSRect(x: phone.midX - 0.65, y: phone.maxY - 3.1, width: 1.3, height: 1.3)).fill()
        }

        // Ondas de proyección saliendo del teléfono
        let center = NSPoint(x: phone.maxX + 0.5, y: phone.midY)
        let radii: [CGFloat] = style == .warning ? [] : [3.6, 6.6]
        for r in radii {
            let arc = NSBezierPath()
            arc.appendArc(withCenter: center, radius: r, startAngle: -48, endAngle: 48)
            arc.lineWidth = style == .mirroring ? 1.8 : 1.5
            arc.lineCapStyle = .round
            arc.stroke()
        }

        // Aviso: faltan herramientas
        if style == .warning {
            let x = phone.maxX + 4.5
            let bar = NSBezierPath()
            bar.move(to: NSPoint(x: x, y: 13.5))
            bar.line(to: NSPoint(x: x, y: 7.5))
            bar.lineWidth = 2
            bar.lineCapStyle = .round
            bar.stroke()
            NSBezierPath(ovalIn: NSRect(x: x - 1.2, y: 2.6, width: 2.4, height: 2.4)).fill()
        }
    }
}
