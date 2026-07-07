import XCTest
@testable import HolisticHealth

/// Baseline tests covering the US-001 app shell information architecture.
final class AppShellTests: XCTestCase {

    func testFourPrimaryTabsInOrder() {
        XCTAssertEqual(
            AppTab.allCases,
            [.lifestyle, .supplements, .macro, .exercise],
            "The app must expose exactly four primary tabs in the approved order."
        )
    }

    func testEveryTabHasTitleAndSymbol() {
        for tab in AppTab.allCases {
            XCTAssertFalse(tab.title.isEmpty, "\(tab) is missing a title")
            XCTAssertFalse(tab.systemImage.isEmpty, "\(tab) is missing an SF Symbol")
        }
    }
}
