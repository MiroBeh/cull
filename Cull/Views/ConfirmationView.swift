import SwiftUI
import Photos

struct ConfirmationView: View {
    @EnvironmentObject var viewModel: CullViewModel
    @EnvironmentObject var photoService: PhotoLibraryService
    @Environment(\.dismiss) private var dismiss
    @State private var isDeleting = false

    var body: some View {
        NavigationStack {
            List(viewModel.toDelete) { photo in
                ThumbnailRow(asset: photo.asset)
            }
            .navigationTitle("Delete \(viewModel.toDelete.count) Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Delete", role: .destructive) {
                        Task { await runDeletion() }
                    }
                    .disabled(isDeleting)
                    .tint(.red)
                }
            }
            .overlay {
                if isDeleting {
                    ProgressView("Deleting…")
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }

    private func runDeletion() async {
        isDeleting = true
        await viewModel.confirmDeletion(using: photoService)
        isDeleting = false
    }
}

struct ThumbnailRow: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.systemGray5).overlay(ProgressView())
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if let date = asset.creationDate {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)
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
