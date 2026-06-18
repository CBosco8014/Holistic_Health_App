import SwiftUI

/// Create or edit a hormone & skin check-in. All measures are optional so users
/// can log only what's relevant. Language is pattern-based, never diagnostic.
struct CheckInView: View {
    @EnvironmentObject private var store: CheckInStore
    @Environment(\.dismiss) private var dismiss

    var existing: HormoneSkinCheckIn?
    @State private var draft = HormoneSkinCheckIn()
    @State private var newSymptom = ""
    @State private var trackCycleDay = false

    private let acneLocations = ["Forehead", "Cheeks", "Jaw", "Chin", "Nose", "Back", "Chest"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                cycleSection
                skinSection
                signalsSection
                customSection
                notesSection

                SafetyNote(text: "Notice patterns over time — these notes are for reflection, not diagnosis.")

                Button("Save check-in") {
                    store.save(draft)
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle(existing == nil ? "New Check-In" : "Edit Check-In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        .onAppear { if let existing { draft = existing; trackCycleDay = existing.cycleDay != nil } }
    }

    private var cycleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Cycle", title: "Where are you?")
            FlowChips(items: CyclePhase.allCases,
                      isSelected: { draft.cyclePhase == $0 },
                      label: { $0.displayName },
                      toggle: { draft.cyclePhase = (draft.cyclePhase == $0 ? nil : $0) })
            Toggle("Track cycle day", isOn: $trackCycleDay)
                .font(Theme.Typography.body)
                .tint(Theme.Colors.accent)
                .onChange(of: trackCycleDay) { _, on in draft.cycleDay = on ? (draft.cycleDay ?? 1) : nil }
            if trackCycleDay {
                Stepper(value: Binding(get: { draft.cycleDay ?? 1 }, set: { draft.cycleDay = $0 }), in: 1...40) {
                    Text("Cycle day: \(draft.cycleDay ?? 1)")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
        }
    }

    private var skinSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Skin", title: "Acne today")
            RatingSelector(label: "Severity (0 calm – 5 flaring)", value: $draft.acneSeverity)
            VStack(alignment: .leading, spacing: 6) {
                EyebrowText(text: "Locations")
                FlowChips(items: acneLocations,
                          isSelected: { draft.acneLocations.contains($0) },
                          label: { $0 },
                          toggle: { loc in
                              if let i = draft.acneLocations.firstIndex(of: loc) { draft.acneLocations.remove(at: i) }
                              else { draft.acneLocations.append(loc) }
                          })
            }
        }
    }

    private var signalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Signals", title: "How you feel")
            RatingSelector(label: "Mood", value: $draft.mood)
            RatingSelector(label: "Energy", value: $draft.energy)
            RatingSelector(label: "Cravings", value: $draft.cravings)
            RatingSelector(label: "Digestion", value: $draft.digestion)
            RatingSelector(label: "Bloating", value: $draft.bloating)
            RatingSelector(label: "Sleep quality", value: $draft.sleepQuality)
            RatingSelector(label: "Stress", value: $draft.stress)
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Custom", title: "Other symptoms")
            HStack {
                DecoTextField(label: "Add a symptom", placeholder: "e.g. headache", text: $newSymptom)
                Button {
                    if let s = newSymptom.nilIfBlank { draft.customSymptoms.append(s); newSymptom = "" }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.decoSecondary)
                .frame(width: 56)
            }
            if !draft.customSymptoms.isEmpty {
                WrapLayout {
                    ForEach(draft.customSymptoms, id: \.self) { symptom in
                        Button { draft.customSymptoms.removeAll { $0 == symptom } } label: {
                            HStack(spacing: 4) {
                                Text(symptom)
                                Image(systemName: "xmark.circle.fill")
                            }
                            .font(Theme.Typography.sansMedium(13))
                            .foregroundStyle(Theme.Colors.accentText)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(Theme.Colors.surface))
                            .overlay(Capsule().strokeBorder(Theme.Colors.goldLine, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            SectionHeader(eyebrow: "Notes", title: "Observations")
            DecoTextField(label: "Free text", placeholder: "Anything you noticed today",
                          text: Binding($draft.notes, replacingNilWith: ""))
        }
    }
}

#Preview {
    NavigationStack { CheckInView() }.environmentObject(CheckInStore())
}
