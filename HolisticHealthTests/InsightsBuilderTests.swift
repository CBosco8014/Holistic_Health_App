import XCTest
@testable import HolisticHealth

final class InsightsBuilderTests: XCTestCase {

    private let cal = Calendar(identifier: .gregorian)

    func testRecentDaysReturnsCountOldestFirst() {
        let now = Date()
        let days = InsightsBuilder.recentDays(count: 7, now: now, calendar: cal)
        XCTAssertEqual(days.count, 7)
        XCTAssertTrue(days[0] < days[6], "Oldest first")
    }

    func testWeeklyMacrosSumsPerDay() throws {
        let now = Date()
        let days = InsightsBuilder.recentDays(count: 3, now: now, calendar: cal)
        let today = days.last!
        let entries = [
            MealLogEntry(foodName: "A", servingDescription: "s",
                         macros: MacroNutrients(proteinGrams: 10, carbGrams: 5, fatGrams: 2, calories: 90),
                         loggedAt: today),
            MealLogEntry(foodName: "B", servingDescription: "s",
                         macros: MacroNutrients(proteinGrams: 15, carbGrams: 10, fatGrams: 3, calories: 150),
                         loggedAt: today)
        ]
        let macros = InsightsBuilder.weeklyMacros(entries: entries, days: days, calendar: cal)
        XCTAssertEqual(try XCTUnwrap(macros.last).protein, 25, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(macros.first).protein, 0, accuracy: 0.001)
        XCTAssertTrue(InsightsBuilder.hasMacroData(macros))
    }

    func testSignalSeriesReadsCheckInValue() {
        let now = Date()
        let days = InsightsBuilder.recentDays(count: 2, now: now, calendar: cal)
        let today = days.last!
        let checkIns = [HormoneSkinCheckIn(date: today, stress: 4)]
        let series = InsightsBuilder.signalSeries(kind: .stress, days: days, checkIns: checkIns,
                                                  sessions: [], supplementLogs: [], calendar: cal)
        XCTAssertEqual(series.last?.value, 4)
        XCTAssertNil(series.first?.value)
        XCTAssertTrue(InsightsBuilder.hasSignalData(series))
    }

    func testSignalSeriesSumsExerciseMinutes() {
        let now = Date()
        let days = InsightsBuilder.recentDays(count: 1, now: now, calendar: cal)
        let today = days.last!
        let sessions = [
            ExerciseSession(category: .weightlifting, intensity: .high, durationMinutes: 30, timestamp: today),
            ExerciseSession(category: .sprintBurst, activity: .rowing, durationMinutes: 15, timestamp: today)
        ]
        let series = InsightsBuilder.signalSeries(kind: .exerciseMinutes, days: days, checkIns: [],
                                                  sessions: sessions, supplementLogs: [], calendar: cal)
        XCTAssertEqual(series.last?.value, 45)
    }

    func testEmptyDataReportsNoData() {
        let days = InsightsBuilder.recentDays(count: 3, now: Date(), calendar: cal)
        let macros = InsightsBuilder.weeklyMacros(entries: [], days: days, calendar: cal)
        XCTAssertFalse(InsightsBuilder.hasMacroData(macros))
        let signals = InsightsBuilder.signalSeries(kind: .mood, days: days, checkIns: [], sessions: [],
                                                   supplementLogs: [], calendar: cal)
        XCTAssertFalse(InsightsBuilder.hasSignalData(signals))
    }
}
