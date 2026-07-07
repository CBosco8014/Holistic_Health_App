import XCTest
@testable import HolisticHealth

@MainActor
final class AcneConsultViewModelTests: XCTestCase {

    func testClarifyingQuestionsRouteToQuestionsStep() async {
        let vm = AcneConsultViewModel(reviewer: { _, _ in
            AcneReviewResult(clarifyingQuestions: ["How long has it lasted?"], summary: "Preliminary",
                             contextualFindings: nil, wellnessSuggestions: nil, references: nil)
        })
        vm.grantConsentAndContinue()
        await vm.review()
        XCTAssertEqual(vm.step, .questions)
        XCTAssertEqual(vm.answers.count, 1)
    }

    func testNoQuestionsRoutesToResult() async {
        let vm = AcneConsultViewModel(reviewer: { _, _ in
            AcneReviewResult(clarifyingQuestions: [], summary: "Reflection",
                             contextualFindings: ["Possible dairy link"],
                             wellnessSuggestions: ["Hydrate", "Sleep"], references: nil)
        })
        vm.grantConsentAndContinue()
        await vm.review()
        XCTAssertEqual(vm.step, .result)
    }

    func testAnswersSecondPassReachesResult() async {
        var callCount = 0
        let vm = AcneConsultViewModel(reviewer: { _, _ in
            callCount += 1
            if callCount == 1 {
                return AcneReviewResult(clarifyingQuestions: ["Q?"], summary: "p", contextualFindings: nil,
                                        wellnessSuggestions: nil, references: nil)
            }
            return AcneReviewResult(clarifyingQuestions: [], summary: "final", contextualFindings: nil,
                                    wellnessSuggestions: ["rest"], references: nil)
        })
        vm.grantConsentAndContinue()
        await vm.review()
        vm.answers[0].answer = "two weeks"
        await vm.submitAnswers()
        XCTAssertEqual(vm.step, .result)
        XCTAssertEqual(vm.result?.summary, "final")
    }

    func testBuildAssessmentExcludesImage() async {
        let vm = AcneConsultViewModel(reviewer: { _, _ in
            AcneReviewResult(clarifyingQuestions: [], summary: "Reflection",
                             contextualFindings: ["pattern"], wellnessSuggestions: ["hydrate"],
                             references: [.init(title: "Ref", url: "https://x")])
        })
        vm.grantConsentAndContinue()
        vm.setImage(Data([0x01]))
        await vm.review()
        let assessment = vm.buildAssessment()
        XCTAssertNotNil(assessment)
        XCTAssertEqual(assessment?.summary, "Reflection")
        XCTAssertEqual(assessment?.wellnessSuggestions, ["hydrate"])
        // AcneAssessment has no image property by design — nothing to assert
        // beyond it building from derived data only.
    }

    func testErrorSurfaces() async {
        let vm = AcneConsultViewModel(reviewer: { _, _ in throw AIError.policyBlocked })
        vm.grantConsentAndContinue()
        await vm.review()
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.step, .capture)
    }
}
