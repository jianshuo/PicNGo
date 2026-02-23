//
//  FoodAnalysisResult.swift
//  PicNGo
//
//  Created by Jianshuo Wang on 2026/2/22.
//

import SwiftUI

struct FoodAnalysisResult: Codable {
    let foodName: String
    let ingredients: [String]
    let caloriesEstimate: String
    let healthRating: String
    let healthAssessment: String
    let tips: [String]

    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case ingredients
        case caloriesEstimate = "calories_estimate"
        case healthRating = "health_rating"
        case healthAssessment = "health_assessment"
        case tips
    }
}

extension FoodAnalysisResult {
    enum HealthLevel {
        case healthy, moderate, unhealthy

        var color: Color {
            switch self {
            case .healthy:   return .green
            case .moderate:  return .orange
            case .unhealthy: return .red
            }
        }

        var emoji: String {
            switch self {
            case .healthy:   return "✅"
            case .moderate:  return "⚠️"
            case .unhealthy: return "❌"
            }
        }

        var label: String {
            switch self {
            case .healthy:   return "Healthy"
            case .moderate:  return "Moderate"
            case .unhealthy: return "Unhealthy"
            }
        }
    }

    var healthLevel: HealthLevel {
        switch healthRating.lowercased() {
        case "healthy":   return .healthy
        case "unhealthy": return .unhealthy
        default:          return .moderate
        }
    }
}
