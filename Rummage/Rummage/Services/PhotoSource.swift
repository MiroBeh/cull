import Foundation

/// Everything a session needs from the photo library, and nothing else.
///
/// The session view model talks to the library only through this, so the tests
/// can hand it an in-memory library and never touch PhotoKit.
protocol PhotoSource {
    /// Up to `limit` photos not in `keptIDs`, in no particular order. Fewer
    /// than `limit` means that is all there is left.
    func sessionBatch(limit: Int, excluding keptIDs: Set<String>) async -> [Photo]

    /// How many photos are not in `keptIDs`.
    func unreviewedCount(excluding keptIDs: Set<String>) async -> Int

    /// Moves the photos to Recently Deleted. iOS asks the user to confirm, and
    /// throws if they decline.
    func delete(_ photos: [Photo]) async throws
}
