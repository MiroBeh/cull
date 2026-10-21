import Foundation
import Combine

/// Remembers which photos the user said "keep" to, so a later session does not
/// offer them again — for 90 days, after which a photo is worth reconsidering.
/// Also keeps the lifetime counters the home and settings screens show.
class ReviewHistoryService: ObservableObject {
    @Published private(set) var keptCount: Int = 0
    @Published private(set) var photosCulled: Int = 0
    @Published private(set) var storageFreedBytes: Int = 0

    private let userDefaultsKey = "cull.reviewHistory"
    private let photosCulledKey = "cull.lifetime.photosCulled"
    private let storageFreedKey = "cull.lifetime.storageFreedBytes"
    private let ttl: TimeInterval = 90 * 24 * 60 * 60
    private let defaults: UserDefaults
    private let now: () -> Date
    private var entries: [String: Date] = [:]

    /// `defaults` and `now` are injected so the tests can run against their own
    /// storage and step over the 90-day expiry without waiting for it.
    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        load()
        pruneExpired()
        photosCulled = defaults.integer(forKey: photosCulledKey)
        storageFreedBytes = defaults.integer(forKey: storageFreedKey)
    }

    func recordDeletions(count: Int, bytes: Int) {
        photosCulled += count
        storageFreedBytes += bytes
        defaults.set(photosCulled, forKey: photosCulledKey)
        defaults.set(storageFreedBytes, forKey: storageFreedKey)
    }

    func markKept(_ id: String) {
        entries[id] = now()
        persist()
        keptCount = entries.count
    }

    func unmarkKept(_ id: String) {
        entries.removeValue(forKey: id)
        persist()
        keptCount = entries.count
    }

    func isKept(_ id: String) -> Bool {
        guard let keptAt = entries[id] else { return false }
        return now().timeIntervalSince(keptAt) < ttl
    }

    func pruneExpired() {
        let moment = now()
        entries = entries.filter { _, keptAt in
            moment.timeIntervalSince(keptAt) < ttl
        }
        persist()
        keptCount = entries.count
    }

    func reset() {
        entries = [:]
        persist()
        keptCount = 0
        photosCulled = 0
        storageFreedBytes = 0
        defaults.removeObject(forKey: photosCulledKey)
        defaults.removeObject(forKey: storageFreedKey)
    }

    private func load() {
        guard let data = defaults.data(forKey: userDefaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            entries = decoded.mapValues { Date(timeIntervalSince1970: $0) }
            keptCount = entries.count
        }
    }

    private func persist() {
        let encoded = entries.mapValues { $0.timeIntervalSince1970 }
        if let data = try? JSONEncoder().encode(encoded) {
            defaults.set(data, forKey: userDefaultsKey)
        }
    }
}
