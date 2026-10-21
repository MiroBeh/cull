import Foundation

/// Everything a session needs from the photo library, and nothing else.
///
/// The session view model talks to the library only through this, so the tests
/// can hand it an in-memory library and never touch PhotoKit.
protocol PhotoSource {
    /// Up to `limit` photos the user has not reviewed yet, in no particular
    /// order. Fewer than `limit` means that is all there is left.
    func sessionBatch(limit: Int, history: ReviewHistoryService) async -> [Photo]

    /// How many photos the user has not reviewed yet.
    func unreviewedCount(history: ReviewHistoryService) async -> Int

    /// Moves the photos to Recently Deleted. iOS asks the user to confirm, and
    /// throws if they decline.
    func delete(_ photos: [Photo]) async throws
}
