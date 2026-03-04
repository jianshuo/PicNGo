//
//  ContentView.swift
//  PicNGo
//
//  Created by Jianshuo Wang on 2026/2/22.
//

import SwiftUI
import PhotosUI

// MARK: - Meal Type

enum MealType: String, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snacks

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Night Snacks"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snacks: return "moon.zzz.fill"
        }
    }
}

// MARK: - Meal Slot (per-meal image + result)

struct MealSlot: Identifiable {
    let mealType: MealType
    var image: UIImage?
    var photoItem: PhotosPickerItem?
    var result: FoodAnalysisResult?
    var isAnalyzing: Bool = false

    var id: String { mealType.rawValue }
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var apiKeyManager = APIKeyManager.shared

    @State private var slots: [MealSlot] = MealType.allCases.map { MealSlot(mealType: $0) }
    @State private var errorMessage: String?
    @State private var showingCamera = false
    @State private var cameraForMeal: MealType?
    @State private var showingSettings = false
    @State private var showingAIConsentAlert = false
    @State private var pendingAnalysisIndex: Int?

    private let analyzerService = FoodAnalyzerService()

    private func index(for meal: MealType) -> Int {
        MealType.allCases.firstIndex(of: meal) ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let error = errorMessage {
                        errorBanner(error)
                    }

                    ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                        mealCard(slot: slot, index: index)
                    }
                }
                .padding()
                .padding(.bottom, 32)
            }
            .navigationTitle("Food Analyzer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                if let meal = cameraForMeal {
                    let i = index(for: meal)
                    CameraView(image: Binding(
                        get: { slots[i].image },
                        set: { newImage in
                            var slot = slots[i]
                            slot.image = newImage
                            slot.result = nil
                            slots[i] = slot
                            errorMessage = nil
                        }
                    )) {
                        var slot = slots[i]
                        slot.result = nil
                        slots[i] = slot
                        errorMessage = nil
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Allow AI Data Sharing?", isPresented: $showingAIConsentAlert) {
                Button("Not Now", role: .cancel) {
                    pendingAnalysisIndex = nil
                }
                Button("Agree & Analyze") {
                    apiKeyManager.hasGrantedAIDataSharingConsent = true
                    if let index = pendingAnalysisIndex {
                        Task { await analyzeFood(for: index) }
                    }
                    pendingAnalysisIndex = nil
                }
            } message: {
                Text(
                    "To analyze food, PicNGo sends your selected photo, food-related text prompts, and language preference to OpenAI. " +
                    "This data is processed by OpenAI to generate analysis results."
                )
            }
        }
    }

    // MARK: - Meal Card (one per meal type)

    func mealCard(slot: MealSlot, index: Int) -> some View {
        let meal = slot.mealType
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: meal.icon)
                    .font(.title3)
                    .foregroundStyle(.orange)
                Text(meal.displayName)
                    .font(.headline)
            }

            imageSection(slot: slot, index: index)
            actionButtons(for: index)
            if slots[index].image != nil {
                analyzeButton(for: index)
            }
            if let result = slots[index].result {
                ResultsView(
                    result: result,
                    apiKey: apiKeyManager.apiKey,
                    language: apiKeyManager.selectedLanguage,
                    hasAIDataSharingConsent: apiKeyManager.hasGrantedAIDataSharingConsent
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onChange(of: slots[index].photoItem) { _, newItem in
            loadPhoto(from: newItem, into: index)
        }
    }

    func imageSection(slot: MealSlot, index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
                .frame(height: 200)

            if let image = slot.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            clearSlot(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.5))
                                .padding(8)
                        }
                    }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.green.gradient)
                    Text("Add photo for \(slot.mealType.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    func actionButtons(for index: Int) -> some View {
        HStack(spacing: 10) {
            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    cameraForMeal = slots[index].mealType
                    showingCamera = true
                } else {
                    errorMessage = "Camera is not available on this device."
                }
            } label: {
                Label("Camera", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .font(.subheadline)
            }

            PhotosPicker(selection: $slots[index].photoItem, matching: .images) {
                Label("Library", systemImage: "photo.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .font(.subheadline)
            }
        }
    }

    func analyzeButton(for index: Int) -> some View {
        let isAnalyzing = slots[index].isAnalyzing
        return Button {
            if apiKeyManager.hasGrantedAIDataSharingConsent {
                Task { await analyzeFood(for: index) }
            } else {
                pendingAnalysisIndex = index
                showingAIConsentAlert = true
            }
        } label: {
            HStack(spacing: 8) {
                if isAnalyzing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                    Text("Analyzing…")
                } else {
                    Image(systemName: "sparkles")
                    Text("Analyze \(slots[index].mealType.displayName)")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isAnalyzing ? Color.gray : Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .font(.subheadline)
            .fontWeight(.medium)
            .animation(.easeInOut(duration: 0.2), value: isAnalyzing)
        }
        .disabled(isAnalyzing)
    }

    // MARK: - Error Banner

    func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Actions

    func clearSlot(at index: Int) {
        slots[index].image = nil
        slots[index].photoItem = nil
        slots[index].result = nil
        errorMessage = nil
    }

    func loadPhoto(from item: PhotosPickerItem?, into index: Int) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    slots[index].image = image
                    slots[index].result = nil
                    errorMessage = nil
                }
            }
        }
    }

    func analyzeFood(for index: Int) async {
        guard let image = slots[index].image else { return }
        guard apiKeyManager.hasValidKey else {
            await MainActor.run {
                errorMessage = "No API key found. Tap the gear icon to add your OpenAI API key."
                showingSettings = true
            }
            return
        }
        guard apiKeyManager.hasGrantedAIDataSharingConsent else {
            await MainActor.run {
                errorMessage = "Please allow AI data sharing before analysis."
            }
            return
        }

        await MainActor.run {
            slots[index].isAnalyzing = true
            errorMessage = nil
        }

        do {
            let result = try await analyzerService.analyzeFood(
                image: image,
                apiKey: apiKeyManager.apiKey,
                language: apiKeyManager.selectedLanguage
            )
            await MainActor.run {
                slots[index].result = result
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        await MainActor.run {
            slots[index].isAnalyzing = false
        }
    }
}

// MARK: - Identifiable wrapper so .sheet(item:) always has its data

struct IngredientItem: Identifiable {
    let id: String          // ingredient name doubles as stable ID
    var name: String { id }
}

// MARK: - Results View

struct ResultsView: View {
    let result: FoodAnalysisResult
    let apiKey: String
    let language: AppLanguage
    let hasAIDataSharingConsent: Bool

    @State private var selectedIngredient: IngredientItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header card: food name + health rating
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.foodName)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(result.caloriesEstimate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 4) {
                    Text(result.healthLevel.emoji)
                        .font(.largeTitle)
                    Text(result.healthLevel.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(result.healthLevel.color)
                }
            }
            .padding()
            .background(result.healthLevel.color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Health assessment
            infoCard(
                icon: "heart.text.square.fill",
                iconColor: .pink,
                title: "Health Assessment"
            ) {
                Text(result.healthAssessment)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Ingredients — each row is tappable
            infoCard(
                icon: "list.bullet.clipboard.fill",
                iconColor: .blue,
                title: "Ingredients"
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(result.ingredients, id: \.self) { ingredient in
                        Button {
                            selectedIngredient = IngredientItem(id: ingredient)
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color.blue.opacity(0.5))
                                    .frame(width: 7, height: 7)
                                Text(ingredient)
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 6)
                        }

                        if ingredient != result.ingredients.last {
                            Divider().padding(.leading, 17)
                        }
                    }
                }
            }

            // Tips
            if !result.tips.isEmpty {
                infoCard(
                    icon: "lightbulb.fill",
                    iconColor: .yellow,
                    title: "Health Tips"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(result.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.subheadline)
                                Text(tip)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedIngredient) { item in
            IngredientDetailView(
                ingredient: item.name,
                apiKey: apiKey,
                language: language,
                hasAIDataSharingConsent: hasAIDataSharingConsent
            )
        }
    }

    @ViewBuilder
    func infoCard<Content: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(iconColor)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
