import Foundation

/// A cited reference surfaced in an AI assessment (when available).
struct HealthReference: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var url: String?

    init(id: UUID = UUID(), title: String, url: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
    }
}

/// A question/answer pair captured in consult and acne flows.
struct QAPair: Codable, Hashable {
    var question: String
    var answer: String
}

/// An acne flare assessment. By design the source image is NOT stored — only the
/// derived summary and context are kept.
struct AcneAssessment: Codable, Identifiable, Hashable {
    var id: UUID
    var createdAt: Date
    var summary: String
    var userAnswers: [QAPair]
    var contextualFindings: [String]
    var references: [HealthReference]
    /// Non-drug, wellness-only suggestions. Never treatment/medication.
    var wellnessSuggestions: [String]
    var notes: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        summary: String,
        userAnswers: [QAPair] = [],
        contextualFindings: [String] = [],
        references: [HealthReference] = [],
        wellnessSuggestions: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.summary = summary
        self.userAnswers = userAnswers
        self.contextualFindings = contextualFindings
        self.references = references
        self.wellnessSuggestions = wellnessSuggestions
        self.notes = notes
    }
}

/// An adaptive consult session (up to 10 one-at-a-time questions).
struct ConsultSession: Codable, Identifiable, Hashable {
    var id: UUID
    var startedAt: Date
    var completedAt: Date?
    var topicAreas: [String]
    var exchanges: [QAPair]
    /// Whether the user consented to referencing their logged patterns.
    var usesLoggedPatterns: Bool
    var summary: String?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        topicAreas: [String] = [],
        exchanges: [QAPair] = [],
        usesLoggedPatterns: Bool = false,
        summary: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.topicAreas = topicAreas
        self.exchanges = exchanges
        self.usesLoggedPatterns = usesLoggedPatterns
        self.summary = summary
    }
}

/// Data categories a user can include in a manual health assessment.
enum AssessmentCategory: String, Codable, CaseIterable, Identifiable {
    case macros, supplements, lifestyle, exercise, hormoneSkin, acne, consult
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .macros: return "Macros"
        case .supplements: return "Supplements"
        case .lifestyle: return "Lifestyle"
        case .exercise: return "Exercise"
        case .hormoneSkin: return "Hormone & Skin"
        case .acne: return "Acne"
        case .consult: return "Consult history"
        }
    }
}

/// A manually generated, editable health assessment report.
struct HealthAssessment: Codable, Identifiable, Hashable {
    var id: UUID
    var createdAt: Date
    var includedCategories: [AssessmentCategory]
    var patternSummary: String
    var possibleContributors: [String]
    var currentFocusAreas: [String]
    var activeTreatments: [String]
    var holisticTreatments: [String]
    var acnePhotoFindings: [String]
    var references: [HealthReference]
    var caveats: String
    /// User edits to the generated report (nil until edited).
    var editedReport: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        includedCategories: [AssessmentCategory] = [],
        patternSummary: String = "",
        possibleContributors: [String] = [],
        currentFocusAreas: [String] = [],
        activeTreatments: [String] = [],
        holisticTreatments: [String] = [],
        acnePhotoFindings: [String] = [],
        references: [HealthReference] = [],
        caveats: String = "",
        editedReport: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.includedCategories = includedCategories
        self.patternSummary = patternSummary
        self.possibleContributors = possibleContributors
        self.currentFocusAreas = currentFocusAreas
        self.activeTreatments = activeTreatments
        self.holisticTreatments = holisticTreatments
        self.acnePhotoFindings = acnePhotoFindings
        self.references = references
        self.caveats = caveats
        self.editedReport = editedReport
    }
}
