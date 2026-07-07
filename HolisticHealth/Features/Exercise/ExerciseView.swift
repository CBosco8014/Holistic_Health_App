import SwiftUI

/// The Exercise tab — quick logging of weightlifting (by intensity) and
/// sprint-burst activities, each by duration. No lifts/sets/reps, calorie-burn,
/// or deficit math in the MVP.
struct ExerciseView: View {
    @EnvironmentObject private var store: ExerciseStore

    @State private var category: ExerciseCategory = .weightlifting
    @State private var intensity: ExerciseIntensity = .medium
    @State private var activity: SprintActivity = .running
    @State private var duration: Double = 20   // minutes

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                summaryCard
                logSection
                todaySection
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Exercise")
    }

    // MARK: - Summary

    private var summaryCard: some View {
        InkPanel {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                EyebrowText(text: "Today", color: Theme.Colors.accentOnInk)
                HStack(alignment: .bottom, spacing: Theme.Spacing.s) {
                    MacroStat(value: Double(store.totalMinutes()), label: "Minutes",
                              emphasized: true, tint: Theme.Colors.accentOnInk)
                    Divider().frame(height: 44).overlay(Theme.Colors.accentOnInk.opacity(0.3))
                    MacroStat(value: Double(store.sessions().count), label: "Sessions",
                              tint: Theme.Colors.textOnInk)
                }
            }
        }
    }

    // MARK: - Log form

    private var logSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Log", title: "Add a session")

            FlowChips(items: ExerciseCategory.allCases,
                      isSelected: { category == $0 },
                      label: { $0.displayName },
                      toggle: { category = $0 })

            if category == .weightlifting {
                VStack(alignment: .leading, spacing: 6) {
                    EyebrowText(text: "Intensity")
                    FlowChips(items: ExerciseIntensity.allCases,
                              isSelected: { intensity == $0 },
                              label: { $0.displayName },
                              toggle: { intensity = $0 })
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    EyebrowText(text: "Activity")
                    FlowChips(items: SprintActivity.allCases,
                              isSelected: { activity == $0 },
                              label: { $0.displayName },
                              icon: { $0.systemImage },
                              toggle: { activity = $0 })
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    EyebrowText(text: "Duration")
                    Spacer()
                    Text("\(Int(duration)) min")
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.accentText)
                }
                Slider(value: $duration, in: 5...60, step: 5)
                    .tint(Theme.Colors.accent)
                Text("5 to 60 minutes, in 5-minute steps")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
            }

            Button("Save session") { save() }
                .buttonStyle(.decoPrimary)
        }
    }

    private func save() {
        store.add(ExerciseSession(
            category: category,
            activity: category == .sprintBurst ? activity : nil,
            intensity: category == .weightlifting ? intensity : nil,
            durationMinutes: Int(duration)
        ))
    }

    // MARK: - Today's sessions

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Today", title: "Sessions")
            let todays = store.sessions()
            if todays.isEmpty {
                FramedCard {
                    Text("No sessions yet today. Log weightlifting or a sprint-burst above.")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(todays) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: ExerciseSession) -> some View {
        FramedCard(padding: Theme.Spacing.m) {
            HStack {
                Image(systemName: icon(for: session))
                    .foregroundStyle(Theme.Colors.accentText)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title(for: session))
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("\(session.durationMinutes) min")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textFaint)
                }
                Spacer()
                Button(role: .destructive) { store.remove(session) } label: {
                    Image(systemName: "trash").foregroundStyle(Theme.Colors.danger)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func title(for session: ExerciseSession) -> String {
        switch session.category {
        case .weightlifting:
            return "Weightlifting · \(session.intensity?.displayName ?? "")"
        case .sprintBurst:
            return "Sprint · \(session.activity?.displayName ?? "")"
        }
    }

    private func icon(for session: ExerciseSession) -> String {
        switch session.category {
        case .weightlifting: return "dumbbell"
        case .sprintBurst: return session.activity?.systemImage ?? "figure.run"
        }
    }
}

#Preview {
    NavigationStack { ExerciseView() }.environmentObject(ExerciseStore())
}
