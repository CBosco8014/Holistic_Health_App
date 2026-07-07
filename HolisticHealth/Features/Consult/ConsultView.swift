import SwiftUI

/// Adaptive consult (US-018). Builds its view model once env objects are
/// available, then hands off to an observed child view.
struct ConsultView: View {
    let aiConfig: AIConfigStore
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var checkIns: CheckInStore
    @EnvironmentObject private var assessments: AssessmentStore
    @StateObject private var holder = Holder()

    var body: some View {
        Group {
            if let vm = holder.vm {
                ConsultContent(vm: vm, assessments: assessments)
            } else {
                ProgressView().frame(maxWidth: .infinity).padding(.top, 80)
            }
        }
        .decoBackground()
        .navigationTitle("Consult")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            holder.configure(aiConfig: aiConfig, profile: profile, checkIns: checkIns)
        }
    }

    @MainActor
    final class Holder: ObservableObject {
        @Published var vm: ConsultViewModel?
        func configure(aiConfig: AIConfigStore, profile: ProfileStore, checkIns: CheckInStore) {
            guard vm == nil else { return }
            let model = ConsultViewModel(aiConfig: aiConfig) {
                var parts: [String] = []
                let goals = profile.profile.goals.map(\.title)
                if !goals.isEmpty { parts.append("Goals: \(goals.joined(separator: ", "))") }
                if let latest = checkIns.latest {
                    if let s = latest.stress { parts.append("Stress \(s)/5") }
                    if let sl = latest.sleepQuality { parts.append("Sleep \(sl)/5") }
                    if let a = latest.acneSeverity { parts.append("Skin \(a)/5") }
                }
                return parts.isEmpty ? "No specific signals." : parts.joined(separator: "; ")
            }
            model.usePatterns = profile.isGranted(.aiConsultContext)
            vm = model
        }
    }
}

private struct ConsultContent: View {
    @ObservedObject var vm: ConsultViewModel
    let assessments: AssessmentStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                switch vm.phase {
                case .intro: intro
                case .asking: asking
                case .complete: complete
                }
            }
            .padding(Theme.Spacing.l)
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Consult", title: "A few gentle questions")
            Text("Up to 10 adaptive questions across digestion, stress, sleep, skin, cycle, food, supplements, hydration, and lifestyle.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
            Toggle("Let answers consider my logged patterns", isOn: $vm.usePatterns)
                .font(Theme.Typography.body)
                .tint(Theme.Colors.accent)
            SafetyNote(text: SafetyText.aiGeneral)
            Button {
                Task { await vm.start() }
            } label: {
                HStack {
                    if vm.isWorking { ProgressView().tint(Theme.Colors.textOnInk) }
                    Text(vm.isWorking ? "Starting…" : "Begin consult")
                }
            }
            .buttonStyle(.decoPrimary)
            .disabled(vm.isWorking)
            if let error = vm.errorMessage { SafetyNote(text: error, systemImage: "exclamationmark.triangle") }
        }
    }

    private var asking: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            HStack {
                EyebrowText(text: "Question \(vm.history.count + 1)")
                Spacer()
                Text(vm.progress).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.textFaint)
            }
            Text(vm.currentQuestion)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textPrimary)
            OrnamentalRule()
            DecoTextField(label: "Your answer", placeholder: "Type your answer", text: $vm.currentAnswer)
            HStack(spacing: Theme.Spacing.m) {
                Button("Skip") { Task { await vm.submitAnswer() } }
                    .buttonStyle(.decoSecondary)
                Button {
                    Task { await vm.submitAnswer() }
                } label: {
                    HStack {
                        if vm.isWorking { ProgressView().tint(Theme.Colors.textOnInk) }
                        Text(vm.isWorking ? "…" : "Next")
                    }
                }
                .buttonStyle(.decoPrimary)
                .disabled(vm.isWorking)
            }
            if let error = vm.errorMessage { SafetyNote(text: error, systemImage: "exclamationmark.triangle") }
        }
    }

    private var complete: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Complete", title: "Reflection")
            FramedCard {
                Text(vm.summary)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            SafetyNote(text: SafetyText.aiGeneral)
            HStack(spacing: Theme.Spacing.m) {
                Button("Done") { dismiss() }.buttonStyle(.decoSecondary)
                Button("Save consult") {
                    assessments.saveConsult(vm.buildSession())
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
            }
        }
    }
}
