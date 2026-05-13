//
//  CullApp.swift
//  Cull
//
//  Created by Miro Behninger on 13.05.26.
//

import SwiftUI

@main
struct CullApp: App {
    @StateObject private var photoService = PhotoLibraryService()
    @StateObject private var viewModel = CullViewModel()
    @StateObject private var historyService = ReviewHistoryService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoService)
                .environmentObject(viewModel)
                .environmentObject(historyService)
        }
    }
}
