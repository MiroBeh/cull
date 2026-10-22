//
//  CullApp.swift
//  Cull
//
//  Created by Miro Behninger on 13.05.26.
//

import SwiftUI

@main
struct CullApp: App {
    @StateObject private var photoService: PhotoLibraryService
    @StateObject private var historyService: ReviewHistoryService
    @StateObject private var session: SessionViewModel

    init() {
        let photoService = PhotoLibraryService()
        let historyService = ReviewHistoryService()
        _photoService = StateObject(wrappedValue: photoService)
        _historyService = StateObject(wrappedValue: historyService)
        _session = StateObject(
            wrappedValue: SessionViewModel(source: photoService, history: historyService)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoService)
                .environmentObject(historyService)
                .environmentObject(session)
        }
    }
}
