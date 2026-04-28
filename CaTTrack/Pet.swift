//
//  Pet.swift
//  CaTTrack
//
//  A registered cat profile owned by a User.
//
//  Relationships:
//    User      1 --- *  Pet         (inverse: User.pets, cascade)
//    Pet       1 --- 1  PetGoals    (cascade)
//    Pet       1 --- *  LogEntry    (cascade)
//

import Foundation
import SwiftData

@Model
final class Pet {
    
    // MARK: - Stored Properties
    var name: String
    var breed: String          // raw value of CatBreed
    var ageYears: Int
    var weightKg: Double
    var createdAt: Date
    
    // Inverse side of User <-> Pet.
    var owner: User?
    
    // One-to-one targets. Cascade: deleting a Pet deletes its goals.
    @Relationship(deleteRule: .cascade, inverse: \PetGoals.pet)
    var goals: PetGoals?
    
    // One-to-many log entries. Cascade: deleting a Pet deletes its logs.
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.pet)
    var logEntries: [LogEntry] = []
    
    // MARK: - Computed Property (per 6 - OOP Encapsulation.swift)
    /// Returns the strongly-typed breed enum, falling back to .other
    /// if a stored raw value doesn't match any known case.
    var breedEnum: CatBreed {
        CatBreed(rawValue: breed) ?? .other
    }
    
    // MARK: - Designated Initializer
    init(name: String,
         breed: CatBreed,
         ageYears: Int,
         weightKg: Double,
         owner: User? = nil) {
        self.name = name
        self.breed = breed.rawValue
        self.ageYears = ageYears
        self.weightKg = weightKg
        self.owner = owner
        self.createdAt = Date()
    }
}
