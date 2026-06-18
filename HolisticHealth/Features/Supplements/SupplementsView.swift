import SwiftUI

struct SupplementsView: View {
    @EnvironmentObject private var store: SupplementStore
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var checkIns: CheckInStore
    @EnvironmentObject private var aiConfig: AIConfigStore

    @StateObject private var guidance = GuidanceHolder()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                supplementsSection
                guidanceSection
                SafetyNote(text: SafetyText.supplements)
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Supplements")
        .onAppear { guidance.configure(aiConfig: aiConfig, profile: profile, checkIns: checkIns) }
    }

    // MARK: - Supplements

    private var supplementsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Tracking", title: "My Supplements")

            NavigationLink { SupplementEditView() } label: {
                MacroActionTile(systemImage: "plus.circle", title: "Add supplement",
                                subtitle: "Name, schedule, timing & reason")
            }
            .buttonStyle(.plain)

            ForEach(store.sorted) { supplement in
                supplementRow(supplement)
            }
        }
    }

    private func supplementRow(_ supplement: Supplement) -> some View {
        FramedCard(padding: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    NavigationLink { SupplementEditView(existing: supplement) } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(supplement.name)
                                .font(Theme.Typography.bodyMedium)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            if let detail = scheduleText(supplement) {
                                Text(detail)
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textFaint)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    StatusTag(text: supplement.adherence.displayName,
                              role: supplement.adherence == .taking ? .success : .neutral)
                }
                Toggle(isOn: Binding(
                    get: { store.isTakenToday(supplement.id) },
                    set: { store.setTakenToday(supplement.id, taken: $0) }
                )) {
                    Text("Taken today")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .tint(Theme.Colors.accent)
            }
        }
    }

    private func scheduleText(_ s: Supplement) -> String? {
        [s.schedule, s.timing].compactMap { $0?.nilIfBlank }.joined(separator: " · ").nilIfBlank
    }

    // MARK: - Guidance

    private var guidanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Guidance", title: "Nutrient Areas to Consider")
            Text("A careful, non-diagnostic look at nutrient areas you might explore — never a deficiency diagnosis.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            Button {
                Task { await guidance.vm?.generate() }
            } label: {
                HStack {
                    if guidance.vm?.isWorking == true { ProgressView().tint(Theme.Colors.textOnInk) }
                    Text(guidance.vm?.isWorking == true ? "Thinking…" : "Suggest areas to consider")
                }
            }
            .buttonStyle(.decoPrimary)
            .disabled(guidance.vm?.isWorking == true)

            if let error = guidance.vm?.errorMessage {
                SafetyNote(text: error, systemImage: "exclamationmark.triangle")
            }

            ForEach(guidance.vm?.suggestions ?? []) { suggestion in
                suggestionCard(suggestion)
            }
        }
    }

    private func suggestionCard(_ s: NutrientSuggestion) -> some View {
        FramedCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(s.area)
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(s.rationale)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                if !s.relevantInputs.isEmpty {
                    detailLine("Based on", s.relevantInputs.joined(separator: ", "))
                }
                detailLine("Safety", s.safetyNotes)
                if !s.clinicianQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        EyebrowText(text: "Ask a clinician")
                        ForEach(s.clinicianQuestions, id: \.self) { q in
                            Text("• \(q)")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func detailLine(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            EyebrowText(text: label)
            Text(value)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

/// Holds the guidance view model, configured once the environment is available.
@MainActor
final class GuidanceHolder: ObservableObject {
    @Published var vm: NutrientGuidanceViewModel?

    func configure(aiConfig: AIConfigStore, profile: ProfileStore, checkIns: CheckInStore) {
        guard vm == nil else { return }
        vm = NutrientGuidanceViewModel(aiConfig: aiConfig) {
            var parts: [String] = []
            let goals = profile.profile.goals.map(\.title)
            if !goals.isEmpty { parts.append("Goals: \(goals.joined(separator: ", "))") }
            if let latest = checkIns.latest {
                if let stress = latest.stress { parts.append("Recent stress: \(stress)/5") }
                if let sleep = latest.sleepQuality { parts.append("Recent sleep: \(sleep)/5") }
                if let acne = latest.acneSeverity { parts.append("Recent skin: \(acne)/5") }
            }
            return parts.isEmpty ? "General women's wellness, protein-forward nutrition." : parts.joined(separator: "; ")
        }
    }
}

#Preview {
    NavigationStack { SupplementsView() }
        .environmentObject(SupplementStore())
        .environmentObject(ProfileStore())
        .environmentObject(CheckInStore())
        .environmentObject(AIConfigStore())
}
