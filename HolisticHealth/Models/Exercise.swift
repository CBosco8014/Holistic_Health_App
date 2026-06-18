import Foundation

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case weightlifting
    case sprintBurst
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .weightlifting: return "Weightlifting"
        case .sprintBurst: return "Sprint Burst"
        }
    }
}

enum ExerciseIntensity: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

/// Sprint-burst activities supported in the MVP.
enum SprintActivity: String, Codable, CaseIterable, Identifiable {
    case running, stationaryBike, rowing, boxing
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .stationaryBike: return "Stationary Bike"
        case .rowing: return "Rowing"
        case .boxing: return "Boxing"
        }
    }
    var systemImage: String {
        switch self {
        case .running: return "figure.run"
        case .stationaryBike: return "figure.indoor.cycle"
        case .rowing: return "figure.rower"
        case .boxing: return "figure.boxing"
        }
    }
}

/// A logged exercise session. Intentionally lightweight — no individual lifts,
/// sets, reps, calorie-burn, or deficit calculations in the MVP.
struct ExerciseSession: Codable, Identifiable, Hashable {
    var id: UUID
    var category: ExerciseCategory
    var activity: SprintActivity?          // set for sprint-burst
    var intensity: ExerciseIntensity?      // set for weightlifting
    var durationMinutes: Int
    var timestamp: Date
    var notes: String?
    var source: String                     // e.g. "manual"

    init(
        id: UUID = UUID(),
        category: ExerciseCategory,
        activity: SprintActivity? = nil,
        intensity: ExerciseIntensity? = nil,
        durationMinutes: Int,
        timestamp: Date = Date(),
        notes: String? = nil,
        source: String = "manual"
    ) {
        self.id = id
        self.category = category
        self.activity = activity
        self.intensity = intensity
        self.durationMinutes = durationMinutes
        self.timestamp = timestamp
        self.notes = notes
        self.source = source
    }
}
