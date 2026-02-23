//
//  FoodAnalyzerService.swift
//  PicNGo
//
//  Created by Jianshuo Wang on 2026/2/22.
//

import UIKit

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct FoodAnalyzerService {
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o"

    // MARK: - Food Analysis

    func analyzeFood(image: UIImage, apiKey: String, language: AppLanguage = .english) async throws -> FoodAnalysisResult {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError(message: "API key is not set. Tap the gear icon to add your OpenAI API key.")
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError(message: "Failed to process the image.")
        }

        let base64Image = imageData.base64EncodedString()

        let prompt = """
        Analyze this food image and respond with ONLY a valid JSON object — no markdown, no code fences, no extra text.

        Use exactly this structure:
        {
          "food_name": "Name of the food or dish",
          "ingredients": ["ingredient 1", "ingredient 2", "ingredient 3"],
          "calories_estimate": "approximately X–Y calories per serving",
          "health_rating": "Healthy",
          "health_assessment": "A concise 1–2 sentence assessment of the nutritional value and health impact.",
          "tips": ["Practical health tip 1", "Practical health tip 2"]
        }

        For health_rating use ONLY one of: "Healthy", "Moderate", or "Unhealthy".
        If the image is not food, set food_name to "Not food detected" and explain briefly in health_assessment.
        \(language.promptInstruction)
        """

        let messages: [[String: Any]] = [[
            "role": "user",
            "content": [
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]],
                ["type": "text", "text": prompt]
            ]
        ]]

        let text = try await callOpenAI(messages: messages, apiKey: apiKey, maxTokens: 1024)

        guard let data = text.data(using: .utf8) else {
            throw APIError(message: "Failed to decode analysis text.")
        }
        do {
            return try JSONDecoder().decode(FoodAnalysisResult.self, from: data)
        } catch {
            throw APIError(message: "Could not parse food analysis. Raw: \(String(text.prefix(150)))")
        }
    }

    // MARK: - Ingredient Analysis

    func analyzeIngredient(name: String, apiKey: String, language: AppLanguage = .english) async throws -> IngredientAnalysis {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError(message: "API key is not set.")
        }

        let prompt = """
        You are a nutritionist. Analyze the food ingredient "\(name)" and respond with ONLY a valid JSON object — no markdown, no code fences, no extra text:
        {
          "what_it_is": "A clear 1-2 sentence description of what this ingredient is",
          "nutritional_highlights": ["Key nutrient 1 with brief note", "Key nutrient 2", "Key nutrient 3"],
          "health_benefits": ["Specific benefit 1", "Specific benefit 2", "Specific benefit 3"],
          "health_concerns": ["Concern 1, or write 'Generally safe in normal amounts' if there are none"],
          "recommended_amount": "Recommended daily or per-meal amount for a healthy adult"
        }
        \(language.promptInstruction)
        """

        let messages: [[String: Any]] = [["role": "user", "content": prompt]]

        let text = try await callOpenAI(messages: messages, apiKey: apiKey, maxTokens: 600)

        guard let data = text.data(using: .utf8) else {
            throw APIError(message: "Failed to decode ingredient analysis.")
        }
        do {
            return try JSONDecoder().decode(IngredientAnalysis.self, from: data)
        } catch {
            throw APIError(message: "Could not parse ingredient analysis.")
        }
    }

    // MARK: - Shared API Helper

    private func callOpenAI(
        messages: [[String: Any]],
        apiKey: String,
        maxTokens: Int
    ) async throws -> String {
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": messages
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(message: "Invalid server response.")
        }

        guard httpResponse.statusCode == 200 else {
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorBody["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw APIError(message: "API error: \(message)")
            }
            throw APIError(message: "Server returned HTTP \(httpResponse.statusCode). Please verify your API key.")
        }

        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonResponse["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let msg = firstChoice["message"] as? [String: Any],
              let text = msg["content"] as? String else {
            throw APIError(message: "Unexpected response format from API.")
        }

        // Strip markdown code fences if GPT wraps the JSON
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .components(separatedBy: "\n").dropFirst()
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
    }
}
