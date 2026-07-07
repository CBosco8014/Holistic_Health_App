import Foundation

/// Focus areas captured during onboarding; used to tailor recommendations.
enum GoalArea: String, Codable, CaseIterable, Identifiable {
    case insideOutAcne
    case hormoneHealth
    case cycleAwareness
    case nutrition
    case supplements
    case stress
    case sleep
    case exercise
    case mindfulness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .insideOutAcne: return "Inside-out acne care"
        case .hormoneHealth: return "Hormone health"
        case .cycleAwareness: return "Cycle awareness"
        case .nutrition: return "Protein-forward nutrition"
        case .supplements: return "Supplements"
        case .stress: return "Stress support"
        case .sleep: return "Sleep"
        case .exercise: return "Movement & exercise"
        case .mindfulness: return "Mindfulness"
        }
    }

    var systemImage: String {
        switch self {
        case .insideOutAcne: return "sparkles"
        case .hormoneHealth: return "waveform.path.ecg"
        case .cycleAwareness: return "moon.stars"
        case .nutrition: return "fork.knife"
        case .supplements: return "pills"
        case .stress: return "wind"
        case .sleep: return "bed.double"
        case .exercise: return "figure.run"
        case .mindfulness: return "brain.head.profile"
        }
    }
}

/// Menstrual cycle phase, used as gentle context (never as diagnosis).
enum CyclePhase: String, Codable, CaseIterable, Identifiable {
    case menstrual, follicular, ovulatory, luteal, unknown
    var id: String { rawValue }
    var displayName: String { self == .unknown ? "Not sure" : rawValue.capitalized }
}

/// The user's health profile, captured in onboarding and editable later. All
/// fields are optional so questions can be skipped.
struct UserProfile: Codable, Equatable {
    var id: UUID
    var displayName: String?
    var goals: [GoalArea]
    var cyclePhase: CyclePhase?
    var typicalCycleLength: Int?
    var dietaryNotes: String?
    var stressNotes: String?
    var sleepNotes: String?
    var onboardingCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String? = nil,
        goals: [GoalArea] = [],
        cyclePhase: CyclePhase? = nil,
        typicalCycleLength: Int? = nil,
        dietaryNotes: String? = nil,
        stressNotes: String? = nil,
        sleepNotes: String? = nil,
        onboardingCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.goals = goals
        self.cyclePhase = cyclePhase
        self.typicalCycleLength = typicalCycleLength
        self.dietaryNotes = dietaryNotes
        self.stressNotes = stressNotes
        self.sleepNotes = sleepNotes
        self.onboardingCompleted = onboardingCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Sensitive actions that require explicit, revocable consent.
enum ConsentType: String, Codable, CaseIterable, Identifiable {
    case notifications
    case sensitiveHealthData
    case aiConsultContext
    case acnePhotoReview
    case photoAnalysis
    case iCloudSync
    case providerSharing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notifications: return "Notifications"
        case .sensitiveHealthData: return "Store sensitive health data"
        case .aiConsultContext: return "Use my logs as AI context"
        case .acnePhotoReview: return "Acne photo review"
        case .photoAnalysis: return "Meal photo analysis"
        case .iCloudSync: return "iCloud sync"
        case .providerSharing: return "Share with a provider"
        }
    }
}

struct ConsentRecord: Codable, Identifiable, Equatable {
    var id: UUID
    var type: ConsentType
    var granted: Bool
    var updatedAt: Date

    init(id: UUID = UUID(), type: ConsentType, granted: Bool = false, updatedAt: Date = Date()) {
        self.id = id
        self.type = type
        self.granted = granted
        self.updatedAt = updatedAt
    }
}
