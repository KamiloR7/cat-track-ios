//
//  CatBreed.swift
//  CaTTrack
//
//  Finite set of valid cat breeds. Backing the breed Picker on
//  Step 1 of pet onboarding so users can't invent a breed string
//  the Health AI Engine wouldn't recognize.
//
//  Pattern reference:
//   - 11 - Enum.swift     (raw-value enums, .allCases)
//   - 2 Overview of Swift Features.pdf — "Enum class: model a finite
//     set of mutually exclusive states"
//

import Foundation

enum CatBreed: String, CaseIterable, Identifiable, Codable {
    case domesticShorthair = "Domestic Shorthair"
    case domesticLonghair  = "Domestic Longhair"
    case siamese           = "Siamese"
    case persian           = "Persian"
    case maineCoon         = "Maine Coon"
    case ragdoll           = "Ragdoll"
    case bengal            = "Bengal"
    case britishShorthair  = "British Shorthair"
    case sphynx            = "Sphynx"
    case scottishFold      = "Scottish Fold"
    case russianBlue       = "Russian Blue"
    case abyssinian        = "Abyssinian"
    case americanShorthair = "American Shorthair"
    case norwegianForest   = "Norwegian Forest Cat"
    case other             = "Other / Mixed"
    
    // Identifiable — required by ForEach inside Picker
    var id: String { rawValue }
}
