import XCTest
@testable import HolisticHealth

@MainActor
final class ConsultViewModelTests: XCTestCase {

    func testAsksOneQuestionAtATime() async {
        let vm = ConsultViewModel(nextStep: { history, _ in
            ConsultStepResult(question: "Question \(history.count + 1)?", isComplete: false, summary: nil)
        }, contextProvider: { "ctx" })
        await vm.start()
        XCTAssertEqual(vm.phase, .asking)
        XCTAssertEqual(vm.currentQuestion, "Question 1?")
        vm.currentAnswer = "yes"
        await vm.submitAnswer()
        XCTAssertEqual(vm.history.count, 1)
        XCTAssertEqual(vm.currentQuestion, "Question 2?")
    }

    func testCompletesWhenModelSignalsDone() async {
        var count = 0
        let vm = ConsultViewModel(nextStep: { _, _ in
            count += 1
            if count >= 2 { return ConsultStepResult(question: nil, isComplete: true, summary: "All done") }
            return ConsultStepResult(question: "Q?", isComplete: false, summary: nil)
        }, contextProvider: { "ctx" })
        await vm.start()
        vm.currentAnswer = "a"
        await vm.submitAnswer()
        XCTAssertEqual(vm.phase, .complete)
        XCTAssertEqual(vm.summary, "All done")
    }

    func testStopsAtTenQuestions() async {
        let vm = ConsultViewModel(nextStep: { history, _ in
            ConsultStepResult(question: "Q\(history.count)?", isComplete: false, summary: nil)
        }, contextProvider: { "ctx" })
        await vm.start()
        for _ in 0..<vm.maxQuestions {
            vm.currentAnswer = "a"
            await vm.submitAnswer()
        }
        XCTAssertEqual(vm.phase, .complete)
        XCTAssertEqual(vm.history.count, vm.maxQuestions)
    }

    func testContextOnlyUsedWhenConsented() async {
        var seenContext = ""
        let vm = ConsultViewModel(nextStep: { _, context in
            seenContext = context
            return ConsultStepResult(question: "Q?", isComplete: false, summary: nil)
        }, contextProvider: { "SECRET PATTERNS" })
        vm.usePatterns = false
        await vm.start()
        XCTAssertFalse(seenContext.contains("SECRET PATTERNS"))
        vm.usePatterns = true
        vm.currentAnswer = "a"
        await vm.submitAnswer()
        XCTAssertTrue(seenContext.contains("SECRET PATTERNS"))
    }

    func testBuildSessionCapturesHistory() async {
        let vm = ConsultViewModel(nextStep: { _, _ in
            ConsultStepResult(question: nil, isComplete: true, summary: "done")
        }, contextProvider: { "ctx" })
        vm.usePatterns = true
        await vm.start()
        let session = vm.buildSession()
        XCTAssertTrue(session.usesLoggedPatterns)
        XCTAssertEqual(session.summary, "done")
    }
}
