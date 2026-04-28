//
//  FoodType.swift
//  CaTTrack
//
//  Protein source for meal log entries. Used by LogEntrySheet
//  when the log type is .meal.
//
//  Pattern reference:
//   - 11 - Enum.swift (raw-value enum, CaseIterable)
//

import Foundation

enum FoodType: String, CaseIterable, Identifiable, Codable {
    case chicken = "Chicken"
    case turkey  = "Turkey"
    case lamb    = "Lamb"
    case beef    = "Beef"
    case fish    = "Fish"
    case other   = "Other"
    
    var id: String { rawValue }
}
