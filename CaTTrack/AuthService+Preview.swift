//
//  AuthService+Preview.swift
//  CaTTrack
//
//  Preview-only convenience. Builds an in-memory ModelContainer so
//  #Preview blocks can render without touching the on-disk store.
//

import Foundation
import SwiftData

extension AuthService {
    
    /// Throwaway AuthService backed by an in-memory SwiftData container.
    /// For SwiftUI previews only.
    @MainActor
    static var previewMock: AuthService {
        let schema = Schema([User.self, Pet.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // Force-try is acceptable in preview-only code paths.
        let container = try! ModelContainer(for: schema, configurations: [config])
        return AuthService(context: container.mainContext)
    }
}
