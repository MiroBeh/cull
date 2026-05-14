import SwiftUI
import Photos

struct ConfirmationView: View {
    @EnvironmentObject var viewModel: CullViewModel
    @EnvironmentObject var photoService: PhotoLibraryService
    @Environment(\.dismiss) private var dismiss
    @State private var isDeleting = false

    var body: some View {
        ZStack {
            CullTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                thumbnailList
                Spacer()
                ctaButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
            }

            if isDeleting {
                deletingOverlay
            }
        }
        .preferredColorScheme(.dark)
        .padding(.top, 54)
        .ignoresSafeArea(edges: .top)
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )
        ) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            IconPillButton(systemName: "xmark") {
                viewModel.showConfirmation = false
            }
            Spacer()
            Text("Delete \(viewModel.toDelete.count) Photos")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CullTheme.text)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var thumbnailList: some View {
        ScrollView {
            SurfaceGroup {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.toDelete.enumerated()), id: \.element.id) { index, photo in
                        confirmationThumbnailRow(photo: photo)
                        if index < viewModel.toDelete.count - 1 {
                            Hairline()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func confirmationThumbnailRow(photo: Photo) -> some View {
        HStack(spacing: 12) {
            ConfirmationThumbnail(asset: photo.asset)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                if let date = photo.asset.creationDate {
                    MonoLabel(
                        text: Self.dateFmt.string(from: date),
                        size: 11,
                        tracking: 0.08 * 11,
                        color: CullTheme.text2
                    )
                }
                let w = photo.asset.pixelWidth
                let h = photo.asset.pixelHeight
                MonoLabel(
                    text: "\(w)×\(h)",
                    size: 9,
                    tracking: 0.14 * 9,
                    color: CullTheme.text4
                )
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 56)
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    private var ctaButtons: some View {
        VStack(spacing: 8) {
            Button {
                Task { await runDeletion() }
            } label: {
                HStack {
                    Text("Delete \(viewModel.toDelete.count)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(CullTheme.text)
                    Spacer()
                    MonoLabel(text: "→", size: 14, tracking: 0, color: CullTheme.text)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(CullTheme.del)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)

            Button {
                viewModel.showConfirmation = false
            } label: {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CullTheme.text2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(CullTheme.lineSolid, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var deletingOverlay: some View {
        ZStack {
            CullTheme.surface.opacity(0.9)
                .ignoresSafeArea()
            ProgressView("Deleting…")
                .foregroundStyle(CullTheme.text2)
                .padding(20)
                .background(CullTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CullTheme.lineSolid, lineWidth: 1)
                )
        }
    }

    private func runDeletion() async {
        isDeleting = true
        await viewModel.confirmDeletion(using: photoService)
        isDeleting = false
    }
}

struct ConfirmationThumbnail: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(CullTheme.surface2)
                    .overlay(ProgressView().tint(CullTheme.text2))
            }
        }
        .task(id: asset.localIdentifier) {
            thumbnail = await loadThumbnail()
        }
    }

    private func loadThumbnail() async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 120, height: 120),
                contentMode: .aspectFill,
                options: options
            ) { img, _ in
                continuation.resume(returning: img)
            }
        }
    }
}
