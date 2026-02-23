//
//  IngredientAnalysis.swift
//  PicNGo
//
//  Created by Jianshuo Wang on 2026/2/22.
//

import Foundation

struct IngredientAnalysis: Codable {
    let whatItIs: String
    let nutritionalHighlights: [String]
    let healthBenefits: [String]
    let healthConcerns: [String]
    let recommendedAmount: String

    enum CodingKeys: String, CodingKey {
        case whatItIs = "what_it_is"
        case nutritionalHighlights = "nutritional_highlights"
        case healthBenefits = "health_benefits"
        case healthConcerns = "health_concerns"
        case recommendedAmount = "recommended_amount"
    }
}
