import XCTest
@testable import HolisticHealth

@MainActor
final class LifestyleTests: XCTestCase {

    // MARK: - Recommender

    func testHighStressPrioritizesCalmingPractices() {
        let profile = UserProfile(goals: [.stress])
        let checkIn = HormoneSkinCheckIn(stress: 5)
        let recommended = PracticeCatalog.recommended(profile: profile, latest: checkIn, limit: 3)
        let types = recommended.map(\.type)
        XCTAssertTrue(types.contains(.breathwork) || types.contains(.grounding),
                      "High stress should surface breathwork/grounding")
    }

    func testLowSleepPrioritizesSleepPractices() {
        let profile = UserProfile(goals: [.sleep])
        let checkIn = HormoneSkinCheckIn(sleepQuality: 1)
        let recommended = PracticeCatalog.recommended(profile: profile, latest: checkIn, limit: 2)
        let types = recommended.map(\.type)
        XCTAssertTrue(types.contains(.sleepWindDown) || types.contains(.screenBoundary))
    }

    func testRecommenderAlwaysReturnsSomethingWithNoData() {
        let recommended = PracticeCatalog.recommended(profile: UserProfile(), latest: nil, limit: 4)
        XCTAssertEqual(recommended.count, 4)
    }

    // MARK: - Store

    func testRecordAndCompletedCount() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = LifestyleStore(persistence: FileDataStore(baseDirectory: dir), fileName: "p.json")
        let practice = PracticeCatalog.all[0]
        store.record(practice, status: .completed, rating: 4)
        store.record(practice, status: .skipped)
        XCTAssertEqual(store.completedCount, 1)
        XCTAssertEqual(store.todaysStatus(for: practice.type), .skipped, "Latest status today")
    }

    func testLifestylePersistsAcrossReload() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store1 = LifestyleStore(persistence: FileDataStore(baseDirectory: dir), fileName: "p.json")
        store1.record(PracticeCatalog.all[1], status: .completed, rating: 5)
        let store2 = LifestyleStore(persistence: FileDataStore(baseDirectory: dir), fileName: "p.json")
        XCTAssertEqual(store2.completedCount, 1)
        XCTAssertEqual(store2.logs.first?.rating, 5)
    }
}
