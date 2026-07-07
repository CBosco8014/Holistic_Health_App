import Foundation
import Combine

/// A summary of estimated Gemini spend. All values are estimates, never bills.
struct CostSummary: Equatable {
    var today: Double
    var last7Days: Double
    var averagePerActiveDay: Double
    var total: Double
    var eventCount: Int
}

/// Holds AI configuration (selected model + API-key presence) and the AI usage
/// event log, with cost summaries. The API key itself lives only in the
/// Keychain; this store exposes presence and read-on-demand, never persists the
/// secret in JSON or includes it in exports.
@MainActor
final class AIConfigStore: ObservableObject {
    @Published private(set) var settings: AISettings
    @Published private(set) var usageEvents: [APIUsageEvent]

    private let persistence: DataPersisting
    private let keychainAccount: String
    private let settingsFile: String
    private let usageFile: String

    init(
        persistence: DataPersisting = FileDataStore(),
        keychainAccount: String = KeychainService.geminiKeyAccount,
        settingsFile: String = "ai_settings.json",
        usageFile: String = "usage_events.json"
    ) {
        self.persistence = persistence
        self.keychainAccount = keychainAccount
        self.settingsFile = settingsFile
        self.usageFile = usageFile

        var loaded = (try? persistence.load(AISettings.self, from: settingsFile)) ?? AISettings()
        loaded.hasAPIKey = KeychainService.read(account: keychainAccount) != nil
        self.settings = loaded
        self.usageEvents = (try? persistence.load([APIUsageEvent].self, from: usageFile)) ?? []
    }

    // MARK: - Model selection

    var selectedModel: GeminiModel { settings.selectedModel }

    func selectModel(_ model: GeminiModel) {
        settings.selectedModel = model
        persistSettings()
    }

    // MARK: - API key (Keychain-backed)

    var hasAPIKey: Bool { settings.hasAPIKey }

    /// Reads the key on demand (used by the AI service). Avoid holding it.
    func apiKey() -> String? {
        KeychainService.read(account: keychainAccount)
    }

    @discardableResult
    func saveAPIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let ok = KeychainService.save(trimmed, account: keychainAccount)
        if ok {
            settings.hasAPIKey = true
            persistSettings()
        }
        return ok
    }

    func clearAPIKey() {
        KeychainService.delete(account: keychainAccount)
        settings.hasAPIKey = false
        persistSettings()
    }

    // MARK: - Usage

    func record(_ event: APIUsageEvent) {
        usageEvents.append(event)
        try? persistence.save(usageEvents, to: usageFile)
    }

    func clearUsage() {
        usageEvents.removeAll()
        try? persistence.save(usageEvents, to: usageFile)
    }

    // MARK: - Cost summaries

    func costSummary(now: Date = Date(), calendar: Calendar = .current) -> CostSummary {
        let costed = usageEvents.filter { $0.estimatedCostUSD != nil }
        let total = costed.reduce(0) { $0 + ($1.estimatedCostUSD ?? 0) }

        let startOfToday = calendar.startOfDay(for: now)
        let today = costed
            .filter { $0.timestamp >= startOfToday }
            .reduce(0) { $0 + ($1.estimatedCostUSD ?? 0) }

        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let last7 = costed
            .filter { $0.timestamp >= sevenDaysAgo }
            .reduce(0) { $0 + ($1.estimatedCostUSD ?? 0) }

        let activeDays = Set(costed.map { calendar.startOfDay(for: $0.timestamp) }).count
        let average = activeDays > 0 ? total / Double(activeDays) : 0

        return CostSummary(
            today: today,
            last7Days: last7,
            averagePerActiveDay: average,
            total: total,
            eventCount: usageEvents.count
        )
    }

    // MARK: - Helpers

    private func persistSettings() {
        // hasAPIKey is derived but harmless to persist; the secret is NOT here.
        try? persistence.save(settings, to: settingsFile)
    }

    /// Estimates cost for token counts using a model's pricing metadata.
    static func estimateCost(model: GeminiModel, promptTokens: Int?, completionTokens: Int?) -> Double? {
        guard promptTokens != nil || completionTokens != nil else { return nil }
        let p = Double(promptTokens ?? 0) / 1_000_000 * model.pricing.inputPerMillion
        let c = Double(completionTokens ?? 0) / 1_000_000 * model.pricing.outputPerMillion
        return p + c
    }
}
