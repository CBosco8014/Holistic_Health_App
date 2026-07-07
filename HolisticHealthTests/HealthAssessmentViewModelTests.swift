import XCTest
@testable import HolisticHealth

@MainActor
final class HealthAssessmentViewModelTests: XCTestCase {

    private let result = HealthAssessmentResult(
        patternSummary: "Stress and sleep appear linked to skin this week.",
        possibleContributors: ["Late screens"],
        currentFocusAreas: ["Wind-down"],
        activeTreatments: [],
        holisticTreatments: ["Breathwork"],
        acnePhotoFindings: [],
        caveats: "Wellness only.",
        references: [.init(title: "Sleep & skin", url: nil)]
    )

    func testGenerateBuildsAssessmentFromSelectedCategories() async {
        var seenCategories: [AssessmentCategory] = []
        let vm = HealthAssessmentViewModel(generator: { categories, _ in
            seenCategories = categories
            return self.result
        }, contextProvider: { _ in "ctx" })
        vm.selectedCategories = [.macros, .hormoneSkin]
        await vm.generate()
        XCTAssertEqual(vm.phase, .report)
        XCTAssertEqual(Set(seenCategories), [.macros, .hormoneSkin])
        XCTAssertEqual(vm.assessment?.patternSummary, result.patternSummary)
        XCTAssertEqual(vm.editedText, result.patternSummary)
    }

    func testEditsAppliedToFinalizedAssessment() async {
        let vm = HealthAssessmentViewModel(generator: { _, _ in self.result }, contextProvider: { _ in "c" })
        await vm.generate()
        vm.editedText = "My own edited summary."
        let final = vm.finalizedAssessment()
        XCTAssertEqual(final?.editedReport, "My own edited summary.")
    }

    func testCannotGenerateWithNoCategories() async {
        let vm = HealthAssessmentViewModel(generator: { _, _ in self.result }, contextProvider: { _ in "c" })
        vm.selectedCategories = []
        XCTAssertFalse(vm.canGenerate)
    }

    func testErrorSurfaces() async {
        let vm = HealthAssessmentViewModel(generator: { _, _ in throw AIError.rateLimited }, contextProvider: { _ in "c" })
        await vm.generate()
        XCTAssertEqual(vm.phase, .setup)
        XCTAssertNotNil(vm.errorMessage)
    }
}
