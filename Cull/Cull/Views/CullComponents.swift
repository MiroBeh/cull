import SwiftUI

extension CullTheme {
    static let keep = Color(.sRGB, red: 0.373, green: 0.812, blue: 0.541, opacity: 1)
    static let del  = Color(.sRGB, red: 0.894, green: 0.463, blue: 0.408, opacity: 1)

    static let keepDim  = Color(.sRGB, red: 0.373, green: 0.812, blue: 0.541, opacity: 0.14)
    static let delDim   = Color(.sRGB, red: 0.894, green: 0.463, blue: 0.408, opacity: 0.14)
    static let amberDim = Color(.sRGB, red: 0.890, green: 0.749, blue: 0.435, opacity: 0.14)
    static let text4    = Color(.sRGB, red: 0.251, green: 0.259, blue: 0.271, opacity: 1)
    static let surfaceUp = Color(.sRGB, red: 0.224, green: 0.231, blue: 0.243, opacity: 1)
}

struct MonoLabel: View {
    let text: String
    var size: CGFloat = 11
    var tracking: CGFloat = 0
    var color: Color = CullTheme.text3
    var uppercase: Bool = true

    var body: some View {
        Text(uppercase ? text.uppercased() : text)
            .cullMono(size: size, tracking: tracking)
            .foregroundStyle(color)
    }
}

struct SurfaceGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(CullTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(CullTheme.lineSolid, lineWidth: 1)
            )
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(CullTheme.lineSolid)
            .frame(height: 1)
    }
}

struct IconPillButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 999)
                    .fill(CullTheme.surface)
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(CullTheme.text2)
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

struct SectionHeader: View {
    let label: String
    var right: String? = nil

    var body: some View {
        HStack {
            MonoLabel(text: label, size: 10, tracking: 0.22 * 10, color: CullTheme.text3)
            Spacer()
            if let right {
                MonoLabel(text: right, size: 10, tracking: 0.22 * 10, color: CullTheme.text4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

struct ThinProgressBar: View {
    let value: Double
    var color: Color = CullTheme.text
    var height: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(CullTheme.lineSolid.opacity(0.4))
                RoundedRectangle(cornerRadius: 999)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
    }
}
