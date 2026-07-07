import XCTest
import SwiftUI
@testable import HolisticHealth

final class DesignSystemTests: XCTestCase {

    func testHexParsingProducesExpectedComponents() throws {
        let color = Color(hex: "#18213a")
        let resolved = color.resolve(in: EnvironmentValues())
        XCTAssertEqual(Double(resolved.red), 0x18 / 255, accuracy: 0.01)
        XCTAssertEqual(Double(resolved.green), 0x21 / 255, accuracy: 0.01)
        XCTAssertEqual(Double(resolved.blue), 0x3a / 255, accuracy: 0.01)
    }

    func testHexParsingToleratesMissingHash() throws {
        let withHash = Color(hex: "#b58f33").resolve(in: EnvironmentValues())
        let without = Color(hex: "b58f33").resolve(in: EnvironmentValues())
        XCTAssertEqual(withHash.red, without.red, accuracy: 0.001)
        XCTAssertEqual(withHash.blue, without.blue, accuracy: 0.001)
    }
}
