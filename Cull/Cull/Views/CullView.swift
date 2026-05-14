import SwiftUI
import Photos

struct CullView: View {
    let filter: SessionFilter
    @EnvironmentObject var viewModel: CullViewModel
    @EnvironmentObject var photoService: PhotoLibraryService
    @EnvironmentObject var historyService: ReviewHistoryService
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGSize = .zero

    private static let monthFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

    private static let dateLineFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd·MMM·yyyy · HH:mm"
        return f
    }()

    private var filterTitle: String {
        switch filter {
        case .all: return "All Photos"
        case .month(let y, let m):
            var c = DateComponents(); c.year = y; c.month = m
            guard let d = Calendar.current.date(from: c) else { return "Photos" }
            return Self.monthFmt.string(from: d)
        case .album(_, let title): return title
        }
    }

    private var filterSubtitle: String {
        switch filter {
        case .all: return ""
        case .month(let y, _): return "\(y)"
        case .album: return ""
        }
    }

    private var freedMB: Int {
        viewModel.toDelete.count * 4
    }

    var body: some View {
        ZStack {
            CullTheme.bg.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(CullTheme.text2)
            } else if viewModel.isComplete {
                completionView
            } else {
                mainContent
            }
        }
        .preferredColorScheme(.dark)
        .padding(.top, 54)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task(id: filter) {
            await viewModel.loadPhotos(using: photoService, history: historyService, filter: filter)
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            topBar
            progressStrip
            cardStack
                .padding(.horizontal, 20)
                .padding(.top, 20)
            metadataStrip
            dotIndicator
                .padding(.bottom, 28)
        }
    }

    private var topBar: some View {
        HStack {
            IconPillButton(systemName: "chevron.left") { dismiss() }
            Spacer()
            VStack(spacing: 3) {
                Text(filterTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(CullTheme.text)
                if !filterSubtitle.isEmpty {
                    MonoLabel(text: filterSubtitle, size: 9, tracking: 0.18 * 9, color: CullTheme.text3)
                }
            }
            Spacer()
            endButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var endButton: some View {
        Button {
            viewModel.endSessionEarly()
        } label: {
            MonoLabel(text: "END", size: 11, tracking: 0.06 * 11, color: CullTheme.text2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(CullTheme.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.currentIndex == 0)
    }

    private var progressStrip: some View {
        let total = max(1, viewModel.progress.total)
        let reviewed = viewModel.progress.reviewed
        let fraction = Double(reviewed) / Double(total)

        return VStack(spacing: 6) {
            HStack {
                MonoLabel(
                    text: "\(reviewed) / \(total)",
                    size: 10,
                    tracking: 0.14 * 10,
                    color: CullTheme.text3
                )
                Spacer()
                MonoLabel(
                    text: "+\(freedMB) MB FREED",
                    size: 10,
                    tracking: 0.14 * 10,
                    color: CullTheme.amber
                )
            }
            ThinProgressBar(value: fraction, color: CullTheme.text, height: 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var cardStack: some View {
        ZStack {
            HStack {
                sideRail(isDelete: true)
                Spacer()
                sideRail(isDelete: false)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(CullTheme.surface2)
                    .scaleEffect(0.88)
                    .offset(y: 28)
                    .opacity(0.5)

                RoundedRectangle(cornerRadius: 18)
                    .fill(CullTheme.surface2)
                    .scaleEffect(0.94)
                    .offset(y: 14)
                    .opacity(0.75)

                if let photo = viewModel.currentPhoto {
                    activeCard(photo: photo)
                }
            }
            .frame(maxWidth: 320)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
        .frame(maxWidth: .infinity)
    }

    private func activeCard(photo: Photo) -> some View {
        PhotoCardView(asset: photo.asset)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.4), radius: 30, y: 18)
            .offset(x: dragOffset.width)
            .rotationEffect(.degrees(Double(dragOffset.width) / 12))
            .overlay(decisionOverlay)
            .gesture(swipeGesture)
    }

    @ViewBuilder
    private var decisionOverlay: some View {
        let dx = dragOffset.width
        if abs(dx) > 30 {
            ZStack {
                if dx > 30 {
                    keepChip
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(20)
                }
                if dx < -30 {
                    deleteChip
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(20)
                }
            }
        }
    }

    private var keepChip: some View {
        MonoLabel(text: "KEEP", size: 18, tracking: 0.08 * 18, color: CullTheme.keep)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CullTheme.keep, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .rotationEffect(.degrees(-8))
    }

    private var deleteChip: some View {
        MonoLabel(text: "DELETE", size: 18, tracking: 0.08 * 18, color: CullTheme.del)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CullTheme.del, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .rotationEffect(.degrees(8))
    }

    private func sideRail(isDelete: Bool) -> some View {
        let dx = dragOffset.width
        let active = isDelete ? dx < -10 : dx > 10
        let activeColor = isDelete ? CullTheme.del : CullTheme.keep
        let color = active ? activeColor : CullTheme.text4
        let icon = isDelete ? "trash" : "checkmark"
        let label = isDelete ? "DELETE" : "KEEP"

        return VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(label)
                .cullMono(size: 9, tracking: 0.32 * 9)
                .foregroundStyle(color)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 14)
        .animation(.easeInOut(duration: 0.15), value: active)
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                handleSwipeEnd(value: value)
            }
    }

    private func handleSwipeEnd(value: DragGesture.Value) {
        let w = value.translation.width
        let predicted = value.predictedEndTranslation.width
        if predicted > 120 || w > 120 {
            withAnimation(.easeOut(duration: 0.25)) {
                dragOffset = CGSize(width: 600, height: value.translation.height)
            }
            Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                viewModel.swipeRight()
                withAnimation(.spring()) { dragOffset = .zero }
            }
        } else if predicted < -120 || w < -120 {
            withAnimation(.easeOut(duration: 0.25)) {
                dragOffset = CGSize(width: -600, height: value.translation.height)
            }
            Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                viewModel.swipeLeft()
                withAnimation(.spring()) { dragOffset = .zero }
            }
        } else {
            withAnimation(.spring()) { dragOffset = .zero }
        }
    }

    private var metadataStrip: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                MonoLabel(
                    text: photoDateLine,
                    size: 11,
                    tracking: 0.08 * 11,
                    color: CullTheme.text2
                )
                MonoLabel(
                    text: photoDimLine,
                    size: 9,
                    tracking: 0.14 * 9,
                    color: CullTheme.text4
                )
            }
            Spacer()
            undoPill
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var photoDateLine: String {
        guard let date = viewModel.currentPhoto?.creationDate else { return "—" }
        return Self.dateLineFmt.string(from: date).uppercased()
    }

    private var photoDimLine: String {
        guard let asset = viewModel.currentPhoto?.asset else { return "—" }
        let w = asset.pixelWidth
        let h = asset.pixelHeight
        let uti = asset.value(forKey: "uniformTypeIdentifier") as? String
        let ext = uti.flatMap { $0.split(separator: ".").last.map(String.init) }?.uppercased() ?? ""
        return ext.isEmpty ? "\(w)×\(h)" : "\(w)×\(h) · \(ext)"
    }

    private var undoPill: some View {
        Button {
            viewModel.undo()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13))
                    .foregroundStyle(CullTheme.text2)
                MonoLabel(text: "UNDO", size: 10, tracking: 0.12 * 10, color: CullTheme.text2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(CullTheme.surface)
            .overlay(
                Capsule().stroke(CullTheme.lineSolid, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(viewModel.undoStack.isEmpty ? 0.4 : 1)
        .disabled(viewModel.undoStack.isEmpty)
    }

    private var dotIndicator: some View {
        let total = viewModel.photos.count
        let displayed = min(total, 20)
        let current = viewModel.currentIndex

        return HStack(spacing: 6) {
            ForEach(0..<displayed, id: \.self) { i in
                let photoIndex = total <= 20
                    ? i
                    : Int(Double(i) / Double(19) * Double(total - 1))
                let isCurrent = (total <= 20 ? i == current : photoIndex == current)
                    || (i == displayed - 1 && current >= total - 1)

                dotView(index: i, photoIndex: photoIndex, isCurrent: isCurrent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .animation(.easeInOut(duration: 0.2), value: current)
    }

    private func dotView(index: Int, photoIndex: Int, isCurrent: Bool) -> some View {
        let photos = viewModel.photos
        let color: Color
        if photoIndex < viewModel.toKeep.count + viewModel.toDelete.count {
            let keptIds = Set(viewModel.toKeep.map { $0.id })
            let deletedIds = Set(viewModel.toDelete.map { $0.id })
            if photoIndex < photos.count {
                let id = photos[photoIndex].id
                if keptIds.contains(id) {
                    color = CullTheme.keep
                } else if deletedIds.contains(id) {
                    color = CullTheme.del
                } else {
                    color = CullTheme.surface2
                }
            } else {
                color = CullTheme.surface2
            }
        } else {
            color = CullTheme.surface2
        }

        return RoundedRectangle(cornerRadius: 999)
            .fill(color)
            .frame(width: isCurrent ? 16 : 4, height: 4)
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Session complete")
                .cullSans(size: 32, weight: .medium, tracking: -0.02 * 32)
                .foregroundStyle(CullTheme.text)
            Text("Reviewed \(viewModel.progress.total) photos")
                .font(.system(size: 16))
                .foregroundStyle(CullTheme.text3)
            Spacer()
            if !viewModel.toDelete.isEmpty {
                Button {
                    viewModel.showConfirmation = true
                } label: {
                    HStack {
                        Text("Review \(viewModel.toDelete.count)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(CullTheme.bg)
                        Spacer()
                        MonoLabel(text: "DELETE ↗", size: 10, tracking: 0.14 * 10, color: CullTheme.bg)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(CullTheme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            } else {
                Button {
                    viewModel.showSummary = true
                } label: {
                    HStack {
                        Text("Done")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(CullTheme.bg)
                        Spacer()
                        MonoLabel(text: "→ HOME", size: 10, tracking: 0.14 * 10, color: CullTheme.bg)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(CullTheme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }
            Spacer().frame(height: 28)
        }
    }
}

struct PhotoCardView: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(CullTheme.surface2)
                    .overlay(ProgressView().tint(CullTheme.text2))
            }
        }
        .task(id: asset.localIdentifier) {
            image = await loadImage()
        }
    }

    private func loadImage() async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 800, height: 800),
                contentMode: .aspectFill,
                options: options
            ) { img, _ in
                continuation.resume(returning: img)
            }
        }
    }
}
