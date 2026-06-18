import SwiftUI

/// Lets the user review and edit the profile answers captured during onboarding.
struct ProfileEditView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft = UserProfile()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    SectionHeader(eyebrow: "Profile", title: "Focus areas")
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

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    SectionHeader(eyebrow: "Cycle", title: "Context")
                    FlowChips(
                        items: CyclePhase.allCases,
                        isSelected: { draft.cyclePhase == $0 },
                        label: { $0.displayName },
                        toggle: { draft.cyclePhase = (draft.cyclePhase == $0 ? nil : $0) }
                    )
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    SectionHeader(eyebrow: "Notes", title: "About you")
                    DecoTextField(label: "Name", text: Binding($draft.displayName, replacingNilWith: ""))
                    DecoTextField(label: "Nutrition notes", text: Binding($draft.dietaryNotes, replacingNilWith: ""))
                    DecoTextField(label: "Stress notes", text: Binding($draft.stressNotes, replacingNilWith: ""))
                    DecoTextField(label: "Sleep notes", text: Binding($draft.sleepNotes, replacingNilWith: ""))
                }

                Button("Save changes") {
                    draft.displayName = draft.displayName?.nilIfBlank
                    draft.dietaryNotes = draft.dietaryNotes?.nilIfBlank
                    draft.stressNotes = draft.stressNotes?.nilIfBlank
                    draft.sleepNotes = draft.sleepNotes?.nilIfBlank
                    profileStore.update(draft)
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { draft = profileStore.profile }
    }
}

#Preview {
    NavigationStack { ProfileEditView().environmentObject(ProfileStore()) }
}
