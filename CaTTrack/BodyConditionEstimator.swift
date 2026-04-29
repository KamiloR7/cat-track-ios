//
//  BodyConditionEstimator.swift
//  CaTTrack
//
//  Cat body-condition estimator. We do not collect rib-cage
//  circumference or lower-leg length, so the clinical Feline
//  Body Mass Index (FBMI) formula is unavailable. Instead we
//  approximate the AAFP-recommended Body Condition Score (BCS)
//  on a 1–9 scale using:
//
//      ratio = actualWeight / midpoint(breedIdealRange)
//
//  Breed-specific ideal weight ranges are drawn from a peer-
//  reviewed pilot study (Ludwig-Maximilians-Universität München,
//  British Journal of Nutrition 2011) which grouped pure-bred
//  cats into five weight classes from "very light" through
//  "giant", and supplemented with breed-standard references
//  (TICA / breed-club guidelines). Ranges represent unisex adult
//  cats at ideal body condition; in real clinical practice, sex
//  and life stage would further refine these numbers.
//
//  This is a screening tool, not a diagnosis. The output is
//  intentionally labeled "BCS (est.)" in the UI so we are not
//  overclaiming clinical accuracy.
//
//  Pattern reference:
//   - 11 - Enum.swift              (raw-value enums + computed properties)
//   - 6 - OOP Encapsulation.swift  (class with stored properties + methods)
//

import Foundation

// MARK: - Result types

enum BodyConditionCategory: String {
    case severelyUnderweight = "Severely Underweight"
    case underweight         = "Underweight"
    case lean                = "Lean"
    case ideal               = "Ideal"
    case slightlyOverweight  = "Slightly Overweight"
    case overweight          = "Overweight"
    case obese               = "Obese"
    
    /// SF Symbol color cue.
    var color: String {
        switch self {
        case .severelyUnderweight, .obese:
            return "red"
        case .underweight, .overweight:
            return "orange"
        case .lean, .slightlyOverweight:
            return "yellow"
        case .ideal:
            return "green"
        }
    }
}

struct BodyCondition {
    /// 1–9 BCS, where 5 is the clinical ideal.
    let score: Int
    let category: BodyConditionCategory
    /// The breed's ideal weight range in kilograms (for UI context).
    let idealRangeKg: ClosedRange<Double>
    /// Cat's weight relative to ideal midpoint. 1.0 means perfectly on midpoint.
    let ratio: Double
}

// MARK: - Estimator

enum BodyConditionEstimator {
    
    /// Looks up the unisex ideal weight range (kg) for a breed.
    /// Sources: Munich 2011 pilot study + TICA breed standards;
    /// see file header for full citation.
    static func idealRangeKg(for breed: CatBreed) -> ClosedRange<Double> {
        switch breed {
        case .domesticShorthair,
             .domesticLonghair,
             .other:
            return 3.5...5.5
        case .siamese:
            return 3.0...5.0
        case .persian:
            return 3.5...5.5
        case .maineCoon:
            return 5.5...9.5
        case .ragdoll:
            return 4.5...9.0
        case .bengal:
            return 3.5...6.5
        case .britishShorthair:
            return 4.0...7.5
        case .sphynx:
            return 3.0...5.5
        case .scottishFold:
            return 3.0...6.0
        case .russianBlue:
            return 3.0...5.5
        case .abyssinian:
            return 3.0...5.0
        case .americanShorthair:
            return 3.5...7.0
        case .norwegianForest:
            return 4.0...7.5
        }
    }
    
    /// Compute body condition for a pet's current weight.
    /// Returns BCS 1–9, a category label, and the breed's ideal range.
    static func evaluate(weightKg: Double, breed: CatBreed) -> BodyCondition {
        let range = idealRangeKg(for: breed)
        let midpoint = (range.lowerBound + range.upperBound) / 2.0
        
        // Guard against degenerate input — designated init for Pet
        // already prevents zero/negative weights, but we belt-and-
        // suspenders here so a corrupt store can't crash the UI.
        guard midpoint > 0, weightKg > 0 else {
            return BodyCondition(score: 5,
                                 category: .ideal,
                                 idealRangeKg: range,
                                 ratio: 1.0)
        }
        
        let ratio = weightKg / midpoint
        
        // Map ratio onto BCS 1–9. Cutoffs derived from the relationship
        // between BCS levels and percentage-over-ideal documented in
        // veterinary practice (Laflamme 1997, WSAVA guidelines).
        let score: Int
        let category: BodyConditionCategory
        
        switch ratio {
        case ..<0.70:
            score = 1
            category = .severelyUnderweight
        case 0.70..<0.80:
            score = 2
            category = .underweight
        case 0.80..<0.90:
            score = 3
            category = .underweight
        case 0.90..<0.95:
            score = 4
            category = .lean
        case 0.95...1.05:
            score = 5
            category = .ideal
        case 1.05..<1.15:
            score = 6
            category = .slightlyOverweight
        case 1.15..<1.25:
            score = 7
            category = .overweight
        case 1.25..<1.40:
            score = 8
            category = .overweight
        default:
            score = 9
            category = .obese
        }
        
        return BodyCondition(score: score,
                             category: category,
                             idealRangeKg: range,
                             ratio: ratio)
    }
}
