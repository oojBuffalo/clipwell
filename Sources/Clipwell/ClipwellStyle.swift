import SwiftUI

enum Ink {
    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        func swatch(_ hex: UInt32) -> NSColor {
            NSColor(srgbRed: CGFloat(hex >> 16) / 255,
                    green: CGFloat((hex >> 8) & 255) / 255,
                    blue: CGFloat(hex & 255) / 255, alpha: 1)
        }
        return Color(nsColor: NSColor(name: nil) { appearance in
            swatch(appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light)
        })
    }

    static let surface = adaptive(0xFCFCF9, 0x202522)
    static let inset = adaptive(0xF3F4EF, 0x2B302D)
    static let text = adaptive(0x202923, 0xF1F4EE)
    static let secondary = adaptive(0x5D685E, 0xB2BDB3)
    static let line = adaptive(0xDBDFD7, 0x424A44)
    static let accent = adaptive(0x19674F, 0x99D7B6)
    static let tint = adaptive(0xE1EFE5, 0x2F473B)
    static let key = adaptive(0xFAFBF7, 0x353C36)
}

struct Keycap: View {
    var key: String
    var body: some View {
        Text(verbatim: key)
            .font(.system(size: 10.5, weight: .medium, design: .rounded))
            .foregroundStyle(Ink.secondary)
            .padding(.horizontal, 4)
            .frame(minWidth: 18, minHeight: 18)
            .background(Ink.key, in: RoundedRectangle(cornerRadius: 4))
            .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(Ink.line, lineWidth: 0.7) }
    }
}

struct BrandMark: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 32
            context.scaleBy(x: scale, y: scale)
            func rounded(_ rect: CGRect, _ radius: CGFloat) -> Path {
                Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
            }
            context.fill(rounded(CGRect(x: 0, y: 0, width: 32, height: 32), 8),
                         with: .linearGradient(Gradient(colors: [
                            Color(red: 0.23, green: 0.49, blue: 0.36),
                            Color(red: 0.07, green: 0.29, blue: 0.23)
                         ]), startPoint: .zero, endPoint: CGPoint(x: 28, y: 32)))
            var back = context
            back.rotate(by: .degrees(-9))
            back.fill(rounded(CGRect(x: 5, y: 10, width: 13, height: 16), 2.2),
                      with: .color(Color(red: 0.64, green: 0.81, blue: 0.64)))
            context.fill(rounded(CGRect(x: 11, y: 7, width: 13, height: 18), 2.5),
                         with: .color(Color(red: 0.97, green: 0.97, blue: 0.87)))
            let green = Color(red: 0.23, green: 0.43, blue: 0.32)
            context.fill(rounded(CGRect(x: 14.2, y: 5.6, width: 6.6, height: 3.9), 1.6),
                         with: .color(Color(red: 0.71, green: 0.84, blue: 0.65)))
            for (y, w) in [(13.2, 7.4), (16.3, 7.4), (19.4, 4.4)] {
                context.fill(rounded(CGRect(x: 14, y: y, width: w, height: 1.2), 0.6), with: .color(green))
            }
        }
        .accessibilityHidden(true)
    }
}

struct IconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(width: 26, height: 26)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Ink.secondary)
                .background(hovered ? Ink.inset : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityLabel(label)
        .help(label)
    }
}
