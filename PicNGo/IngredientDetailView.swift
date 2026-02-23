//
//  IngredientDetailView.swift
//  PicNGo
//
//  Created by Jianshuo Wang on 2026/2/22.
//

import SwiftUI

struct IngredientDetailView: View {
    let ingredient: String
    let apiKey: String
    let language: AppLanguage

    @State private var analysis: IngredientAnalysis?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let service = FoodAnalyzerService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if let analysis {
                        analysisContent(analysis)
                    }
                }
                .padding()
                .padding(.bottom, 32)
            }
            .navigationTitle(ingredient)
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await loadAnalysis() }
    }

    // MARK: - Loading

    var loadingView: some View {
        VStack(spacing: 18) {
            ProgressView()
                .scaleEffect(1.4)
            Text("Asking GPT-4o about \(ingredient)…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Error

    func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await loadAnalysis() }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Analysis Content

    func analysisContent(_ analysis: IngredientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // What is it
            infoCard(icon: "info.circle.fill", iconColor: .blue, title: "What is it?") {
                Text(analysis.whatItIs)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Nutritional highlights
            infoCard(icon: "bolt.fill", iconColor: .orange, title: "Nutritional Highlights") {
                bulletList(items: analysis.nutritionalHighlights,
                           icon: "bolt.fill", iconColor: .orange)
            }

            // Health benefits
            infoCard(icon: "heart.fill", iconColor: .green, title: "Health Benefits") {
                bulletList(items: analysis.healthBenefits,
                           icon: "checkmark.circle.fill", iconColor: .green)
            }

            // Health concerns
            infoCard(icon: "exclamationmark.triangle.fill", iconColor: .red, title: "Health Concerns") {
                bulletList(items: analysis.healthConcerns,
                           icon: "exclamationmark.circle.fill", iconColor: .red)
            }

            // Recommended amount
            infoCard(icon: "scalemass.fill", iconColor: .purple, title: "Recommended Amount") {
                Text(analysis.recommendedAmount)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    func bulletList(items: [String], icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(iconColor)
                        .padding(.top, 2)
                    Text(item)
                        .font(.subheadline)
                }
            }
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

    // MARK: - Load

    func loadAnalysis() async {
        isLoading = true
        errorMessage = nil
        do {
            analysis = try await service.analyzeIngredient(name: ingredient, apiKey: apiKey, language: language)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
