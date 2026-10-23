import SwiftUI

/// How a decision looks, in one place: the gesture, the stamp on the card and
/// the button all have to say the same thing in the same colour.
extension SwipeDecision {
    var color: Color { self == .keep ? RummageTheme.keep : RummageTheme.del }
    var iconName: String { self == .keep ? "checkmark" : "trash" }
    var label: String { self == .keep ? "Keep" : "Delete" }
}

/// Monospace, for the wordmark and for figures that should not jiggle as they
/// count. Everything the user *reads* is set in the sans face.
struct MonoLabel: View {
    let text: String
    var size: CGFloat = 11
    var tracking: CGFloat = 0
    var color: Color = RummageTheme.text3
    var uppercase: Bool = false

    var body: some View {
        Text(uppercase ? text.uppercased() : text)
            .rummageMono(size: size, tracking: tracking)
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
            .background(RummageTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(RummageTheme.lineSolid, lineWidth: 1)
            )
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(RummageTheme.lineSolid)
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
                Circle().fill(RummageTheme.surface)
                Image(systemName: systemName)
                    .font(.system(size: size * 0.42, weight: .regular))
                    .foregroundStyle(RummageTheme.text2)
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
            .foregroundStyle(RummageTheme.text3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
    }
}

struct ThinProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(RummageTheme.lineSolid)
                Capsule()
                    .fill(RummageTheme.text)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: 4)
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
                .foregroundStyle(RummageTheme.amberInk)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(RummageTheme.amber)
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
                .foregroundStyle(RummageTheme.text2)
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
            .foregroundStyle(RummageTheme.text3)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}
