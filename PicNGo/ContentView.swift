//
//  ContentView.swift
//  PicNGo
//
//  Created by Jianshuo Wang on 2026/2/22.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var apiKeyManager = APIKeyManager.shared

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var analysisResult: FoodAnalysisResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showingCamera = false
    @State private var showingSettings = false

    private let analyzerService = FoodAnalyzerService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    actionButtons
                    if selectedImage != nil {
                        analyzeButton
                    }
                    if let error = errorMessage {
                        errorBanner(error)
                    }
                    if let result = analysisResult {
                        ResultsView(result: result, apiKey: apiKeyManager.apiKey, language: apiKeyManager.selectedLanguage)
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
                CameraView(image: $selectedImage) {
                    analysisResult = nil
                    errorMessage = nil
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadPhoto(from: newItem)
        }
    }

    // MARK: - Image Section

    var imageSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 300)

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            selectedImage = nil
                            selectedPhotoItem = nil
                            analysisResult = nil
                            errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.5))
                                .padding(10)
                        }
                    }
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green.gradient)
                    Text("Snap or choose a food photo")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("GPT-4o will identify ingredients\nand assess nutritional health")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Action Buttons

    var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showingCamera = true
                } else {
                    errorMessage = "Camera is not available on this device."
                }
            } label: {
                Label("Camera", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .font(.headline)
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Library", systemImage: "photo.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .font(.headline)
            }
        }
    }

    // MARK: - Analyze Button

    var analyzeButton: some View {
        Button {
            Task { await analyzeFood() }
        } label: {
            HStack(spacing: 10) {
                if isAnalyzing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                    Text("Analyzing with GPT-4o…")
                } else {
                    Image(systemName: "sparkles")
                    Text("Analyze Food")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(isAnalyzing ? Color.gray : Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .font(.headline)
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

    func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                analysisResult = nil
                errorMessage = nil
            }
        }
    }

    func analyzeFood() async {
        guard let image = selectedImage else { return }
        guard apiKeyManager.hasValidKey else {
            errorMessage = "No API key found. Tap the gear icon to add your OpenAI API key."
            showingSettings = true
            return
        }

        isAnalyzing = true
        errorMessage = nil

        do {
            analysisResult = try await analyzerService.analyzeFood(
                image: image,
                apiKey: apiKeyManager.apiKey,
                language: apiKeyManager.selectedLanguage
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
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
            IngredientDetailView(ingredient: item.name, apiKey: apiKey, language: language)
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
