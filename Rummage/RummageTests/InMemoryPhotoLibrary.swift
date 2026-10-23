import Foundation
@testable import Rummage

/// A photo library that is just an array, so the tests can drive a whole
/// session without PhotoKit, a simulator library or a device.
final class InMemoryPhotoLibrary: PhotoSource {
    private(set) var photos: [Photo]
    private(set) var deleted: [Photo] = []

    /// Set when the test needs the system delete prompt to be declined.
    var refusesDeletion = false

    enum Failure: Error { case declined }

    init(photos: [Photo]) {
        self.photos = photos
    }

    /// `count` photos of the same size, so what a test expects to be freed is
    /// arithmetic rather than a fixture.
    convenience init(count: Int, pixelWidth: Int = 4032, pixelHeight: Int = 3024) {
        self.init(photos: (0..<count).map { index in
            Photo(
                id: "photo-\(index)",
                creationDate: Date(timeIntervalSince1970: 1_700_000_000 + Double(index) * 3600),
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight
            )
        })
    }

    /// Unshuffled: which photos come back is the real service's business, and a
    /// test that depended on the order would be testing `shuffled()`.
    func sessionBatch(limit: Int, history: ReviewHistoryService) async -> [Photo] {
        Array(unreviewed(history: history).prefix(limit))
    }

    func unreviewedCount(history: ReviewHistoryService) async -> Int {
        unreviewed(history: history).count
    }

    func delete(_ photos: [Photo]) async throws {
        if refusesDeletion { throw Failure.declined }
        deleted.append(contentsOf: photos)
        self.photos.removeAll { photos.contains($0) }
    }

    private func unreviewed(history: ReviewHistoryService) -> [Photo] {
        photos.filter { !history.isKept($0.id) }
    }
}
