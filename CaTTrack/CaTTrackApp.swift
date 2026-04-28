//
//  CaTTrackApp.swift
//  CaTTrack
//
//  App entry. Owns the ModelContainer and the AuthService.
//
//  Single-container rule: AuthService and the .modelContainer
//  modifier share one container so writes are visible across all
//  views in the same session.
//

import SwiftUI
import SwiftData

@main
struct CaTTrackApp: App {
    
    let sharedModelContainer: ModelContainer
    
    @StateObject private var auth: AuthService
    
    init() {
        let schema = Schema([
            User.self,
            Pet.self,
            PetGoals.self,
            LogEntry.self,
            Item.self  // kept from the original scaffold
        ])
        let configuration = ModelConfiguration(schema: schema,
                                               isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema,
                                           configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        self.sharedModelContainer = container
        _auth = StateObject(
            wrappedValue: AuthService(context: container.mainContext)
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }
        .modelContainer(sharedModelContainer)
    }
}
