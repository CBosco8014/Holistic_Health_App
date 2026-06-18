import SwiftUI

/// A labeled input field styled for the Ristoro system: cream sunken surface
/// with a gold hairline, eyebrow-style label above.
struct DecoTextField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            EyebrowText(text: label)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.Colors.textPrimary)
            .keyboardType(keyboard)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .fill(Theme.Colors.surfaceSunk)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.small, style: .continuous)
                    .strokeBorder(Theme.Colors.goldLine, lineWidth: 1)
            )
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var key = ""
    return ZStack {
        Theme.Colors.background.ignoresSafeArea()
        VStack(spacing: 16) {
            DecoTextField(label: "Food name", placeholder: "e.g. Greek yogurt", text: $name)
            DecoTextField(label: "Gemini API key", placeholder: "Paste key", text: $key, isSecure: true)
        }
        .padding()
    }
}
