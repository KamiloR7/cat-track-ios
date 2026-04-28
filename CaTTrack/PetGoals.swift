//
//  PetGoals.swift
//  CaTTrack
//
//  The "ceiling" targets the user sets in Step 2 of pet onboarding.
//  Future graphs render these as dotted ceiling lines, with logged
//  meal/water entries plotted as solid-line nodes underneath.
//
//  One-to-one with Pet.
//

import Foundation
import SwiftData

@Model
final class PetGoals {
    
    var targetWeightKg: Double
    var targetCaloriesPerDay: Int
    var targetWaterMlPerDay: Int
    var createdAt: Date
    
    // Inverse of Pet.goals.
    var pet: Pet?
    
    // MARK: Designated Initializer
    init(targetWeightKg: Double,
         targetCaloriesPerDay: Int,
         targetWaterMlPerDay: Int,
         pet: Pet? = nil) {
        self.targetWeightKg = targetWeightKg
        self.targetCaloriesPerDay = targetCaloriesPerDay
        self.targetWaterMlPerDay = targetWaterMlPerDay
        self.createdAt = Date()
        self.pet = pet
    }
}
