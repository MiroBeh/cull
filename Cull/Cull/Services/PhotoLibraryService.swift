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

    func fetchPhotos(filter: SessionFilter, history: ReviewHistoryService, limit: Int = 500) async -> [Photo] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit

        var photos: [Photo] = []

        switch filter {
        case .all:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let result = PHAsset.fetchAssets(with: options)
            result.enumerateObjects { asset, _, _ in
                photos.append(Photo(asset: asset))
            }

        case .month(let year, let month):
            let cal = Calendar.current
            var startComps = DateComponents()
            startComps.year = year
            startComps.month = month
            startComps.day = 1
            guard let start = cal.date(from: startComps),
                  let end = cal.date(byAdding: .month, value: 1, to: start) else {
                return []
            }
            options.predicate = NSPredicate(
                format: "mediaType == %d AND creationDate >= %@ AND creationDate < %@",
                PHAssetMediaType.image.rawValue,
                start as NSDate,
                end as NSDate
            )
            let result = PHAsset.fetchAssets(with: options)
            result.enumerateObjects { asset, _, _ in
                photos.append(Photo(asset: asset))
            }

        case .album(let localId, _):
            let collections = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [localId],
                options: nil
            )
            guard let collection = collections.firstObject else { return [] }
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let result = PHAsset.fetchAssets(in: collection, options: options)
            result.enumerateObjects { asset, _, _ in
                photos.append(Photo(asset: asset))
            }
        }

        return history.filterUnreviewed(photos)
    }

    func fetchAlbums() async -> [PHAssetCollection] {
        var albums: [PHAssetCollection] = []
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        userAlbums.enumerateObjects { collection, _, _ in
            if collection.localizedTitle != nil {
                albums.append(collection)
            }
        }
        return albums.sorted { ($0.localizedTitle ?? "") < ($1.localizedTitle ?? "") }
    }

    func fetchMonthBuckets(history: ReviewHistoryService) async -> [MonthBucket] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let result = PHAsset.fetchAssets(with: options)
        let cal = Calendar.current

        struct BucketKey: Hashable { let year: Int; let month: Int }
        var totals: [BucketKey: Int] = [:]
        var unreviewed: [BucketKey: Int] = [:]

        result.enumerateObjects { asset, _, _ in
            guard let date = asset.creationDate else { return }
            let comps = cal.dateComponents([.year, .month], from: date)
            guard let y = comps.year, let m = comps.month else { return }
            let key = BucketKey(year: y, month: m)
            totals[key, default: 0] += 1
            if !history.isKept(asset.localIdentifier) {
                unreviewed[key, default: 0] += 1
            }
        }

        return totals
            .compactMap { key, total -> MonthBucket? in
                let u = unreviewed[key] ?? 0
                guard u > 0 else { return nil }
                return MonthBucket(year: key.year, month: key.month, totalCount: total, unreviewedCount: u)
            }
            .sorted { ($0.year, $0.month) > ($1.year, $1.month) }
    }

    func deletePhotos(_ photos: [Photo]) async throws {
        let assets = photos.map { $0.asset }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }
}
