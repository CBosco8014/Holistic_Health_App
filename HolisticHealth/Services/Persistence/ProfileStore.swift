import Foundation
import Combine

/// Holds the user's health profile and consent records, persisted locally.
/// Injected as an environment object so every workflow (Lifestyle, Supplements,
/// Macro, Acne Review, Consult, Health Assessment) can read profile context.
@MainActor
final class ProfileStore: ObservableObject {
    @Published var profile: UserProfile
    @Published var consents: [ConsentRecord]

    private let persistence: DataPersisting
    private let profileFile: String
    private let consentFile: String

    init(
        persistence: DataPersisting = FileDataStore(),
        profileFile: String = "profile.json",
        consentFile: String = "consents.json"
    ) {
        self.persistence = persistence
        self.profileFile = profileFile
        self.consentFile = consentFile
        self.profile = (try? persistence.load(UserProfile.self, from: profileFile)) ?? UserProfile()
        self.consents = (try? persistence.load([ConsentRecord].self, from: consentFile)) ?? []
    }

    // MARK: - Profile

    /// Persists the current profile (call after editing fields).
    func save() {
        profile.updatedAt = Date()
        try? persistence.save(profile, to: profileFile)
    }

    /// Replaces the whole profile (used by onboarding completion) and saves.
    func update(_ newProfile: UserProfile) {
        profile = newProfile
        save()
    }

    func completeOnboarding() {
        profile.onboardingCompleted = true
        save()
    }

    var hasCompletedOnboarding: Bool { profile.onboardingCompleted }

    // MARK: - Consent

    func isGranted(_ type: ConsentType) -> Bool {
        consents.first { $0.type == type }?.granted ?? false
    }

    func setConsent(_ type: ConsentType, granted: Bool) {
        if let idx = consents.firstIndex(where: { $0.type == type }) {
            consents[idx].granted = granted
            consents[idx].updatedAt = Date()
        } else {
            consents.append(ConsentRecord(type: type, granted: granted))
        }
        try? persistence.save(consents, to: consentFile)
    }

    // MARK: - Reset (used by privacy/data deletion)

    func resetProfile() {
        profile = UserProfile()
        consents = []
        try? persistence.save(profile, to: profileFile)
        try? persistence.save(consents, to: consentFile)
    }
}
