//
//  APIKeyManager.swift
//  PicNGo
//
//  Created by Jianshuo Wang on 2026/2/22.
//

import Foundation
internal import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case japanese = "ja"
    case chinese = "zh"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:  return "English"
        case .japanese: return "日本語"
        case .chinese:  return "中文"
        }
    }

    /// Instruction appended to every prompt so GPT-4o replies in the chosen language.
    var promptInstruction: String {
        switch self {
        case .english:  return "Respond entirely in English."
        case .japanese: return "日本語で回答してください。"
        case .chinese:  return "请用中文回答。"
        }
    }
}

@MainActor
final class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()

    private let apiKeyStorageKey  = "anthropic_api_key"
    private let languageStorageKey = "app_language"

    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: apiKeyStorageKey) }
    }

    @Published var selectedLanguage: AppLanguage {
        didSet { UserDefaults.standard.set(selectedLanguage.rawValue, forKey: languageStorageKey) }
    }

    var hasValidKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private init() {
        self.apiKey = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
        let savedLang = UserDefaults.standard.string(forKey: "app_language") ?? ""
        self.selectedLanguage = AppLanguage(rawValue: savedLang) ?? .english
    }
}
