import SwiftUI

struct ExerciseView: View {
    var body: some View {
        PlaceholderScreen(
            systemImage: "figure.run",
            title: "Exercise",
            message: "Log weightlifting and sprint-burst sessions by intensity and duration here."
        )
    }
}

#Preview {
    NavigationStack { ExerciseView() }
}
