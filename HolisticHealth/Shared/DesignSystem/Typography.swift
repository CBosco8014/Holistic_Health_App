import SwiftUI

/// Ristoro typography. The design guide uses geometric Art Deco webfonts
/// (Poiret One, Bebas Neue, Jost). We map those to iOS-native geometric faces —
/// Futura for display/poster and Avenir Next for body/labels — so no fonts need
/// to be bundled while preserving the Deco character. If branded fonts are later
/// added to the bundle, only this file changes.
extension Theme {
    enum Typography {
        // Display: large, elegant, used for hero titles.
        static func display(_ size: CGFloat) -> Font { .custom("Futura-Medium", size: size) }

        // Poster: tall condensed caps for eyebrows / section banners.
        static func poster(_ size: CGFloat) -> Font { .custom("Futura-CondensedExtraBold", size: size) }

        // Body / labels.
        static func sans(_ size: CGFloat) -> Font { .custom("AvenirNext-Regular", size: size) }
        static func sansMedium(_ size: CGFloat) -> Font { .custom("AvenirNext-Medium", size: size) }
        static func sansBold(_ size: CGFloat) -> Font { .custom("AvenirNext-DemiBold", size: size) }

        // Semantic, scalable roles.
        static let largeTitle = display(34)
        static let title = display(26)
        static let sectionTitle = sansBold(18)
        static let body = sans(16)
        static let bodyMedium = sansMedium(16)
        static let callout = sans(15)
        static let label = sansMedium(14)
        static let caption = sans(13)
        static let metric = display(28)
    }
}

// MARK: - Eyebrow modifier

/// Small uppercase, wide-tracked poster label used above section titles — a
/// signature Art Deco detail.
struct EyebrowText: View {
    let text: String
    var color: Color = Theme.Colors.accentText

    var body: some View {
        Text(text.uppercased())
            .font(Theme.Typography.poster(13))
            .tracking(2.5)
            .foregroundStyle(color)
    }
}
