import XCTest
@testable import HolisticHealth

@MainActor
final class VisualizeFoodViewModelTests: XCTestCase {

    private func makeStores() -> (MacroLibraryStore, MealLogStore) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fs = FileDataStore(baseDirectory: dir)
        return (MacroLibraryStore(persistence: fs, fileName: "lib.json"),
                MealLogStore(persistence: fs, fileName: "log.json"))
    }

    private let estimate = VisualizedFoodEstimate(
        visualDescription: "A plate of pesto pasta with grilled chicken.",
        name: "Chicken pesto pasta", servingDescription: "1 plate",
        proteinGrams: 38, carbGrams: 60, fatGrams: 28, calories: 680,
        confidence: 0.6, assumptions: "Restaurant portion"
    )

    func testVisualizeFromTextReachesConfirm() async {
        let (lib, log) = makeStores()
        let vm = VisualizeFoodViewModel(library: lib, mealLog: log, visualizer: { text, image in
            XCTAssertEqual(text, "pesto pasta")
            XCTAssertNil(image)
            return self.estimate
        })
        vm.dishText = "pesto pasta"
        XCTAssertTrue(vm.canVisualize)
        await vm.visualize()
        XCTAssertEqual(vm.step, .confirm)
        XCTAssertEqual(vm.draftName, "Chicken pesto pasta")
        XCTAssertFalse(vm.visualDescription.isEmpty)
    }

    func testVisualizeFromImageReachesConfirm() async {
        let (lib, log) = makeStores()
        let vm = VisualizeFoodViewModel(library: lib, mealLog: log, visualizer: { _, image in
            XCTAssertNotNil(image)
            return self.estimate
        })
        vm.setImage(Data([0x02]))
        XCTAssertTrue(vm.canVisualize)
        await vm.visualize()
        XCTAssertEqual(vm.step, .confirm)
    }

    func testConfirmSavesAsMenuSourceAndLogs() async {
        let (lib, log) = makeStores()
        let vm = VisualizeFoodViewModel(library: lib, mealLog: log, visualizer: { _, _ in self.estimate })
        vm.dishText = "pasta"
        await vm.visualize()
        XCTAssertTrue(lib.records.isEmpty, "Confirmation required before saving")
        vm.draftCategory = .dinner
        vm.confirmAndLog()

        XCTAssertEqual(lib.records.first?.source, .geminiMenu)
        XCTAssertEqual(log.entries.count, 1)
        XCTAssertEqual(log.entries.first?.category, .dinner)
        XCTAssertEqual(vm.step, .input, "Resets after logging")
    }

    func testErrorSurfacesAndStaysOnInput() async {
        let (lib, log) = makeStores()
        let vm = VisualizeFoodViewModel(library: lib, mealLog: log, visualizer: { _, _ in throw AIError.policyBlocked })
        vm.dishText = "x"
        await vm.visualize()
        XCTAssertEqual(vm.step, .input)
        XCTAssertNotNil(vm.errorMessage)
    }

    func testCannotVisualizeWithoutInput() {
        let (lib, log) = makeStores()
        let vm = VisualizeFoodViewModel(library: lib, mealLog: log, visualizer: { _, _ in self.estimate })
        XCTAssertFalse(vm.canVisualize)
    }
}
