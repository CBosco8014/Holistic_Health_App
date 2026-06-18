import SwiftUI

/// First-run onboarding. Captures goals across the MVP focus areas, optional
/// cycle context, and optional notes. Optional questions can be skipped, and
/// everything is editable later from Settings → Profile.
struct OnboardingView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var step = 0
    @State private var draft = UserProfile()

    private let stepCount = 4

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    switch step {
                    case 0: welcomeStep
                    case 1: goalsStep
                    case 2: cycleStep
                    default: notesStep
                    }
                }
                .padding(Theme.Spacing.l)
            }
            footer
        }
        .decoBackground()
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            EyebrowText(text: "Welcome")
            Text("A calm, inside-out approach to skin & hormone health")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textPrimary)
            OrnamentalRule()
            Text("We'll ask a few optional questions to tailor your experience. You can skip anything and change it later.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
            SafetyNote(text: SafetyText.onboarding)
        }
    }

    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Step 1", title: "What would you like to focus on?")
            Text("Choose any that apply.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
            FlowChips(
                items: GoalArea.allCases,
                isSelected: { draft.goals.contains($0) },
                label: { $0.title },
                icon: { $0.systemImage },
                toggle: { goal in
                    if let idx = draft.goals.firstIndex(of: goal) {
                        draft.goals.remove(at: idx)
                    } else {
                        draft.goals.append(goal)
                    }
                }
            )
        }
    }

    private var cycleStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Step 2 · Optional", title: "Cycle context")
            Text("Used only as gentle context — never as a diagnosis.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                EyebrowText(text: "Current phase")
                FlowChips(
                    items: CyclePhase.allCases,
                    isSelected: { draft.cyclePhase == $0 },
                    label: { $0.displayName },
                    icon: { _ in nil },
                    toggle: { draft.cyclePhase = (draft.cyclePhase == $0 ? nil : $0) }
                )
            }

            Stepper(value: Binding(
                get: { draft.typicalCycleLength ?? 28 },
                set: { draft.typicalCycleLength = $0 }
            ), in: 20...40) {
                Text("Typical cycle length: \(draft.typicalCycleLength ?? 28) days")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
        }
    }

    private var notesStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Step 3 · Optional", title: "Anything else?")
            DecoTextField(label: "Your name (optional)", placeholder: "e.g. Maya",
                          text: Binding($draft.displayName, replacingNilWith: ""))
            DecoTextField(label: "Nutrition notes", placeholder: "e.g. dairy-sensitive, plant-forward",
                          text: Binding($draft.dietaryNotes, replacingNilWith: ""))
            DecoTextField(label: "Stress notes", placeholder: "e.g. busy season at work",
                          text: Binding($draft.stressNotes, replacingNilWith: ""))
            DecoTextField(label: "Sleep notes", placeholder: "e.g. ~6 hrs, hard to wind down",
                          text: Binding($draft.sleepNotes, replacingNilWith: ""))
        }
    }

    // MARK: - Chrome

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.Colors.surfaceSunk)
                Rectangle().fill(Theme.Colors.accent)
                    .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(stepCount))
            }
        }
        .frame(height: 3)
    }

    private var footer: some View {
        HStack(spacing: Theme.Spacing.m) {
            if step > 0 {
                Button("Back") { withAnimation { step -= 1 } }
                    .buttonStyle(.decoSecondary)
            }
            if step >= 1 && step < stepCount - 1 {
                Button("Skip") { withAnimation { advance() } }
                    .buttonStyle(.decoSecondary)
            }
            Button(step == stepCount - 1 ? "Finish" : "Continue") {
                withAnimation { advance() }
            }
            .buttonStyle(.decoPrimary)
        }
        .padding(Theme.Spacing.l)
        .background(Theme.Colors.background)
    }

    private func advance() {
        if step < stepCount - 1 {
            step += 1
        } else {
            finish()
        }
    }

    private func finish() {
        draft.onboardingCompleted = true
        // Trim empty optional strings to nil.
        draft.displayName = draft.displayName?.nilIfBlank
        draft.dietaryNotes = draft.dietaryNotes?.nilIfBlank
        draft.stressNotes = draft.stressNotes?.nilIfBlank
        draft.sleepNotes = draft.sleepNotes?.nilIfBlank
        profileStore.update(draft)
    }
}

#Preview {
    OnboardingView().environmentObject(ProfileStore())
}
