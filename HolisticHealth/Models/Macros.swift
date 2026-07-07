import Foundation

/// Macro nutrients for a food. The product is a *macro* tracker: protein, carbs,
/// and fat are primary; calories are secondary data only.
struct MacroNutrients: Codable, Hashable {
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
    /// Secondary only — never used for deficit/burn framing.
    var calories: Double

    init(proteinGrams: Double = 0, carbGrams: Double = 0, fatGrams: Double = 0, calories: Double = 0) {
        self.proteinGrams = proteinGrams
        self.carbGrams = carbGrams
        self.fatGrams = fatGrams
        self.calories = calories
    }

    static let zero = MacroNutrients()

    /// Scales every value by a multiplier (used for portion sizing).
    func scaled(by factor: Double) -> MacroNutrients {
        MacroNutrients(
            proteinGrams: proteinGrams * factor,
            carbGrams: carbGrams * factor,
            fatGrams: fatGrams * factor,
            calories: calories * factor
        )
    }

    static func + (lhs: MacroNutrients, rhs: MacroNutrients) -> MacroNutrients {
        MacroNutrients(
            proteinGrams: lhs.proteinGrams + rhs.proteinGrams,
            carbGrams: lhs.carbGrams + rhs.carbGrams,
            fatGrams: lhs.fatGrams + rhs.fatGrams,
            calories: lhs.calories + rhs.calories
        )
    }
}

/// Where a food record originated. Drives confidence and review behavior.
enum FoodSource: String, Codable, CaseIterable {
    case manual
    case geminiText
    case geminiPhoto
    case geminiMenu
    case imported
    case builtIn
}

/// Whether a record's macros have been confirmed by the user.
enum ConfirmationState: String, Codable, CaseIterable {
    case confirmed       // user-verified, safe to log directly
    case needsReview     // AI estimate awaiting confirmation
    case estimated       // saved estimate, may be refined
}

enum MealCategory: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

/// A reusable food record in the local JSON macro library. These accumulate over
/// time to form the user's custom food database. Macros are stored *per serving*
/// as described by `servingDescription`.
struct MacroLibraryRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var canonicalName: String
    var aliases: [String]
    var servingDescription: String
    var macros: MacroNutrients
    var source: FoodSource
    var confidence: Double?          // 0...1 when AI-estimated
    var confirmation: ConfirmationState
    var createdAt: Date
    var updatedAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        canonicalName: String,
        aliases: [String] = [],
        servingDescription: String,
        macros: MacroNutrients,
        source: FoodSource = .manual,
        confidence: Double? = nil,
        confirmation: ConfirmationState = .confirmed,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.canonicalName = canonicalName
        self.aliases = aliases
        self.servingDescription = servingDescription
        self.macros = macros
        self.source = source
        self.confidence = confidence
        self.confirmation = confirmation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
    }
}

/// A single entry in the daily food log. Separate from the reusable library; it
/// may reference a library record when one exists, and stores the macros already
/// scaled to the logged amount.
struct MealLogEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var libraryRecordID: UUID?
    var foodName: String
    /// Multiplier relative to one serving (1.0 == one serving).
    var servingAmount: Double
    var servingDescription: String
    var macros: MacroNutrients     // already scaled to servingAmount
    var category: MealCategory
    var loggedAt: Date
    var source: FoodSource
    var notes: String?

    init(
        id: UUID = UUID(),
        libraryRecordID: UUID? = nil,
        foodName: String,
        servingAmount: Double = 1.0,
        servingDescription: String,
        macros: MacroNutrients,
        category: MealCategory = .snack,
        loggedAt: Date = Date(),
        source: FoodSource = .manual,
        notes: String? = nil
    ) {
        self.id = id
        self.libraryRecordID = libraryRecordID
        self.foodName = foodName
        self.servingAmount = servingAmount
        self.servingDescription = servingDescription
        self.macros = macros
        self.category = category
        self.loggedAt = loggedAt
        self.source = source
        self.notes = notes
    }
}
