import XCTest
@testable import HolisticHealth

final class ModelsTests: XCTestCase {

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func testMacroScalingAndAddition() {
        let base = MacroNutrients(proteinGrams: 10, carbGrams: 20, fatGrams: 5, calories: 165)
        let half = base.scaled(by: 0.5)
        XCTAssertEqual(half.proteinGrams, 5, accuracy: 0.0001)
        XCTAssertEqual(half.calories, 82.5, accuracy: 0.0001)
        let sum = base + half
        XCTAssertEqual(sum.proteinGrams, 15, accuracy: 0.0001)
    }

    func testMacroLibraryRecordRoundTrips() throws {
        let record = MacroLibraryRecord(
            canonicalName: "Greek yogurt",
            aliases: ["plain greek yogurt", "fage"],
            servingDescription: "1 cup (245 g)",
            macros: MacroNutrients(proteinGrams: 20, carbGrams: 9, fatGrams: 0.7, calories: 130),
            source: .geminiText,
            confidence: 0.8,
            confirmation: .confirmed
        )
        let decoded = try roundTrip(record)
        XCTAssertEqual(decoded, record)
    }

    func testUserProfileRoundTrips() throws {
        let profile = UserProfile(
            displayName: "Test",
            goals: [.insideOutAcne, .hormoneHealth],
            cyclePhase: .luteal,
            onboardingCompleted: true
        )
        XCTAssertEqual(try roundTrip(profile), profile)
    }

    func testExerciseAndAssessmentsRoundTrip() throws {
        let session = ExerciseSession(category: .sprintBurst, activity: .rowing, durationMinutes: 20)
        XCTAssertEqual(try roundTrip(session), session)

        let acne = AcneAssessment(summary: "s", wellnessSuggestions: ["sleep"])
        XCTAssertEqual(try roundTrip(acne), acne)
    }

    func testUsageEventRoundTrips() throws {
        let event = APIUsageEvent(feature: .foodParsing, model: GeminiModel.flash.rawValue, success: true,
                                  totalTokens: 1200, estimatedCostUSD: 0.0012)
        XCTAssertEqual(try roundTrip(event), event)
    }
}
