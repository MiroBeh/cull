import SwiftUI
import Photos

struct CullView: View {
    let filter: SessionFilter
    @EnvironmentObject var viewModel: CullViewModel
    @EnvironmentObject var photoService: PhotoLibraryService
    @EnvironmentObject var historyService: ReviewHistoryService
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            if viewModel.isLoading {
                ProgressView("Loading photos…")
            } else if viewModel.isComplete {
                completionView
            } else if let photo = viewModel.currentPhoto {
                VStack(spacing: 16) {
                    Spacer()
                    photoCard(photo: photo)
                    Spacer()
                    bottomBar
                }
                .padding()
            } else {
                Text("No photos found").foregroundStyle(.secondary)
            }
        }
        .navigationTitle(filter.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.isLoading && !viewModel.isComplete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End") {
                        viewModel.endSessionEarly()
                    }
                    .disabled(viewModel.currentIndex == 0)
                }
            }
        }
        .task(id: filter) {
            await viewModel.loadPhotos(using: photoService, history: historyService, filter: filter)
        }
    }

    private func photoCard(photo: Photo) -> some View {
        PhotoCardView(asset: photo.asset)
            .frame(maxWidth: 360)
            .frame(height: 420)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 8)
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width) / 20))
            .overlay(swipeIndicatorOverlay)
            .gesture(swipeGesture)
            .animation(.interactiveSpring(), value: dragOffset)
    }

    private var swipeIndicatorOverlay: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
                .opacity(dragOffset.width < -30 ? min(1, Double(-dragOffset.width) / 100) : 0)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .opacity(dragOffset.width > 30 ? min(1, Double(dragOffset.width) / 100) : 0)
        }
        .padding(28)
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
        let predictedX = value.predictedEndTranslation.width
        if predictedX > 120 || value.translation.width > 120 {
            withAnimation(.easeOut(duration: 0.25)) {
                dragOffset = CGSize(width: 600, height: value.translation.height)
            }
            Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                viewModel.swipeRight()
                dragOffset = .zero
            }
        } else if predictedX < -120 || value.translation.width < -120 {
            withAnimation(.easeOut(duration: 0.25)) {
                dragOffset = CGSize(width: -600, height: value.translation.height)
            }
            Task {
                try? await Task.sleep(nanoseconds: 250_000_000)
                viewModel.swipeLeft()
                dragOffset = .zero
            }
        } else {
            withAnimation(.spring()) { dragOffset = .zero }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            chipRow
            ProgressView(value: Double(viewModel.progress.reviewed),
                         total: max(1, Double(viewModel.progress.total)))
                .tint(Color.accentColor)
            Text("\(viewModel.progress.reviewed) of \(viewModel.progress.total) reviewed")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Undo") { viewModel.undo() }
                .disabled(viewModel.undoStack.isEmpty)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private var chipRow: some View {
        if viewModel.toKeep.count > 0 || viewModel.toDelete.count > 0 {
            HStack(spacing: 8) {
                if viewModel.toKeep.count > 0 {
                    statChip(symbol: "checkmark.circle.fill", color: .green,
                             text: "\(viewModel.toKeep.count) kept")
                }
                if viewModel.toDelete.count > 0 {
                    statChip(symbol: "trash.fill", color: .red,
                             text: "\(viewModel.toDelete.count) to delete")
                }
            }
        }
    }

    private func statChip(symbol: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(text)
                .foregroundStyle(color)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.15)))
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("All Done!")
                .font(.title.bold())
            Text("Reviewed \(viewModel.progress.total) photos")
                .foregroundStyle(.secondary)
            if !viewModel.toDelete.isEmpty {
                Button("Review \(viewModel.toDelete.count) Photos to Delete") {
                    viewModel.showConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button("Done") { viewModel.showSummary = true }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
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
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(ProgressView())
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
