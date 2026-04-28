//
//  HealthAIEngine.swift
//  CaTTrack
//

import Foundation

/// Represents the daily health metrics input for a cat.
struct CatHealthMetrics {
    let weight: Double        // in kilograms
    let dailyCalories: Int    // in kcal
    let dailyWater: Int       // in milliliters
    let restroomCount: Int    // number of daily visits
}

/// Represents the possible health status levels.
enum HealthStatus: String {
    case good = "Good"
    case warning = "Warning"
    case critical = "Critical"
}

/// Represents the result of a health assessment.
struct HealthAssessment {
    let score: Int            // 0–100
    let recommendations: [String]
    let status: HealthStatus
}

/// A local, deterministic AI engine that simulates a health assistant for cats.
class HealthAIEngine {
    
    // MARK: - Baselines
    
    /// Baseline recommendations for an average domestic cat.
    private struct Baseline {
        static let minWeight: Double = 3.5
        static let maxWeight: Double = 5.5
        static let dailyCalories: Int = 250
        static let dailyWater: Int = 200
        static let restroomCount: Int = 3
    }
    
    // MARK: - Public Methods
    
    /// Assesses the provided metrics and returns a health score, recommendations, and status.
    func assess(metrics: CatHealthMetrics) -> HealthAssessment {
        var score = 100
        var recommendations: [String] = []
        
        // 1. Hydration Check
        if metrics.dailyWater < Baseline.dailyWater {
            let deficit = Baseline.dailyWater - metrics.dailyWater
            let penalty = min(30, (deficit / 20) * 5)
            score -= penalty
            recommendations.append("💧 Hydration warning: Intake is \(deficit)ml below the recommended \(Baseline.dailyWater)ml. Try a water fountain or mix in wet food.")
        }
        
        // 2. Calorie Check
        if metrics.dailyCalories > Baseline.dailyCalories {
            let excess = metrics.dailyCalories - Baseline.dailyCalories
            let penalty = min(30, (excess / 50) * 5)
            score -= penalty
            recommendations.append("🍖 Calorie alert: Intake is \(excess)kcal above the recommended \(Baseline.dailyCalories)kcal. Consider smaller portions or a diet formula.")
        }
        
        // 3. Restroom Check
        if metrics.restroomCount < 2 {
            score -= 20
            recommendations.append("🚽 Digestive concern: Only \(metrics.restroomCount) restroom visit(s) today. Monitor for constipation and consult a vet if this continues.")
        }
        
        // 4. Weight Check
        if metrics.weight < Baseline.minWeight {
            score -= 15
            recommendations.append("⚖️ Weight alert: \(metrics.weight)kg is below the healthy range. Schedule a nutritional check-up.")
        } else if metrics.weight > Baseline.maxWeight {
            score -= 15
            recommendations.append("⚖️ Weight alert: \(metrics.weight)kg is above the healthy range. Consider playtime and portion control.")
        }
        
        // Clamp score to 0–100
        score = max(0, min(100, score))
        
        // Determine status
        let status: HealthStatus
        switch score {
        case 80...100:
            status = .good
        case 50...79:
            status = .warning
        default:
            status = .critical
        }
        
        // If everything is perfect, add a positive note
        if recommendations.isEmpty {
            recommendations.append("✅ All metrics look great! Keep maintaining this healthy routine.")
        }
        
        return HealthAssessment(score: score, recommendations: recommendations, status: status)
    }
    
    /// Generates a human-readable summary string from an assessment for UI display.
    func generateSummary(from assessment: HealthAssessment) -> String {
        let emoji: String
        switch assessment.status {
        case .good:
            emoji = "🟢"
        case .warning:
            emoji = "🟡"
        case .critical:
            emoji = "🔴"
        }
        
        return "\(emoji) Health Score: \(assessment.score)/100 (\(assessment.status.rawValue))\n📋 \(assessment.recommendations.count) recommendation(s) available."
    }
}

