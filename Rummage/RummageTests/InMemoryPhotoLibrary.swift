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
    func sessionBatch(limit: Int, excluding keptIDs: Set<String>) async -> [Photo] {
        Array(unreviewed(excluding: keptIDs).prefix(limit))
    }

    func unreviewedCount(excluding keptIDs: Set<String>) async -> Int {
        unreviewed(excluding: keptIDs).count
    }

    /// Set when the test needs the system delete prompt to stay up: `delete`
    /// waits until the test calls `answerPrompt()`.
    var holdsPrompt = false
    private(set) var deleteCalls = 0
    private var prompt: CheckedContinuation<Void, Never>?

    var isPromptShowing: Bool { prompt != nil }

    func answerPrompt() {
        prompt?.resume()
        prompt = nil
    }

    func delete(_ photos: [Photo]) async throws {
        deleteCalls += 1
        // Only one prompt is held, so a second call fails the test, not hangs it.
        if holdsPrompt, prompt == nil {
            await withCheckedContinuation { prompt = $0 }
        }
        if refusesDeletion { throw Failure.declined }
        deleted.append(contentsOf: photos)
        self.photos.removeAll { photos.contains($0) }
    }

    private func unreviewed(excluding keptIDs: Set<String>) -> [Photo] {
        photos.filter { !keptIDs.contains($0.id) }
    }
}
