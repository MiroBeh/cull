import SwiftUI
import UIKit
import Combine

struct UndoEntry {
    let photo: Photo
    let decision: SwipeDecision
}

class CullViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var currentIndex: Int = 0
    @Published var toDelete: [Photo] = []
    @Published var toKeep: [Photo] = []
    @Published var undoStack: [UndoEntry] = []
    @Published var isLoading: Bool = false
    @Published var showConfirmation: Bool = false
    @Published var showSummary: Bool = false
    @Published var error: Error? = nil

    private var historyService: ReviewHistoryService?

    var currentPhoto: Photo? {
        guard currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }

    var progress: (reviewed: Int, total: Int) {
        (currentIndex, photos.count)
    }

    var isComplete: Bool {
        !photos.isEmpty && currentIndex >= photos.count
    }

    func loadPhotos(using service: PhotoLibraryService, history: ReviewHistoryService, filter: SessionFilter) async {
        self.historyService = history
        isLoading = true
        photos = await service.fetchPhotos(filter: filter, history: history)
        currentIndex = 0
        toDelete = []
        toKeep = []
        undoStack = []
        isLoading = false
    }

    func swipeRight() {
        guard let photo = currentPhoto else { return }
        toKeep.append(photo)
        pushUndo(photo: photo, decision: .keep)
        historyService?.markKept(photo.id)
        currentIndex += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        checkCompletion()
    }

    func swipeLeft() {
        guard let photo = currentPhoto else { return }
        toDelete.append(photo)
        pushUndo(photo: photo, decision: .delete)
        currentIndex += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        checkCompletion()
    }

    func undo() {
        guard !undoStack.isEmpty, currentIndex > 0 else { return }
        let last = undoStack.removeLast()
        currentIndex -= 1
        switch last.decision {
        case .keep:
            toKeep.removeLast()
            historyService?.unmarkKept(last.photo.id)
        case .delete:
            toDelete.removeLast()
        }
    }

    func endSessionEarly() {
        if !toDelete.isEmpty {
            showConfirmation = true
        } else {
            showSummary = true
        }
    }

    func confirmDeletion(using service: PhotoLibraryService) async {
        do {
            try await service.deletePhotos(toDelete)
            showConfirmation = false
            showSummary = true
        } catch {
            self.error = error
        }
    }

    func storageSavedEstimate() -> String {
        let mb = Double(toDelete.count) * 4.0
        return mb >= 1024 ? String(format: "~%.1f GB", mb / 1024) : String(format: "~%.0f MB", mb)
    }

    func reset() {
        photos = []
        currentIndex = 0
        toDelete = []
        toKeep = []
        undoStack = []
        isLoading = false
        showConfirmation = false
        showSummary = false
        error = nil
    }

    private func pushUndo(photo: Photo, decision: SwipeDecision) {
        undoStack.append(UndoEntry(photo: photo, decision: decision))
        if undoStack.count > 50 { undoStack.removeFirst() }
    }

    private func checkCompletion() {
        if isComplete && !toDelete.isEmpty {
            showConfirmation = true
        } else if isComplete {
            showSummary = true
        }
    }
}
