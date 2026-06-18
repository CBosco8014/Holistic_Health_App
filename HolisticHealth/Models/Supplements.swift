import Foundation

enum AdherenceState: String, Codable, CaseIterable, Identifiable {
    case taking, paused, discontinued
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

/// A supplement the user tracks. Dosage/schedule/timing are free text so the app
/// never prescribes amounts.
struct Supplement: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var dosageNotes: String?
    var schedule: String?       // e.g. "Daily", "Mon/Wed/Fri"
    var timing: String?         // e.g. "With breakfast"
    var reason: String?
    var adherence: AdherenceState
    var startDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        dosageNotes: String? = nil,
        schedule: String? = nil,
        timing: String? = nil,
        reason: String? = nil,
        adherence: AdherenceState = .taking,
        startDate: Date? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dosageNotes = dosageNotes
        self.schedule = schedule
        self.timing = timing
        self.reason = reason
        self.adherence = adherence
        self.startDate = startDate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// A daily adherence log for a supplement.
struct SupplementLogEntry: Codable, Identifiable, Hashable {
    var id: UUID
    var supplementID: UUID
    var date: Date
    var taken: Bool
    var notes: String?

    init(id: UUID = UUID(), supplementID: UUID, date: Date = Date(), taken: Bool = true, notes: String? = nil) {
        self.id = id
        self.supplementID = supplementID
        self.date = date
        self.taken = taken
        self.notes = notes
    }
}

/// A careful, non-diagnostic suggestion of a nutrient area to consider. Produced
/// by the AI layer; never claims a deficiency.
struct NutrientSuggestion: Codable, Identifiable, Hashable {
    var id: UUID
    var area: String                 // e.g. "Zinc", "Omega-3"
    var rationale: String
    var relevantInputs: [String]
    var safetyNotes: String
    var clinicianQuestions: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        area: String,
        rationale: String,
        relevantInputs: [String] = [],
        safetyNotes: String,
        clinicianQuestions: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.area = area
        self.rationale = rationale
        self.relevantInputs = relevantInputs
        self.safetyNotes = safetyNotes
        self.clinicianQuestions = clinicianQuestions
        self.createdAt = createdAt
    }
}
