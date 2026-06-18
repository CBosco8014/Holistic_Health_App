import SwiftUI

/// Search saved foods and pick a portion. Fully implemented in US-010 (search +
/// portion sizing) and US-011 (meal photo capture).
struct AddFoodView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "magnifyingglass",
            title: "Add Food",
            message: "Search your saved foods and adjust the serving size, or capture a meal photo.",
            eyebrow: "Macro"
        )
        .navigationTitle("Add Food")
        .navigationBarTitleDisplayMode(.inline)
    }
}
