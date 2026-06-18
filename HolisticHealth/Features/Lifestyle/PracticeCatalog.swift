import Foundation

/// A curated catalog of calming practices and a data-reactive recommender. The
/// recommender adapts ordering to the user's goals and most recent check-in
/// (stress, sleep, mood) — never with hype or shame, just gentle relevance.
enum PracticeCatalog {
    /// One representative practice per type.
    static let all: [LifestylePractice] = [
        LifestylePractice(type: .breathwork, title: "Box breathing",
                          detail: "Inhale 4, hold 4, exhale 4, hold 4. Repeat to settle the nervous system.",
                          durationMinutes: 5),
        LifestylePractice(type: .meditation, title: "Body-scan meditation",
                          detail: "Move attention slowly from head to toe, softening as you go.",
                          durationMinutes: 10),
        LifestylePractice(type: .journaling, title: "Brain dump",
                          detail: "Write whatever's on your mind for a few minutes — no editing.",
                          durationMinutes: 8),
        LifestylePractice(type: .gentleMovement, title: "Gentle stretch flow",
                          detail: "A slow, kind sequence to release tension.",
                          durationMinutes: 10),
        LifestylePractice(type: .gratitude, title: "Three good things",
                          detail: "Note three small things that went okay today.",
                          durationMinutes: 3),
        LifestylePractice(type: .grounding, title: "5-4-3-2-1 grounding",
                          detail: "Name 5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste.",
                          durationMinutes: 4),
        LifestylePractice(type: .sleepWindDown, title: "Wind-down ritual",
                          detail: "Dim lights, warm tea, and a few slow breaths before bed.",
                          durationMinutes: 15),
        LifestylePractice(type: .screenBoundary, title: "Screen sunset",
                          detail: "Set screens aside 30 minutes before sleep.",
                          durationMinutes: 5)
    ]

    /// Returns practices ordered by relevance to the profile + latest check-in.
    static func recommended(profile: UserProfile, latest: HormoneSkinCheckIn?, limit: Int = 4) -> [LifestylePractice] {
        all
            .map { ($0, score($0.type, profile: profile, latest: latest)) }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.title < $1.0.title }
            .prefix(limit)
            .map { $0.0 }
    }

    /// Relevance score for a practice type (higher = more relevant now).
    static func score(_ type: PracticeType, profile: UserProfile, latest: HormoneSkinCheckIn?) -> Int {
        var score = 0
        let highStress = (latest?.stress ?? 0) >= 4
        let lowSleep = (latest?.sleepQuality ?? 5) <= 2
        let lowMood = (latest?.mood ?? 5) <= 2

        switch type {
        case .breathwork, .grounding:
            if highStress { score += 3 }
            if profile.goals.contains(.stress) { score += 2 }
        case .meditation:
            if highStress { score += 2 }
            if profile.goals.contains(.mindfulness) { score += 2 }
        case .journaling, .gratitude:
            if lowMood { score += 3 }
            if profile.goals.contains(.mindfulness) { score += 1 }
        case .gentleMovement:
            if lowMood { score += 2 }
            if profile.goals.contains(.exercise) { score += 1 }
        case .sleepWindDown, .screenBoundary:
            if lowSleep { score += 3 }
            if profile.goals.contains(.sleep) { score += 2 }
        }
        return score
    }
}
