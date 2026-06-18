import SwiftUI

/// Meal photo / upload macro capture. Fully implemented in US-011.
struct MealPhotoView: View {
    let library: MacroLibraryStore
    let mealLog: MealLogStore
    let aiConfig: AIConfigStore

    var body: some View {
        PlaceholderScreen(
            systemImage: "camera",
            title: "Meal Photo",
            message: "Take or upload a meal photo and confirm itemized macros.",
            eyebrow: "Macro"
        )
        .navigationTitle("Meal Photo")
        .navigationBarTitleDisplayMode(.inline)
    }
}
