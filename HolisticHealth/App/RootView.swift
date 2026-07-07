import SwiftUI

/// The four primary destinations of the app. Order here is the order shown in
/// the bottom tab bar.
enum AppTab: String, CaseIterable, Identifiable {
    case lifestyle
    case supplements
    case macro
    case exercise

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lifestyle: return "Lifestyle"
        case .supplements: return "Supplements"
        case .macro: return "Macro"
        case .exercise: return "Exercise"
        }
    }

    /// SF Symbol used for the tab item. These are placeholders for US-001 and
    /// may be refined when the Ristoro design system lands in US-002.
    var systemImage: String {
        switch self {
        case .lifestyle: return "leaf"
        case .supplements: return "pills"
        case .macro: return "fork.knife"
        case .exercise: return "figure.run"
        }
    }
}

/// Root container: a four-tab interface plus a Settings entry point that lives
/// outside the bottom tab bar (presented modally from a toolbar control on each
/// tab's navigation bar).
struct RootView: View {
    @State private var selectedTab: AppTab = .macro
    @State private var showingSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tabContent(for: tab)
                        .navigationTitle(tab.title)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                        .accessibilityLabel("Settings")
                                }
                            }
                        }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .lifestyle: LifestyleView()
        case .supplements: SupplementsView()
        case .macro: MacroView()
        case .exercise: ExerciseView()
        }
    }
}

#Preview {
    RootView()
}
