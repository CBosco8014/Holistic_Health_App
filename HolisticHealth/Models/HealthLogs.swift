import Foundation

/// A hormone & skin check-in. All measures are optional 0–5 self-ratings except
/// where noted, so users can log only what's relevant.
struct HormoneSkinCheckIn: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var cycleDay: Int?
    var cyclePhase: CyclePhase?
    var acneSeverity: Int?         // 0...5
    var acneLocations: [String]
    var mood: Int?
    var energy: Int?
    var cravings: Int?
    var digestion: Int?
    var bloating: Int?
    var sleepQuality: Int?
    var stress: Int?
    var customSymptoms: [String]
    var notes: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        cycleDay: Int? = nil,
        cyclePhase: CyclePhase? = nil,
        acneSeverity: Int? = nil,
        acneLocations: [String] = [],
        mood: Int? = nil,
        energy: Int? = nil,
        cravings: Int? = nil,
        digestion: Int? = nil,
        bloating: Int? = nil,
        sleepQuality: Int? = nil,
        stress: Int? = nil,
        customSymptoms: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.cycleDay = cycleDay
        self.cyclePhase = cyclePhase
        self.acneSeverity = acneSeverity
        self.acneLocations = acneLocations
        self.mood = mood
        self.energy = energy
        self.cravings = cravings
        self.digestion = digestion
        self.bloating = bloating
        self.sleepQuality = sleepQuality
        self.stress = stress
        self.customSymptoms = customSymptoms
        self.notes = notes
    }
}

/// A generic symptom log entry (for symptoms outside the structured check-in).
struct SymptomLog: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var name: String
    var severity: Int?     // 0...5
    var notes: String?

    init(id: UUID = UUID(), date: Date = Date(), name: String, severity: Int? = nil, notes: String? = nil) {
        self.id = id
        self.date = date
        self.name = name
        self.severity = severity
        self.notes = notes
    }
}

/// A standalone acne log entry for trend tracking.
struct AcneLog: Codable, Identifiable, Hashable {
    var id: UUID
    var date: Date
    var severity: Int          // 0...5
    var locations: [String]
    var notes: String?

    init(id: UUID = UUID(), date: Date = Date(), severity: Int, locations: [String] = [], notes: String? = nil) {
        self.id = id
        self.date = date
        self.severity = severity
        self.locations = locations
        self.notes = notes
    }
}
