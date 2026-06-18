import SwiftUI

struct LifestyleView: View {
    @EnvironmentObject private var checkInStore: CheckInStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                checkInSection
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Lifestyle")
    }

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

            let recent = checkInStore.recent(7).filter { !($0.id == checkInStore.todays()?.id) }
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
    NavigationStack { LifestyleView() }.environmentObject(CheckInStore())
}
