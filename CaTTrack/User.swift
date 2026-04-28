//
//  User.swift
//  CaTTrack
//
//  Local user account model.
//  Schema mirrors Prof. Shen's UserStore (SQLite.swift): id, name, email.
//  passwordHash is added for local-only authentication (no network).
//

import Foundation
import SwiftData

@Model
final class User {
    
    // MARK: - Stored Properties
    //
    // SwiftData uses Apple's persistent store (the same backing store
    // family as Core Data — see 10 Core Data.pdf).
    //
    @Attribute(.unique) var email: String
    var name: String
    var passwordHash: String
    var createdAt: Date
    
    // Relationship: one user may register many pets.
    // Cascade delete: removing the user removes their pets.
    @Relationship(deleteRule: .cascade, inverse: \Pet.owner)
    var pets: [Pet] = []
    
    // MARK: - Designated Initializer
    //
    // Pattern from 6 - OOP Encapsulation.swift:
    // designated init takes all stored properties.
    //
    init(name: String, email: String, passwordHash: String) {
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.createdAt = Date()
    }
}
