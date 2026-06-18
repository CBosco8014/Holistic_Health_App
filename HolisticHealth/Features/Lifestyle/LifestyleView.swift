import SwiftUI

struct LifestyleView: View {
    @EnvironmentObject private var checkInStore: CheckInStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var lifestyleStore: LifestyleStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                practicesSection
                checkInSection
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Lifestyle")
    }

    // MARK: - Practices

    private var practicesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Practices", title: "Suggested for you")
            Text("Gentle, nervous-system-friendly practices, chosen from how you've been feeling.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            let recommended = PracticeCatalog.recommended(
                profile: profileStore.profile,
                latest: checkInStore.latest
            )
            ForEach(recommended) { practice in
                PracticeCard(practice: practice,
                             todaysStatus: lifestyleStore.todaysStatus(for: practice.type)) { status, rating in
                    lifestyleStore.record(practice, status: status, rating: rating)
                }
            }

            if lifestyleStore.completedCount > 0 {
                Text("\(lifestyleStore.completedCount) practice\(lifestyleStore.completedCount == 1 ? "" : "s") completed so far — lovely.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
            }
        }
    }

    // MARK: - Check-in

    private var checkInSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(eyebrow: "Daily", title: "Hormone & Skin Check-In")

            if let today = checkInStore.todays() {
                NavigationLink { CheckInView(existing: today) } label: {
                    CheckInRow(checkIn: today)
                }
                .buttonStyle(.plain)
                Text("You've checked in today — tap to update.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
            } else {
                NavigationLink { CheckInView() } label: {
                    MacroActionTile(systemImage: "heart.text.square",
                                    title: "New check-in",
                                    subtitle: "Log cycle, skin, mood & more")
                }
                .buttonStyle(.plain)
            }

            let recent = checkInStore.recent(7).filter { $0.id != checkInStore.todays()?.id }
            if !recent.isEmpty {
                SectionHeader(eyebrow: "History", title: "Recent")
                ForEach(recent) { entry in
                    NavigationLink { CheckInView(existing: entry) } label: {
                        CheckInRow(checkIn: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { LifestyleView() }
        .environmentObject(CheckInStore())
        .environmentObject(ProfileStore())
        .environmentObject(LifestyleStore())
}
