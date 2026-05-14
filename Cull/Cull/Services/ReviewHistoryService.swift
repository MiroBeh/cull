import Foundation
import Combine

class ReviewHistoryService: ObservableObject {
    @Published private(set) var keptCount: Int = 0
    @Published private(set) var photosCulled: Int = 0
    @Published private(set) var storageFreedBytes: Int = 0

    private let userDefaultsKey = "cull.reviewHistory"
    private let photosCulledKey = "cull.lifetime.photosCulled"
    private let storageFreedKey = "cull.lifetime.storageFreedBytes"
    private let ttl: TimeInterval = 90 * 24 * 60 * 60
    private var entries: [String: Date] = [:]

    init() {
        load()
        pruneExpired()
        photosCulled = UserDefaults.standard.integer(forKey: photosCulledKey)
        storageFreedBytes = UserDefaults.standard.integer(forKey: storageFreedKey)
    }

    func recordDeletions(count: Int, bytes: Int) {
        photosCulled += count
        storageFreedBytes += bytes
        UserDefaults.standard.set(photosCulled, forKey: photosCulledKey)
        UserDefaults.standard.set(storageFreedBytes, forKey: storageFreedKey)
    }

    func markKept(_ id: String) {
        entries[id] = Date()
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
        return Date().timeIntervalSince(keptAt) < ttl
    }

    func filterUnreviewed(_ photos: [Photo]) -> [Photo] {
        photos.filter { !isKept($0.id) }
    }

    func pruneExpired() {
        let now = Date()
        entries = entries.filter { _, keptAt in
            now.timeIntervalSince(keptAt) < ttl
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
        UserDefaults.standard.removeObject(forKey: photosCulledKey)
        UserDefaults.standard.removeObject(forKey: storageFreedKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            entries = decoded.mapValues { Date(timeIntervalSince1970: $0) }
            keptCount = entries.count
        }
    }

    private func persist() {
        let encoded = entries.mapValues { $0.timeIntervalSince1970 }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
