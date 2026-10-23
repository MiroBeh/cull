import SwiftUI

// MARK: - Icon Shapes

/// One card of the stack icon, placed on an 80×80 grid. The front card also
/// carries the little picture: a sun and a mountain line.
struct StackCard: Shape {
    let x: CGFloat
    let y: CGFloat
    var showsPicture = false

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 80.0
        var p = Path()
        p.addRoundedRect(
            in: CGRect(x: x * scale, y: y * scale, width: 40 * scale, height: 46 * scale),
            cornerSize: CGSize(width: 5 * scale, height: 5 * scale)
        )
        guard showsPicture else { return p }
        let cr = 3.0 * scale
        p.addEllipse(in: CGRect(
            x: 42 * scale - cr, y: 24 * scale - cr,
            width: cr * 2, height: cr * 2
        ))
        let pts: [(CGFloat, CGFloat)] = [(30,46),(38,38),(46,46),(56,36),(70,50)]
        p.move(to: CGPoint(x: pts[0].0 * scale, y: pts[0].1 * scale))
        for pt in pts.dropFirst() {
            p.addLine(to: CGPoint(x: pt.0 * scale, y: pt.1 * scale))
        }
        return p
    }
}

struct SwipeIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 80.0
        var p = Path()
        p.addRoundedRect(
            in: CGRect(x: 22 * scale, y: 14 * scale, width: 36 * scale, height: 48 * scale),
            cornerSize: CGSize(width: 6 * scale, height: 6 * scale)
        )
        p.move(to: CGPoint(x: 14 * scale, y: 30 * scale))
        p.addLine(to: CGPoint(x: 22 * scale, y: 38 * scale))
        p.addLine(to: CGPoint(x: 14 * scale, y: 46 * scale))
        p.move(to: CGPoint(x: 66 * scale, y: 30 * scale))
        p.addLine(to: CGPoint(x: 58 * scale, y: 38 * scale))
        p.addLine(to: CGPoint(x: 66 * scale, y: 46 * scale))
        p.move(to: CGPoint(x: 28 * scale, y: 38 * scale))
        p.addLine(to: CGPoint(x: 22 * scale, y: 38 * scale))
        p.move(to: CGPoint(x: 58 * scale, y: 38 * scale))
        p.addLine(to: CGPoint(x: 52 * scale, y: 38 * scale))
        return p
    }
}

struct SparkRaysShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 80.0
        var p = Path()
        p.move(to: CGPoint(x: 40 * scale, y: 10 * scale))
        p.addLine(to: CGPoint(x: 40 * scale, y: 70 * scale))
        p.move(to: CGPoint(x: 10 * scale, y: 40 * scale))
        p.addLine(to: CGPoint(x: 70 * scale, y: 40 * scale))
        p.move(to: CGPoint(x: 22 * scale, y: 22 * scale))
        p.addLine(to: CGPoint(x: 58 * scale, y: 58 * scale))
        p.move(to: CGPoint(x: 58 * scale, y: 22 * scale))
        p.addLine(to: CGPoint(x: 22 * scale, y: 58 * scale))
        return p
    }
}

struct SparkCoreShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 80.0
        let r = 14.0 * scale
        var p = Path()
        p.addEllipse(in: CGRect(x: 40 * scale - r, y: 40 * scale - r, width: r * 2, height: r * 2))
        return p
    }
}

// MARK: - Icon Views

private struct StackIconView: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            StackCard(x: 14, y: 22)
                .stroke(RummageTheme.text, lineWidth: 1.4 * (size / 80))
                .opacity(0.35)
            StackCard(x: 22, y: 16)
                .stroke(RummageTheme.text, lineWidth: 1.4 * (size / 80))
                .opacity(0.6)
            StackCard(x: 30, y: 10, showsPicture: true)
                .stroke(
                    RummageTheme.text,
                    style: StrokeStyle(lineWidth: 1.4 * (size / 80), lineJoin: .round)
                )
        }
        .frame(width: size, height: size)
    }
}

private struct SwipeIconView: View {
    let size: CGFloat
    var body: some View {
        SwipeIconShape()
            .stroke(
                RummageTheme.text,
                style: StrokeStyle(lineWidth: 1.4 * (size / 80), lineCap: .round, lineJoin: .round)
            )
            .frame(width: size, height: size)
    }
}

private struct SparkIconView: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            SparkRaysShape()
                .stroke(
                    RummageTheme.text,
                    style: StrokeStyle(lineWidth: 1.4 * (size / 80), lineCap: .round, lineJoin: .round)
                )
                .opacity(0.35)
            SparkCoreShape()
                .fill(RummageTheme.text)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    let onComplete: () -> Void
    @EnvironmentObject var photoService: PhotoLibraryService
    @State private var step: Int = 0

    var body: some View {
        ZStack {
            RummageTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                switch step {
                case 0:
                    screenView(
                        eyebrow: "RUMMAGE · V1.0",
                        icon: AnyView(StackIconView(size: 56)),
                        title: "Rummage through your camera roll.",
                        body: "Fifty photos at a time, about two minutes. No lists to pick from — press one button and start reclaiming the gigabytes you forgot you were paying for.",
                        ctaText: "Continue",
                        ctaTag: "→ 02",
                        showSkip: true,
                        isAmber: false
                    )
                case 1:
                    screenView(
                        eyebrow: "MECHANICS",
                        icon: AnyView(SwipeIconView(size: 56)),
                        title: "Keep or delete.",
                        body: "Two buttons, or swipe the photo: right keeps, left deletes. Find one you had forgotten about and you can share it without leaving the session. Photos you keep are left out for 90 days.",
                        ctaText: "Continue",
                        ctaTag: "→ 03",
                        showSkip: true,
                        isAmber: false
                    )
                default:
                    screenView(
                        eyebrow: "PERMISSION",
                        icon: AnyView(SparkIconView(size: 56)),
                        title: "One thing first.",
                        body: "Rummage needs access to your photo library. Nothing leaves your device unless you share it, and shared photos never carry their location. iOS asks you to confirm before anything is deleted, and deletions land in Recently Deleted — recoverable for 30 days.",
                        ctaText: "Grant access",
                        ctaTag: "BEGIN ↗",
                        showSkip: false,
                        isAmber: true
                    )
                }
            }
            .padding(.top, 54)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func screenView(
        eyebrow: String,
        icon: AnyView,
        title: String,
        body: String,
        ctaText: String,
        ctaTag: String,
        showSkip: Bool,
        isAmber: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(eyebrow)
                    .rummageMono(size: 11, tracking: 0.22 * 11)
                    .foregroundStyle(RummageTheme.text3)
                    .textCase(.uppercase)
                Spacer()
                Text(String(format: "%02d / 03", step + 1))
                    .rummageMono(size: 11, tracking: 0.22 * 11)
                    .foregroundStyle(RummageTheme.text3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)

            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(RummageTheme.surface)
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(RummageTheme.lineSolid, lineWidth: 1)
                    icon
                }
                .frame(width: 96, height: 96)
                .padding(.bottom, 36)

                Text(title)
                    .rummageSans(size: 34, weight: .medium, tracking: -0.025 * 34)
                    .foregroundStyle(RummageTheme.text)
                    .lineSpacing(2)

                Text(body)
                    .rummageSans(size: 15)
                    .foregroundStyle(RummageTheme.text2)
                    .lineSpacing(6)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 28)
            .padding(.top, 40)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            VStack(spacing: 8) {
                progressBar

                Button {
                    if isAmber {
                        Task {
                            _ = await photoService.requestAuthorization()
                            onComplete()
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.22)) {
                            step += 1
                        }
                    }
                } label: {
                    HStack {
                        Text(ctaText)
                            .rummageSans(size: 15, weight: .medium)
                        Spacer()
                        Text(ctaTag)
                            .rummageMono(size: 10, tracking: 0.14 * 10)
                    }
                    .foregroundStyle(RummageTheme.bg)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(isAmber ? RummageTheme.amber : RummageTheme.text)
                    .cornerRadius(14)
                }

                if showSkip {
                    Button {
                        withAnimation(.easeOut(duration: 0.22)) {
                            step = 2
                        }
                    } label: {
                        Text("SKIP")
                            .rummageMono(size: 10, tracking: 0.18 * 10)
                            .foregroundStyle(RummageTheme.text3)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 6)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(i <= step ? RummageTheme.text : RummageTheme.surface2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .padding(.bottom, 12)
    }
}
