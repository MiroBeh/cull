import SwiftUI
import Photos

/// One photo, one question. The two buttons and the swipe are the same action:
/// as you drag, the card tilts, the decision stamps onto it, the matching edge
/// of the screen washes with colour and the matching button lights up.
struct ReviewView: View {
    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    /// How far the card has to travel before letting go decides anything. Short
    /// of this it springs back, so a twitch cannot delete a photo.
    private static let commitDistance: CGFloat = 110

    @State private var dragX: CGFloat = 0
    @State private var isLeaving = false

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            RummageTheme.bg.ignoresSafeArea()

            switch session.phase {
            case .loading:
                ProgressView().tint(RummageTheme.text2)
            case .reviewing:
                reviewing
            case .finished(let summary):
                DoneView(
                    summary: summary,
                    onMore: { Task { await session.start() } },
                    onFinish: { dismiss() }
                )
            }
        }
        .overlay(alignment: .leading) { edgeWash(for: .delete) }
        .overlay(alignment: .trailing) { edgeWash(for: .keep) }
        .preferredColorScheme(.dark)
        .padding(.top, 54)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task { await session.start() }
        .onDisappear {
            // The exit button and the done screen both leave a finished
            // session behind. Anything else — a back gesture, say — would
            // otherwise lose the deletions the user already made.
            if session.isReviewing {
                Task { await session.endEarly() }
            }
        }
    }

    // MARK: - The drag

    private var pending: SwipeDecision? {
        guard abs(dragX) >= Self.commitDistance else { return nil }
        return dragX > 0 ? .keep : .delete
    }

    /// 0 at rest, 1 at the commit point.
    private var dragProgress: Double {
        min(1, abs(dragX) / Self.commitDistance)
    }

    private var leaning: SwipeDecision? {
        guard abs(dragX) > 6 else { return nil }
        return dragX > 0 ? .keep : .delete
    }

    private var swipe: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isLeaving else { return }
                dragX = value.translation.width
            }
            .onEnded { value in
                guard !isLeaving else { return }
                let travelled = value.translation.width
                let predicted = value.predictedEndTranslation.width
                let commit = Self.commitDistance
                if travelled >= commit || predicted >= commit {
                    decide(.keep)
                } else if travelled <= -commit || predicted <= -commit {
                    decide(.delete)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) { dragX = 0 }
                }
            }
    }

    /// The buttons and the gesture both come through here, so they do visibly
    /// the same thing.
    private func decide(_ decision: SwipeDecision) {
        guard !isLeaving else { return }
        isLeaving = true
        withAnimation(.easeOut(duration: 0.2)) {
            dragX = decision == .keep ? 720 : -720
        }
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            // The card is off screen by now. Advance first and re-centre in the
            // same pass — re-centring first would flash the photo that was just
            // decided back into the middle of the screen.
            switch decision {
            case .keep: await session.keep()
            case .delete: await session.delete()
            }
            dragX = 0
            isLeaving = false
        }
    }

    // MARK: - Reviewing

    private var reviewing: some View {
        VStack(spacing: 0) {
            progressHeader
            photoArea
            metaRow
            actions
            hint
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                // The prototype never shows a way out of a session; starting 50
                // photos by accident has to be survivable, so this stays.
                Button {
                    // Nothing decided yet means nothing to report and nothing
                    // to delete: someone who pressed Start by accident should
                    // just be let out.
                    if session.hasDecisions {
                        Task { await session.endEarly() }
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(RummageTheme.text3)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("End this session")

                Text("\(session.position) of \(session.total)")
                    .font(.system(size: 13))
                    .foregroundStyle(RummageTheme.text2)
                    .monospacedDigit()

                Spacer()

                if session.bytesFreedSoFar > 0 {
                    MonoLabel(
                        text: "+\(StorageEstimate.format(session.bytesFreedSoFar)) freed",
                        size: 12,
                        color: RummageTheme.amber
                    )
                }
            }
            ThinProgressBar(value: session.progress)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }

    private var photoArea: some View {
        ZStack {
            if let photo = session.current {
                PhotoCardView(photo: photo)
                    // A fresh card per photo, so the last photo's image is not
                    // shown while the next one loads.
                    .id(photo.id)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(stamp)
                    .shadow(color: .black.opacity(abs(dragX) > 6 ? 0.5 : 0.3), radius: 28, y: 16)
                    .offset(x: dragX)
                    .rotationEffect(.degrees(Double(dragX) / 16), anchor: .bottom)
                    .gesture(swipe)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    @ViewBuilder
    private var stamp: some View {
        if let pending {
            // Stamped on the leading edge of the card's travel, tilted the way
            // the card is going.
            let isKeep = pending == .keep
            HStack(spacing: 8) {
                Image(systemName: pending.iconName)
                Text(pending.label)
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(pending.color)
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(RummageTheme.bg.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(pending.color, lineWidth: 2)
            )
            .rotationEffect(.degrees(isKeep ? -6 : 6))
            .padding(22)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: isKeep ? .topLeading : .topTrailing
            )
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func edgeWash(for decision: SwipeDecision) -> some View {
        if session.isReviewing, leaning == decision {
            LinearGradient(
                colors: [decision.color.opacity(0.5), decision.color.opacity(0.14), .clear],
                startPoint: decision == .keep ? .trailing : .leading,
                endPoint: decision == .keep ? .leading : .trailing
            )
            .frame(width: 120)
            .opacity(dragProgress)
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }

    private var metaRow: some View {
        HStack(spacing: 12) {
            Text(metaText)
                .font(.system(size: 14))
                .foregroundStyle(RummageTheme.text2)
            Spacer()
            if let photo = session.current {
                SharePhotoButton(photo: photo, title: dateText(for: photo))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var metaText: String {
        guard let photo = session.current else { return " " }
        return "\(dateText(for: photo)) · \(StorageEstimate.format(StorageEstimate.bytes(for: photo)))"
    }

    private func dateText(for photo: Photo) -> String {
        guard let date = photo.creationDate else { return "No date" }
        return Self.dateFmt.string(from: date)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            actionButton(.delete)
            actionButton(.keep)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private func actionButton(_ decision: SwipeDecision) -> some View {
        let color = decision.color
        let isLit = pending == decision
        let isDimmed = pending != nil && pending != decision
        // Below the commit point the matching button brightens with the drag;
        // past it, it is lit and the other one dims.
        let fill = leaning == decision ? 0.14 + 0.16 * dragProgress : 0.14

        return Button {
            decide(decision)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: decision.iconName)
                    .font(.system(size: 24, weight: .regular))
                Text(decision.label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .background(color.opacity(fill))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(color.opacity(isLit ? 1 : 0.4), lineWidth: isLit ? 2 : 1)
            )
            .opacity(isDimmed ? 0.3 : 1)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.12), value: isLit)
        .animation(.easeOut(duration: 0.12), value: isDimmed)
    }

    @ViewBuilder
    private var hint: some View {
        if let pending {
            HintLine(text: pending == .keep ? "Let go to keep it" : "Let go to delete it")
                .padding(.top, 14)
                .padding(.bottom, 28)
        } else if session.canUndo {
            Button { session.undo() } label: {
                HStack(spacing: 6) {
                    Text("Swipe the photo, or tap  ·")
                        .font(.system(size: 13))
                        .foregroundStyle(RummageTheme.text3)
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12))
                    Text("Undo")
                        .font(.system(size: 13))
                }
                .foregroundStyle(RummageTheme.text2)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
            .padding(.bottom, 28)
        } else {
            HintLine(text: "Swipe the photo, or tap a button")
                .padding(.top, 14)
                .padding(.bottom, 28)
        }
    }
}

/// The photo itself, at display size. Sharing asks for the original separately.
struct PhotoCardView: View {
    let photo: Photo
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(RummageTheme.surface2)
                        .overlay(ProgressView().tint(RummageTheme.text2))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .task(id: photo.id) {
                image = await PhotoLibraryService.image(
                    for: photo,
                    targetSize: CGSize(
                        width: geo.size.width * displayScale,
                        height: geo.size.height * displayScale
                    )
                )
            }
        }
    }
}
