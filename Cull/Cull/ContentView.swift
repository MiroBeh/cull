//
//  ContentView.swift
//  Cull
//
//  Created by Miro Behninger on 13.05.26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @EnvironmentObject var viewModel: CullViewModel
    @State private var path: [SessionFilter] = []

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView {
                hasSeenOnboarding = true
            }
        } else {
            NavigationStack(path: $path) {
                SessionsHomeView(path: $path)
                    .navigationDestination(for: SessionFilter.self) { filter in
                        CullView(filter: filter)
                    }
            }
            .sheet(isPresented: $viewModel.showConfirmation) {
                ConfirmationView()
            }
            .fullScreenCover(isPresented: $viewModel.showSummary, onDismiss: {
                path.removeAll()
            }) {
                SummaryView()
            }
        }
    }
}
