import SwiftUI

/// Manual health assessment (US-018). Pick data categories, generate a gentle
/// wellness reflection, edit it, and save.
struct HealthAssessmentView: View {
    let aiConfig: AIConfigStore
    @EnvironmentObject private var mealLog: MealLogStore
    @EnvironmentObject private var checkIns: CheckInStore
    @EnvironmentObject private var supplements: SupplementStore
    @EnvironmentObject private var lifestyle: LifestyleStore
    @EnvironmentObject private var exercise: ExerciseStore
    @EnvironmentObject private var assessments: AssessmentStore
    @StateObject private var holder = Holder()

    var body: some View {
        Group {
            if let vm = holder.vm {
                AssessmentContent(vm: vm, assessments: assessments)
            } else {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 80)
            }
        }
        .decoBackground()
        .navigationTitle("Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            holder.configure(aiConfig: aiConfig, mealLog: mealLog, checkIns: checkIns,
                             supplements: supplements, lifestyle: lifestyle, exercise: exercise)
        }
    }

    @MainActor
    final class Holder: ObservableObject {
        @Published var vm: HealthAssessmentViewModel?
        func configure(aiConfig: AIConfigStore, mealLog: MealLogStore, checkIns: CheckInStore,
                       supplements: SupplementStore, lifestyle: LifestyleStore, exercise: ExerciseStore) {
            guard vm == nil else { return }
            vm = HealthAssessmentViewModel(aiConfig: aiConfig) { categories in
                var parts: [String] = []
                for category in categories {
                    switch category {
                    case .macros:
                        let t = mealLog.dailyTotals()
                        parts.append("Today macros: P\(Int(t.proteinGrams)) C\(Int(t.carbGrams)) F\(Int(t.fatGrams))")
                    case .supplements:
                        let names = supplements.supplements.map(\.name)
                        if !names.isEmpty { parts.append("Supplements: \(names.joined(separator: ", "))") }
                    case .lifestyle:
                        parts.append("Practices completed: \(lifestyle.completedCount)")
                    case .exercise:
                        parts.append("Exercise minutes today: \(exercise.totalMinutes())")
                    case .hormoneSkin:
                        if let l = checkIns.latest {
                            parts.append("Latest check-in stress \(l.stress.map(String.init) ?? "-"), sleep \(l.sleepQuality.map(String.init) ?? "-")")
                        }
                    case .acne:
                        if let l = checkIns.latest, let a = l.acneSeverity { parts.append("Skin severity \(a)/5") }
                    case .consult:
                        parts.append("Has consult history.")
                    }
                }
                return parts.isEmpty ? "Limited data available." : parts.joined(separator: "\n")
            }
        }
    }
}

private struct AssessmentContent: View {
    @ObservedObject var vm: HealthAssessmentViewModel
    let assessments: AssessmentStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                switch vm.phase {
                case .setup: setup
                case .report: report
                }
            }
            .padding(Theme.Spacing.l)
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Assessment", title: "What to include")
            Text("Choose the data to reflect on. You can run this any time.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
            FlowChips(items: AssessmentCategory.allCases,
                      isSelected: { vm.selectedCategories.contains($0) },
                      label: { $0.displayName },
                      toggle: { vm.toggle($0) })
            Button {
                Task { await vm.generate() }
            } label: {
                HStack {
                    if vm.isWorking { ProgressView().tint(Theme.Colors.textOnInk) }
                    Text(vm.isWorking ? "Generating…" : "Generate assessment")
                }
            }
            .buttonStyle(.decoPrimary)
            .disabled(!vm.canGenerate || vm.isWorking)
            if let error = vm.errorMessage { SafetyNote(text: error, systemImage: "exclamationmark.triangle") }
        }
    }

    @ViewBuilder
    private var report: some View {
        if let assessment = vm.assessment {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                SectionHeader(eyebrow: "Reflection", title: "Your patterns")

                VStack(alignment: .leading, spacing: 6) {
                    EyebrowText(text: "Summary (editable)")
                    TextEditor(text: $vm.editedText)
                        .frame(minHeight: 120)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.small).fill(Theme.Colors.surfaceSunk))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.small).strokeBorder(Theme.Colors.goldLine, lineWidth: 1))
                }

                listCard("Possible contributors", assessment.possibleContributors)
                listCard("Focus areas", assessment.currentFocusAreas)
                listCard("Holistic practices", assessment.holisticTreatments)
                listCard("Skin findings", assessment.acnePhotoFindings)
                listCard("References", assessment.references.map(\.title))

                SafetyNote(text: assessment.caveats.nilIfBlank ?? SafetyText.aiGeneral)

                HStack(spacing: Theme.Spacing.m) {
                    Button("Done") { dismiss() }.buttonStyle(.decoSecondary)
                    Button("Save assessment") {
                        if let final = vm.finalizedAssessment() { assessments.saveHealth(final) }
                        dismiss()
                    }
                    .buttonStyle(.decoPrimary)
                }
            }
        }
    }

    @ViewBuilder
    private func listCard(_ title: String, _ items: [String]) -> some View {
        if !items.isEmpty {
            FramedCard {
                VStack(alignment: .leading, spacing: 6) {
                    EyebrowText(text: title)
                    ForEach(items, id: \.self) { item in
                        Text("• \(item)")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
