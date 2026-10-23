import Combine
import Foundation

/// One session: a fixed batch of photos, one decision each, deletion at the end.
///
/// This is the whole feature. The screens read it and call it; everything that
/// is worth asserting about Rummage is assertable here, against any `PhotoSource`.
@MainActor
class SessionViewModel: ObservableObject {
    /// How many photos a session is. About two minutes, and a visible end.
    /// Deliberately a constant and not a setting — choosing is the thing the
    /// app is trying to spare you.
    static let batchSize = 50

    /// What the done screen says, and the only thing it needs to know.
    struct Summary: Equatable {
        var reviewed: Int = 0
        var deleted: Int = 0
        var bytesFreed: Int = 0
        /// False when the user left before the end of the batch.
        var completedBatch: Bool = true
        /// True when the system delete prompt was declined, so nothing went.
        var deletionDeclined: Bool = false
    }

    enum Phase: Equatable {
        case loading
        case reviewing
        case finished(Summary)
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var kept: [Photo] = []
    @Published private(set) var marked: [Photo] = []

    /// Published because the progress line, the undo affordance and which
    /// photo is on screen are all read off it.
    @Published private var decisions: [SwipeDecision] = []

    private let source: PhotoSource
    private let history: ReviewHistoryService

    init(source: PhotoSource, history: ReviewHistoryService) {
        self.source = source
        self.history = history
    }

    // MARK: - Reading a session

    var current: Photo? {
        guard decisions.count < photos.count else { return nil }
        return photos[decisions.count]
    }

    /// 1-based, for "12 of 50".
    var position: Int { min(decisions.count + 1, photos.count) }
    var total: Int { photos.count }
    var progress: Double {
        guard !photos.isEmpty else { return 0 }
        return Double(decisions.count) / Double(photos.count)
    }

    var bytesFreedSoFar: Int { StorageEstimate.bytes(for: marked) }
    /// Whether this session has anything to show for itself yet.
    var hasDecisions: Bool { !decisions.isEmpty }
    var canUndo: Bool { hasDecisions }
    var isReviewing: Bool { phase == .reviewing }

    // MARK: - Running a session

    func start() async {
        phase = .loading
        photos = await source.sessionBatch(limit: Self.batchSize, excluding: history.keptIDs)
        kept = []
        marked = []
        decisions = []
        phase = photos.isEmpty ? .finished(Summary()) : .reviewing
    }

    func keep() async {
        await decide(.keep)
    }

    func delete() async {
        await decide(.delete)
    }

    func undo() {
        guard isReviewing, let decision = decisions.popLast() else { return }
        let photo = photos[decisions.count]
        switch decision {
        case .keep:
            kept.removeAll { $0 == photo }
            history.unmarkKept(photo.id)
        case .delete:
            marked.removeAll { $0 == photo }
        }
    }

    /// Leaving part-way through. The photos already marked still go — the work
    /// is not wasted — and the done screen says the session was cut short.
    func endEarly() async {
        guard isReviewing else { return }
        await finish(completedBatch: false)
    }

    private func decide(_ decision: SwipeDecision) async {
        guard isReviewing, let photo = current else { return }
        switch decision {
        case .keep:
            kept.append(photo)
            history.markKept(photo.id)
        case .delete:
            marked.append(photo)
        }
        decisions.append(decision)
        Haptics.tap(for: decision)

        if decisions.count >= photos.count {
            await finish(completedBatch: true)
        }
    }

    /// Deletion happens once, here, however the session ended. Up to this point
    /// nothing has left the library.
    private func finish(completedBatch: Bool) async {
        // Out of `.reviewing` before waiting on the system prompt, so a decision
        // or a second exit that lands meanwhile is turned away by the guards.
        phase = .loading
        let reviewed = decisions.count
        var declined = false
        if !marked.isEmpty {
            do {
                try await source.delete(marked)
            } catch {
                declined = true
            }
        }

        let bytes = declined ? 0 : StorageEstimate.bytes(for: marked)
        if !declined, !marked.isEmpty {
            history.recordDeletions(count: marked.count, bytes: bytes)
        }

        phase = .finished(Summary(
            reviewed: reviewed,
            deleted: declined ? 0 : marked.count,
            bytesFreed: bytes,
            completedBatch: completedBatch,
            deletionDeclined: declined
        ))
    }
}
