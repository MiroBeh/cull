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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoService)
                .environmentObject(viewModel)
        }
    }
}
