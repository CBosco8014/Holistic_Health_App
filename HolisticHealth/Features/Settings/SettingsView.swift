import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                SectionHeader(eyebrow: "You", title: "Profile & Goals")
                NavigationLink {
                    ProfileEditView()
                } label: {
                    SettingsRow(systemImage: "person.crop.circle",
                                title: "Edit profile",
                                subtitle: "Goals, cycle context, and notes")
                }

                SectionHeader(eyebrow: "Intelligence", title: "AI & Costs")
                NavigationLink {
                    GeminiSettingsView()
                } label: {
                    SettingsRow(systemImage: "sparkles",
                                title: "Gemini & usage",
                                subtitle: "API key, model, and cost tracking")
                }

                SectionHeader(eyebrow: "Data", title: "Privacy")
                NavigationLink {
                    PrivacyView()
                } label: {
                    SettingsRow(systemImage: "lock.shield",
                                title: "Privacy & data",
                                subtitle: "Export, deletion, and consent")
                }
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

/// A tappable row styled as a framed card.
struct SettingsRow: View {
    let systemImage: String
    let title: String
    var subtitle: String? = nil
    var disabled: Bool = false

    var body: some View {
        FramedCard(padding: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Theme.Colors.accentText)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if let subtitle {
                        Text(disabled ? "\(subtitle) · coming soon" : subtitle)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textFaint)
                    }
                }
                Spacer()
                if !disabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textFaint)
                }
            }
        }
        .opacity(disabled ? 0.6 : 1)
    }
}

#Preview {
    NavigationStack { SettingsView().environmentObject(ProfileStore()) }
}
