import Foundation

/// Categories of calming, nervous-system-supportive practices.
enum PracticeType: String, Codable, CaseIterable, Identifiable {
    case breathwork
    case meditation
    case journaling
    case gentleMovement
    case gratitude
    case grounding
    case sleepWindDown
    case screenBoundary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breathwork: return "Breathwork"
        case .meditation: return "Meditation"
        case .journaling: return "Journaling"
        case .gentleMovement: return "Gentle movement"
        case .gratitude: return "Gratitude"
        case .grounding: return "Grounding"
        case .sleepWindDown: return "Sleep wind-down"
        case .screenBoundary: return "Screen boundary"
        }
    }

    var systemImage: String {
        switch self {
        case .breathwork: return "wind"
        case .meditation: return "brain.head.profile"
        case .journaling: return "book.closed"
        case .gentleMovement: return "figure.cooldown"
        case .gratitude: return "heart"
        case .grounding: return "leaf"
        case .sleepWindDown: return "moon.stars"
        case .screenBoundary: return "iphone.slash"
        }
    }
}

/// A recommended practice the user can save and complete.
struct LifestylePractice: Codable, Identifiable, Hashable {
    var id: UUID
    var type: PracticeType
    var title: String
    var detail: String
    var durationMinutes: Int?

    init(id: UUID = UUID(), type: PracticeType, title: String, detail: String, durationMinutes: Int? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.detail = detail
        self.durationMinutes = durationMinutes
    }
}

enum PracticeStatus: String, Codable, CaseIterable {
    case saved, started, completed, skipped
}

/// A record of an interaction with a practice (saved/started/completed/skipped),
/// stored for trend and assessment use.
struct LifestylePracticeLog: Codable, Identifiable, Hashable {
    var id: UUID
    var practiceID: UUID
    var practiceType: PracticeType
    var status: PracticeStatus
    var rating: Int?          // 1...5, optional
    var occurredAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        practiceID: UUID,
        practiceType: PracticeType,
        status: PracticeStatus,
        rating: Int? = nil,
        occurredAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.practiceID = practiceID
        self.practiceType = practiceType
        self.status = status
        self.rating = rating
        self.occurredAt = occurredAt
        self.notes = notes
    }
}
