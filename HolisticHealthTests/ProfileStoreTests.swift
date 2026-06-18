import XCTest
@testable import HolisticHealth

@MainActor
final class ProfileStoreTests: XCTestCase {

    private func tempStore() -> (ProfileStore, FileDataStore) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fs = FileDataStore(baseDirectory: dir)
        return (ProfileStore(persistence: fs), fs)
    }

    func testOnboardingPersistsAcrossRelaunch() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store1 = ProfileStore(persistence: FileDataStore(baseDirectory: dir))
        XCTAssertFalse(store1.hasCompletedOnboarding)

        var p = store1.profile
        p.goals = [.insideOutAcne, .sleep]
        p.cyclePhase = .luteal
        p.onboardingCompleted = true
        store1.update(p)

        let store2 = ProfileStore(persistence: FileDataStore(baseDirectory: dir))
        XCTAssertTrue(store2.hasCompletedOnboarding)
        XCTAssertEqual(store2.profile.goals, [.insideOutAcne, .sleep])
        XCTAssertEqual(store2.profile.cyclePhase, .luteal)
    }

    func testConsentToggles() {
        let (store, _) = tempStore()
        XCTAssertFalse(store.isGranted(.acnePhotoReview))
        store.setConsent(.acnePhotoReview, granted: true)
        XCTAssertTrue(store.isGranted(.acnePhotoReview))
        store.setConsent(.acnePhotoReview, granted: false)
        XCTAssertFalse(store.isGranted(.acnePhotoReview))
    }

    func testResetClearsProfileAndConsents() {
        let (store, _) = tempStore()
        store.setConsent(.iCloudSync, granted: true)
        store.completeOnboarding()
        store.resetProfile()
        XCTAssertFalse(store.hasCompletedOnboarding)
        XCTAssertTrue(store.consents.isEmpty)
    }
}
