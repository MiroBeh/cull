import CoreTransferable
import ImageIO
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
/// card's thumbnail, so whoever receives it gets the photo — but not where it
/// was taken. Sharing an old photo you came across should not also send your
/// home address, so the location is always removed; there is no toggle.
struct SharablePhoto: Transferable {
    let photo: Photo

    enum Failure: Error { case noImageData, couldNotRemoveLocation }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .image) { sharable in
            guard let data = await PhotoLibraryService.imageData(for: sharable.photo) else {
                throw Failure.noImageData
            }
            // Fails closed: a photo that cannot be cleaned is not shared.
            guard let cleaned = removingLocation(from: data) else {
                throw Failure.couldNotRemoveLocation
            }
            return cleaned
        }
    }

    /// The same image with its GPS metadata — EXIF and XMP — dropped.
    ///
    /// Copies the image source rather than re-encoding it, so the pixels are
    /// untouched. Only if the copy fails, or still has a location in it, is the
    /// image decoded and written again with no metadata but its orientation.
    /// Nil if neither works.
    static func removingLocation(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source)
        else { return nil }

        // ImageIO only drops GPS when the metadata is handed back explicitly
        // and replaces, rather than merges with, what the source carries.
        let copied = NSMutableData()
        if let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil),
           let destination = CGImageDestinationCreateWithData(copied, type, 1, nil) {
            let options: [CFString: Any] = [
                kCGImageDestinationMetadata: metadata,
                kCGImageDestinationMergeMetadata: false,
                kCGImageMetadataShouldExcludeGPS: true,
            ]
            if CGImageDestinationCopyImageSource(destination, source, options as CFDictionary, nil),
               !hasLocation(copied as Data) {
                return copied as Data
            }
        }

        let reencoded = NSMutableData()
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let destination = CGImageDestinationCreateWithData(reencoded, type, 1, nil)
        else { return nil }
        let original = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        var properties: [CFString: Any] = [:]
        properties[kCGImagePropertyOrientation] = original?[kCGImagePropertyOrientation]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination), !hasLocation(reencoded as Data) else {
            return nil
        }
        return reencoded as Data
    }

    private static func hasLocation(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return true }
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        return properties?[kCGImagePropertyGPSDictionary] != nil
    }
}
