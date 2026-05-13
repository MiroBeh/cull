import SwiftUI

enum CullOnboardTheme {
    private static func hex(_ hex: UInt32) -> Color {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    static let bg        = hex(0x1A1B1F)
    static let surface   = hex(0x25272A)
    static let surface2  = hex(0x2F3134)
    static let lineSolid = hex(0x3D4044)
    static let text      = hex(0xF4F3EF)
    static let text2     = hex(0xA7A9AD)
    static let text3     = hex(0x6B6D71)
    static let amber     = hex(0xE3BF6F)
}

struct CullMonoStyle: ViewModifier {
    let size: CGFloat
    let tracking: CGFloat
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .medium, design: .monospaced))
            .tracking(tracking)
    }
}

struct CullSansStyle: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let tracking: CGFloat
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .tracking(tracking)
    }
}

extension View {
    func cullMono(size: CGFloat, tracking: CGFloat = 0) -> some View {
        modifier(CullMonoStyle(size: size, tracking: tracking))
    }
    func cullSans(size: CGFloat, weight: Font.Weight = .regular, tracking: CGFloat = 0) -> some View {
        modifier(CullSansStyle(size: size, weight: weight, tracking: tracking))
    }
}
