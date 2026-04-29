//
//  LogEntry.swift
//  CaTTrack
//
//  A single logged event for a Pet. Three flavors share one model:
//    .meal      -> kcal, servingSizeOz, ozServed, brand, foodType   (note optional)
//    .water     -> waterMl                                          (note optional)
//    .restroom  -> (no extra fields)                                (note optional)
//
//  Calorie math (meal logs):
//
//      caloriesConsumed = (ozServed / servingSizeOz) * kcal
//
//  Example: a 5oz can with 300 kcal total, cat ate 3oz of it →
//      (3 / 5) * 300 = 180 kcal consumed
//
//  Storing the full-serving label values rather than pre-computed
//  consumed calories keeps the data faithful to what the user sees
//  on the food package and makes future reporting (e.g. "what brand
//  has the highest kcal per oz") possible without re-deriving it.
//
//  Pattern reference:
//   - 11 - Enum.swift              (raw-value enum)
//   - 6 - OOP Encapsulation.swift  (designated init + computed property)
//   - 10 Core Data.pdf             (entities + relationships, applied via SwiftData)
//

import Foundation
import SwiftData

// MARK: - Log Type (kind of event)

enum LogType: String, CaseIterable, Identifiable, Codable {
    case meal     = "Meal"
    case water    = "Water"
    case restroom = "Restroom"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .meal:     return "fork.knife"
        case .water:    return "drop.fill"
        case .restroom: return "toilet.fill"
        }
    }
    
    var tintHex: String {
        switch self {
        case .meal:     return "FFA726"
        case .water:    return "29B6F6"
        case .restroom: return "66BB6A"
        }
    }
}

// MARK: - LogEntry @Model

@Model
final class LogEntry {
    
    var occurredAt: Date
    var loggedAt: Date
    var typeRaw: String
    
    // Meal-specific fields
    var kcal: Int?              // total kcal in the FULL serving (label value)
    var servingSizeOz: Double?  // total oz in the FULL serving (label value)
    var ozServed: Double?       // how much the cat actually ate
    var brand: String?
    var foodTypeRaw: String?
    
    // Water-specific
    var waterMl: Int?
    
    // Always-available
    var note: String?
    
    var pet: Pet?
    
    // MARK: Computed accessors
    
    var type: LogType {
        LogType(rawValue: typeRaw) ?? .meal
    }
    
    var foodType: FoodType? {
        guard let raw = foodTypeRaw else { return nil }
        return FoodType(rawValue: raw)
    }
    
    /// Calories actually consumed for a meal entry. Uses the
    /// (ozServed / servingSizeOz) ratio applied to the total kcal
    /// of the full serving. Returns 0 for non-meal entries or for
    /// any meal entry missing the data needed to compute the ratio.
    var caloriesConsumed: Int {
        guard type == .meal,
              let kcal = kcal,
              let serving = servingSizeOz, serving > 0,
              let served = ozServed, served > 0
        else {
            return 0
        }
        let ratio = served / serving
        return Int((Double(kcal) * ratio).rounded())
    }
    
    // MARK: Designated Initializer
    init(occurredAt: Date,
         type: LogType,
         kcal: Int? = nil,
         servingSizeOz: Double? = nil,
         ozServed: Double? = nil,
         brand: String? = nil,
         foodType: FoodType? = nil,
         waterMl: Int? = nil,
         note: String? = nil,
         pet: Pet? = nil) {
        self.occurredAt = occurredAt
        self.loggedAt = Date()
        self.typeRaw = type.rawValue
        self.kcal = kcal
        self.servingSizeOz = servingSizeOz
        self.ozServed = ozServed
        self.brand = brand
        self.foodTypeRaw = foodType?.rawValue
        self.waterMl = waterMl
        self.note = note
        self.pet = pet
    }
}
