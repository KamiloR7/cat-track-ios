//
//  LogEntry.swift
//  CaTTrack
//
//  A single logged event for a Pet. Three flavors share one model:
//    .meal      -> kcal, ozServed, brand, foodType   (note optional)
//    .water     -> waterMl                           (note optional)
//    .restroom  -> (no extra fields)                 (note optional)
//
//  Storing all three flavors in one entity keeps the calendar query
//  simple ("give me everything for this day") and sidesteps the need
//  for three parallel tables. Type-specific fields are Optional so
//  the schema accurately reflects "not applicable for this kind."
//
//  Pattern reference:
//   - 10 - Struct.swift            (struct vs class, value semantics — see LogType)
//   - 11 - Enum.swift              (raw-value enum)
//   - 6 - OOP Encapsulation.swift  (designated initializer)
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
        case .meal:     return "FFA726"  // orange
        case .water:    return "29B6F6"  // cyan
        case .restroom: return "66BB6A"  // green
        }
    }
}

// MARK: - LogEntry @Model

@Model
final class LogEntry {
    
    // When the event happened (date + time, set by the user).
    var occurredAt: Date
    
    // When this row was written to the DB (audit trail).
    var loggedAt: Date
    
    // Stored as the enum's raw String so it survives schema migration.
    var typeRaw: String
    
    // Type-specific fields (Optional — only one set populates per row).
    var kcal: Int?
    var ozServed: Double?
    var brand: String?
    var foodTypeRaw: String?
    var waterMl: Int?
    
    // Free-text note (used most often for restroom anomalies, but allowed
    // on any log type per spec).
    var note: String?
    
    // Inverse of Pet.logEntries.
    var pet: Pet?
    
    // MARK: Computed accessors
    
    var type: LogType {
        LogType(rawValue: typeRaw) ?? .meal
    }
    
    var foodType: FoodType? {
        guard let raw = foodTypeRaw else { return nil }
        return FoodType(rawValue: raw)
    }
    
    // MARK: Designated Initializer
    init(occurredAt: Date,
         type: LogType,
         kcal: Int? = nil,
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
        self.ozServed = ozServed
        self.brand = brand
        self.foodTypeRaw = foodType?.rawValue
        self.waterMl = waterMl
        self.note = note
        self.pet = pet
    }
}
