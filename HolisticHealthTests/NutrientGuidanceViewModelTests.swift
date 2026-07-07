import XCTest
@testable import HolisticHealth

@MainActor
final class NutrientGuidanceViewModelTests: XCTestCase {

    func testGenerateMapsSuggestions() async {
        let result = NutrientSuggestionsResult(suggestions: [
            .init(area: "Magnesium", rationale: "Reported stress and poor sleep.",
                  relevantInputs: ["Stress 4/5"], safetyNotes: "Discuss with a clinician.",
                  clinicianQuestions: ["Any kidney concerns?"])
        ])
        let vm = NutrientGuidanceViewModel(suggester: { _ in result }, contextProvider: { "ctx" })
        await vm.generate()
        XCTAssertEqual(vm.suggestions.count, 1)
        XCTAssertEqual(vm.suggestions.first?.area, "Magnesium")
        XCTAssertEqual(vm.suggestions.first?.relevantInputs, ["Stress 4/5"])
        XCTAssertNil(vm.errorMessage)
    }

    func testErrorSurfaces() async {
        let vm = NutrientGuidanceViewModel(suggester: { _ in throw AIError.missingAPIKey }, contextProvider: { "ctx" })
        await vm.generate()
        XCTAssertTrue(vm.suggestions.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testEmptyResultSetsMessage() async {
        let vm = NutrientGuidanceViewModel(suggester: { _ in NutrientSuggestionsResult(suggestions: []) },
                                           contextProvider: { "ctx" })
        await vm.generate()
        XCTAssertNotNil(vm.errorMessage)
    }
}
