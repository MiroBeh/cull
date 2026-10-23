import Foundation
import Testing
@testable import Rummage

/// Everything the feature is, driven through the session view model.
///
/// Each test states something a user would notice. Nothing here knows which
/// method got called or what a screen looks like, so the screens can be rebuilt
/// without touching this file.
@MainActor
struct SessionTests {

    // MARK: - Helpers

    /// A history service with its own storage and its own clock, so tests
    /// neither see each other's kept photos nor wait 90 days.
    private func makeHistory(now: @escaping () -> Date = { .distantPast }) -> ReviewHistoryService {
        let suite = "RummageTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return ReviewHistoryService(defaults: defaults, now: now)
    }

    private func makeSession(
        photos: Int,
        history: ReviewHistoryService
    ) async -> (SessionViewModel, InMemoryPhotoLibrary) {
        let library = InMemoryPhotoLibrary(count: photos)
        let session = SessionViewModel(source: library, history: history)
        await session.start()
        return (session, library)
    }

    // MARK: - The size of a session

    @Test func aSessionIsFiftyPhotos() async {
        let (session, _) = await makeSession(photos: 400, history: makeHistory())

        #expect(session.total == 50)
        #expect(session.phase == .reviewing)
    }

    @Test func aLibraryWithLessLeftGivesAShorterSession() async {
        let (session, _) = await makeSession(photos: 12, history: makeHistory())

        #expect(session.total == 12)
        #expect(session.phase == .reviewing)
    }

    @Test func aFullyReviewedLibraryGivesNoSessionAtAll() async {
        let (session, _) = await makeSession(photos: 0, history: makeHistory())

        #expect(session.total == 0)
        #expect(session.phase == .finished(SessionViewModel.Summary()))
    }

    // MARK: - Deciding

    @Test func keepAndDeleteSortThePhotosAndMoveOn() async {
        let history = makeHistory()
        let (session, _) = await makeSession(photos: 10, history: history)
        let first = session.current
        let second = session.photos[1]

        await session.delete()
        #expect(session.current == second)

        await session.keep()

        #expect(session.marked == [first])
        #expect(history.isKept(second.id))
        #expect(session.position == 3)
    }

    @Test func nothingLeavesTheLibraryUntilTheSessionEnds() async {
        let history = makeHistory()
        let (session, library) = await makeSession(photos: 10, history: history)

        await session.delete()
        await session.delete()

        #expect(library.deleted.isEmpty)
        #expect(session.marked.count == 2)
    }

    @Test func aKeptPhotoIsRememberedAsSoonAsItIsKept() async {
        let history = makeHistory()
        let (session, _) = await makeSession(photos: 10, history: history)
        let photo = session.current!

        await session.keep()

        #expect(history.isKept(photo.id))
    }

    // MARK: - Undo

    @Test func undoPutsTheKeptPhotoBackAndForgetsIt() async {
        let history = makeHistory()
        let (session, _) = await makeSession(photos: 10, history: history)
        let photo = session.current!

        await session.keep()
        session.undo()

        #expect(session.current == photo)
        #expect(history.isKept(photo.id) == false)
        #expect(session.position == 1)
    }

    @Test func undoTakesBackADeletion() async {
        let history = makeHistory()
        let (session, library) = await makeSession(photos: 10, history: history)
        let photo = session.current!

        await session.delete()
        session.undo()

        #expect(session.current == photo)
        #expect(session.marked.isEmpty)
        #expect(session.bytesFreedSoFar == 0)
        #expect(library.deleted.isEmpty)
    }

    @Test func undoAtTheStartOfASessionDoesNothing() async {
        let (session, _) = await makeSession(photos: 10, history: makeHistory())
        let photo = session.current

        #expect(session.canUndo == false)
        session.undo()

        #expect(session.current == photo)
        #expect(session.position == 1)
        #expect(session.phase == .reviewing)
    }

    // MARK: - Finishing

    @Test func theSessionIsCompleteExactlyAtTheEndOfTheBatch() async {
        let history = makeHistory()
        let (session, _) = await makeSession(photos: 60, history: history)

        for _ in 0..<(SessionViewModel.batchSize - 1) {
            await session.keep()
        }
        #expect(session.phase == .reviewing)

        await session.keep()

        #expect(session.phase == .finished(SessionViewModel.Summary(
            reviewed: 50,
            deleted: 0,
            bytesFreed: 0,
            completedBatch: true
        )))
    }

    @Test func finishingDeletesTheMarkedPhotosAndNothingElse() async {
        let history = makeHistory()
        let (session, library) = await makeSession(photos: 50, history: history)
        var expected: [Photo] = []

        for index in 0..<50 {
            if index.isMultiple(of: 2) {
                expected.append(session.current!)
                await session.delete()
            } else {
                await session.keep()
            }
        }

        #expect(library.deleted == expected)
        #expect(library.photos.count == 25)
        #expect(session.phase == .finished(SessionViewModel.Summary(
            reviewed: 50,
            deleted: 25,
            bytesFreed: StorageEstimate.bytes(for: expected),
            completedBatch: true
        )))
    }

    @Test func leavingEarlyStillDeletesWhatWasDecided() async {
        let history = makeHistory()
        let (session, library) = await makeSession(photos: 50, history: history)
        let doomed = [session.photos[0], session.photos[2]]

        await session.delete()
        await session.keep()
        await session.delete()
        await session.endEarly()

        #expect(library.deleted == doomed)
        #expect(session.phase == .finished(SessionViewModel.Summary(
            reviewed: 3,
            deleted: 2,
            bytesFreed: StorageEstimate.bytes(for: doomed),
            completedBatch: false
        )))
    }

    /// While iOS asks to confirm, a swipe still in flight or a second tap on
    /// the exit must not change what was sent, or what the totals say went.
    @Test func nothingCountsThatLandsWhileTheDeletePromptIsUp() async {
        let history = makeHistory()
        let (session, library) = await makeSession(photos: 10, history: history)
        library.holdsPrompt = true
        let doomed = [session.photos[0]]

        await session.delete()
        let ending = Task { await session.endEarly() }
        while !library.isPromptShowing { await Task.yield() }

        await session.delete()
        await session.keep()
        session.undo()
        await session.endEarly()
        library.answerPrompt()
        await ending.value

        #expect(library.deleteCalls == 1)
        #expect(library.deleted == doomed)
        #expect(history.photosDeleted == 1)
        #expect(history.keptCount == 0)
        #expect(session.phase == .finished(SessionViewModel.Summary(
            reviewed: 1,
            deleted: 1,
            bytesFreed: StorageEstimate.bytes(for: doomed),
            completedBatch: false
        )))
    }

    @Test func decliningTheSystemPromptLeavesTheLibraryAndTheCountersAlone() async {
        let history = makeHistory()
        let (session, library) = await makeSession(photos: 10, history: history)
        library.refusesDeletion = true

        await session.delete()
        await session.endEarly()

        #expect(library.deleted.isEmpty)
        #expect(library.photos.count == 10)
        #expect(history.photosDeleted == 0)
        #expect(history.storageFreedBytes == 0)
        #expect(session.phase == .finished(SessionViewModel.Summary(
            reviewed: 1,
            deleted: 0,
            bytesFreed: 0,
            completedBatch: false,
            deletionDeclined: true
        )))
    }

    // MARK: - What adds up over time

    @Test func theFreedFigureIsTheSameOnEveryScreenThatShowsIt() async {
        let history = makeHistory()
        let (session, _) = await makeSession(photos: 10, history: history)

        await session.delete()
        await session.delete()
        let duringSession = session.bytesFreedSoFar
        await session.endEarly()

        guard case .finished(let summary) = session.phase else {
            Issue.record("the session did not finish")
            return
        }
        #expect(duringSession == summary.bytesFreed)
        #expect(history.storageFreedBytes == summary.bytesFreed)
    }

    @Test func theLifetimeCountersAddUpAcrossSessions() async {
        let history = makeHistory()
        let library = InMemoryPhotoLibrary(count: 10)
        let session = SessionViewModel(source: library, history: history)

        await session.start()
        await session.delete()
        await session.endEarly()
        let afterFirst = history.storageFreedBytes

        await session.start()
        await session.delete()
        await session.delete()
        await session.endEarly()

        #expect(history.photosDeleted == 3)
        #expect(history.storageFreedBytes == afterFirst * 3)
        #expect(library.photos.count == 7)
    }

    // MARK: - What a later session offers

    @Test func keptPhotosDoNotComeRoundAgain() async {
        let history = makeHistory()
        let library = InMemoryPhotoLibrary(count: 8)
        let session = SessionViewModel(source: library, history: history)

        await session.start()
        for _ in 0..<8 { await session.keep() }

        await session.start()

        #expect(session.total == 0)
        #expect(session.phase == .finished(SessionViewModel.Summary()))
    }

    @Test func keptPhotosComeBackAfterNinetyDays() async {
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let history = makeHistory(now: { now })
        let library = InMemoryPhotoLibrary(count: 8)
        let session = SessionViewModel(source: library, history: history)

        await session.start()
        for _ in 0..<8 { await session.keep() }

        now = now.addingTimeInterval(89 * 24 * 60 * 60)
        await session.start()
        #expect(session.total == 0)

        now = now.addingTimeInterval(2 * 24 * 60 * 60)
        await session.start()

        #expect(session.total == 8)
        #expect(session.phase == .reviewing)
    }
}
