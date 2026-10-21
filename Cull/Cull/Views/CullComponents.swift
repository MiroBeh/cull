import SwiftUI

extension CullTheme {
    static let keep = Color(.sRGB, red: 0.373, green: 0.812, blue: 0.541, opacity: 1)
    static let del  = Color(.sRGB, red: 0.894, green: 0.463, blue: 0.408, opacity: 1)
    static let text4 = Color(.sRGB, red: 0.251, green: 0.259, blue: 0.271, opacity: 1)
    /// Ink on an amber button — amber is a background here, never text on text.
    static let amberInk = Color(.sRGB, red: 0.125, green: 0.106, blue: 0.063, opacity: 1)
}

/// Monospace, for the wordmark and for figures that should not jiggle as they
/// count. Everything the user *reads* is set in the sans face.
struct MonoLabel: View {
    let text: String
    var size: CGFloat = 11
    var tracking: CGFloat = 0
    var color: Color = CullTheme.text3
    var uppercase: Bool = false

    var body: some View {
        Text(uppercase ? text.uppercased() : text)
            .cullMono(size: size, tracking: tracking)
            .foregroundStyle(color)
            .monospacedDigit()
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
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
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
    var size: CGFloat = 36
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(CullTheme.surface)
                Image(systemName: systemName)
                    .font(.system(size: size * 0.42, weight: .regular))
                    .foregroundStyle(CullTheme.text2)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(CullTheme.text3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
    }
}

struct ThinProgressBar: View {
    let value: Double
    var color: Color = CullTheme.text
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(CullTheme.lineSolid)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.2), value: value)
    }
}

/// The one loud button on a screen.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(CullTheme.amberInk)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(CullTheme.amber)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

/// The equally easy way out, next to it.
struct QuietButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(CullTheme.text2)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.plain)
    }
}

struct HintLine: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(CullTheme.text3)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}
