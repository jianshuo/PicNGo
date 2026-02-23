//
//  SettingsView.swift
//  PicNGo
//
//  Created by Jianshuo Wang on 2026/2/22.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var tempAPIKey: String = ""
    @State private var showingKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OpenAI API Key")
                            .font(.headline)

                        Text("Get your key at platform.openai.com/api-keys")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Group {
                                if showingKey {
                                    TextField("sk-...", text: $tempAPIKey)
                                } else {
                                    SecureField("sk-...", text: $tempAPIKey)
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))

                            Button {
                                showingKey.toggle()
                            } label: {
                                Image(systemName: showingKey ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Your key is stored locally on this device only and never shared.")
                }

                Section {
                    Button("Save API Key") {
                        apiKeyManager.apiKey = tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .disabled(tempAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if apiKeyManager.hasValidKey {
                        Button("Clear API Key", role: .destructive) {
                            apiKeyManager.apiKey = ""
                            tempAPIKey = ""
                        }
                    }
                }

                Section {
                    Picker("Response Language", selection: $apiKeyManager.selectedLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("AI responses will be returned in the selected language.")
                }

                Section("About") {
                    LabeledContent("Model", value: "GPT-4o")
                    LabeledContent("Feature", value: "Vision + AI Analysis")
                    LabeledContent("App", value: "PicNGo v1.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            tempAPIKey = apiKeyManager.apiKey
        }
    }
}
