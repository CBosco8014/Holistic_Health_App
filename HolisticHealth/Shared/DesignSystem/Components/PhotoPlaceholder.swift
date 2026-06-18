import SwiftUI

/// A photo placeholder / drop target used by meal-photo, menu, and acne-flare
/// capture flows before an image is provided.
struct PhotoPlaceholder: View {
    var systemImage: String = "camera"
    var title: String = "Add a photo"
    var subtitle: String? = nil
    var height: CGFloat = 180

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Theme.Colors.accentText)
            Text(title)
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.textSecondary)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textFaint)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Colors.surfaceSunk)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
                .foregroundStyle(Theme.Colors.goldLine)
        )
    }
}

#Preview {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()
        PhotoPlaceholder(subtitle: "Photos are not stored by default").padding()
    }
}
