import SwiftUI

/// Settings for the user's own Gemini access: API key entry (Keychain-backed),
/// model selection, and estimated cost tracking.
struct GeminiSettingsView: View {
    @EnvironmentObject private var aiConfig: AIConfigStore

    @State private var keyDraft = ""
    @State private var showKey = false
    @State private var saveConfirmation: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                apiKeySection
                modelSection
                costSection
                SafetyNote(text: SafetyText.aiGeneral)
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Gemini & Usage")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - API key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Access", title: "Gemini API Key")

            if aiConfig.hasAPIKey {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.Colors.success)
                    Text("A key is configured.")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            } else {
                Text("Add your Gemini API key to enable AI features. It is stored securely in the device Keychain and never included in exports.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            DecoTextField(
                label: aiConfig.hasAPIKey ? "Replace key" : "Enter key",
                placeholder: "Paste your Gemini API key",
                text: $keyDraft,
                isSecure: !showKey
            )

            HStack(spacing: Theme.Spacing.m) {
                Button(showKey ? "Hide" : "Show") { showKey.toggle() }
                    .buttonStyle(.decoSecondary)
                Button("Paste") {
                    if let s = UIPasteboard.general.string { keyDraft = s }
                }
                .buttonStyle(.decoSecondary)
            }

            HStack(spacing: Theme.Spacing.m) {
                Button("Save") {
                    if aiConfig.saveAPIKey(keyDraft) {
                        keyDraft = ""
                        showKey = false
                        saveConfirmation = "Key saved to Keychain."
                    } else {
                        saveConfirmation = "Could not save key."
                    }
                }
                .buttonStyle(.decoPrimary)
                .disabled(keyDraft.trimmingCharacters(in: .whitespaces).isEmpty)

                if aiConfig.hasAPIKey {
                    Button("Clear") {
                        aiConfig.clearAPIKey()
                        keyDraft = ""
                        saveConfirmation = "Key cleared."
                    }
                    .buttonStyle(.decoSecondary)
                }
            }

            if let saveConfirmation {
                Text(saveConfirmation)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
            }
        }
    }

    // MARK: - Model

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Model", title: "Choose a Gemini model")
            ForEach(GeminiModel.allCases) { model in
                Button {
                    aiConfig.selectModel(model)
                } label: {
                    FramedCard(padding: Theme.Spacing.m) {
                        HStack(alignment: .top, spacing: Theme.Spacing.m) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(model.displayName)
                                    .font(Theme.Typography.bodyMedium)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text(model.blurb)
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textFaint)
                            }
                            Spacer()
                            Image(systemName: aiConfig.selectedModel == model ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(aiConfig.selectedModel == model ? Theme.Colors.accent : Theme.Colors.textFaint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Cost

    private var costSection: some View {
        let summary = aiConfig.costSummary()
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Usage", title: "Estimated Cost")
            if summary.eventCount == 0 {
                Text("No AI usage yet. Estimated costs will appear here as you use AI features.")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            } else {
                FramedCard {
                    VStack(spacing: Theme.Spacing.s) {
                        costRow("Today", summary.today)
                        Divider().overlay(Theme.Colors.hairline)
                        costRow("Last 7 days", summary.last7Days)
                        Divider().overlay(Theme.Colors.hairline)
                        costRow("Avg / active day", summary.averagePerActiveDay)
                        Divider().overlay(Theme.Colors.hairline)
                        costRow("Total", summary.total, emphasized: true)
                    }
                }
                Text("\(summary.eventCount) request\(summary.eventCount == 1 ? "" : "s") · estimates only, not a bill")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
            }
        }
    }

    private func costRow(_ label: String, _ value: Double, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(emphasized ? Theme.Typography.bodyMedium : Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            Text(Self.formatUSD(value))
                .font(emphasized ? Theme.Typography.sansBold(16) : Theme.Typography.bodyMedium)
                .foregroundStyle(emphasized ? Theme.Colors.accentText : Theme.Colors.textPrimary)
        }
    }

    static func formatUSD(_ value: Double) -> String {
        if value == 0 { return "$0.00" }
        if value < 0.01 { return String(format: "$%.4f", value) }
        return String(format: "$%.2f", value)
    }
}

#Preview {
    NavigationStack { GeminiSettingsView().environmentObject(AIConfigStore()) }
}
