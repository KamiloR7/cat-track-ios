//
//  ContentView.swift
//  CaTTrack
//

import SwiftUI

struct ContentView: View {
    @State private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                DashboardView()
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

