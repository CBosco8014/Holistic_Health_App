import SwiftUI

/// Central design tokens for the Ristoro-inspired Italian Art Deco visual system.
/// Values are ported from the standalone Ristoro Design Guide so the app matches
/// the approved aesthetic: aged cream paper, midnight navy ink, antique
/// brass/gold, botanical verde, and a restrained rosso accent.
enum Theme {

    // MARK: - Colors

    enum Palette {
        // Paper (cream) family
        static let paper0 = Color(hex: "#faf4e4")
        static let paper1 = Color(hex: "#f3ead2") // primary app background
        static let paper2 = Color(hex: "#ece0bf") // sunken surface
        static let paper3 = Color(hex: "#e2d3aa")
        static let paperEdge = Color(hex: "#d3c193")
        static let surfaceRaised = Color(hex: "#fffaf0") // cards on paper

        // Midnight ink (navy) family
        static let ink0 = Color(hex: "#0e1424")
        static let ink1 = Color(hex: "#18213a") // primary text / ink surfaces
        static let ink2 = Color(hex: "#29324f")
        static let ink3 = Color(hex: "#444c68") // muted text
        static let inkSoft = Color(hex: "#6c7186") // faint text

        // Antique gold / brass family
        static let gold = Color(hex: "#b58f33")
        static let goldBright = Color(hex: "#cfa84e")
        static let goldDeep = Color(hex: "#8a6a22") // gold used as text on paper
        static let goldLeaf = Color(hex: "#e6cd86") // gold text on ink

        // Botanical verde
        static let verde = Color(hex: "#335f3c")
        static let verdeDeep = Color(hex: "#1d3a27")
        static let verdeSoft = Color(hex: "#6d8a64")

        // Restrained rosso
        static let rosso = Color(hex: "#bd4127")
        static let rossoBright = Color(hex: "#d4542f")
        static let rossoDeep = Color(hex: "#8c2c1c")

        // Lines / hairlines
        static let line = Color(hex: "#d8c79c")
        static let lineGold = Color(hex: "#b58f33").opacity(0.55)
        static let textOnInkMuted = Color(hex: "#aab0c4")
    }

    /// Semantic color roles used by views and components.
    enum Colors {
        static let background = Palette.paper1
        static let surface = Palette.surfaceRaised
        static let surfaceSunk = Palette.paper2
        static let inkSurface = Palette.ink1

        static let textPrimary = Palette.ink1
        static let textSecondary = Palette.ink3
        static let textFaint = Palette.inkSoft
        static let textOnInk = Palette.paper1
        static let textOnInkMuted = Palette.textOnInkMuted

        static let accent = Palette.gold          // decorative gold
        static let accentText = Palette.goldDeep  // gold legible as text on paper
        static let accentOnInk = Palette.goldLeaf // gold legible as text on ink

        static let success = Palette.verde
        static let danger = Palette.rosso

        static let hairline = Palette.line
        static let goldLine = Palette.lineGold
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Radius

    enum Radius {
        static let small: CGFloat = 8
        static let card: CGFloat = 14
        static let pill: CGFloat = 999
    }
}
