import Foundation
import Photos

/// A photo as a session cares about it: an identity, a date, a pixel count.
///
/// The `PHAsset` it came from rides along so the review screen can load an
/// image and the share sheet can hand over the original, but none of the
/// session logic touches it — which is what lets the tests build photos
/// without PhotoKit.
nonisolated struct Photo: Identifiable, Hashable {
    let id: String
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let asset: PHAsset?

    init(
        id: String,
        creationDate: Date? = nil,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0,
        asset: PHAsset? = nil
    ) {
        self.id = id
        self.creationDate = creationDate
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.asset = asset
    }

    init(asset: PHAsset) {
        self.init(
            id: asset.localIdentifier,
            creationDate: asset.creationDate,
            pixelWidth: asset.pixelWidth,
            pixelHeight: asset.pixelHeight,
            asset: asset
        )
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }
}

enum SwipeDecision {
    case keep, delete
}
