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

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView {
                hasSeenOnboarding = true
            }
        } else {
            NavigationStack {
                CullView()
            }
            .sheet(isPresented: $viewModel.showConfirmation) {
                ConfirmationView()
            }
            .fullScreenCover(isPresented: $viewModel.showSummary) {
                SummaryView()
            }
        }
    }
}
