import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// The quiet button under the photo. It opens the system share sheet — the real
/// one, so Messages, AirDrop, Mail and everything else the user already has is
/// there — and records no decision: dismissing it leaves the same photo on
/// screen, undecided.
struct SharePhotoButton: View {
    let photo: Photo
    let title: String

    var body: some View {
        ShareLink(
            item: SharablePhoto(photo: photo),
            preview: SharePreview(title)
        ) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .regular))
                Text("Share")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(CullTheme.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(CullTheme.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(CullTheme.lineSolid, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// A photo on its way to the share sheet: the full-size image data, not the
/// card's thumbnail, so whoever receives it gets the photo.
struct SharablePhoto: Transferable {
    let photo: Photo

    enum Failure: Error { case noImageData }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .image) { sharable in
            guard let data = await PhotoLibraryService.imageData(for: sharable.photo) else {
                throw Failure.noImageData
            }
            return data
        }
    }
}
