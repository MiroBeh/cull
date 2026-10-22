//
//  ContentView.swift
//  Cull
//
//  Created by Miro Behninger on 13.05.26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView {
                hasSeenOnboarding = true
            }
        } else {
            NavigationStack {
                HomeView()
            }
        }
    }
}
