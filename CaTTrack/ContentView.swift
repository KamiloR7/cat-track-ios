//
//  ContentView.swift
//  CaTTrack
//
//  Root router. Three states drive which screen is shown:
//
//    1. No signed-in user                         -> WelcomeView
//    2. Signed-in user, but no pet on file        -> PetOnboardingView
//    3. Signed-in user with at least one pet      -> MainTabView
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @EnvironmentObject private var auth: AuthService
    
    var body: some View {
        Group {
            if let user = auth.currentUser {
                if user.pets.isEmpty {
                    PetOnboardingView()
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            } else {
                WelcomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.currentUser?.email)
        .animation(.easeInOut(duration: 0.35), value: auth.currentUser?.pets.count)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.previewMock)
        .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                        inMemory: true)
}
