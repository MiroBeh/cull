import Photos
import SwiftUI
import Combine

class PhotoLibraryService: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        return status == .authorized || status == .limited
    }

    func fetchPhotos(limit: Int = 500) async -> [Photo] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.fetchLimit = limit

        let result = PHAsset.fetchAssets(with: options)
        var photos: [Photo] = []
        result.enumerateObjects { asset, _, _ in
            photos.append(Photo(asset: asset))
        }
        return photos
    }

    func deletePhotos(_ photos: [Photo]) async throws {
        let assets = photos.map { $0.asset }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }
}
