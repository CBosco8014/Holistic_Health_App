import XCTest
@testable import HolisticHealth

@MainActor
final class AddFoodViewModelTests: XCTestCase {

    private func setup() -> (AddFoodViewModel, MacroLibraryStore, MealLogStore, MacroLibraryRecord) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fs = FileDataStore(baseDirectory: dir)
        let lib = MacroLibraryStore(persistence: fs, fileName: "lib.json")
        let log = MealLogStore(persistence: fs, fileName: "log.json")
        let record = MacroLibraryRecord(
            canonicalName: "Chicken breast", servingDescription: "100 g",
            macros: MacroNutrients(proteinGrams: 30, carbGrams: 0, fatGrams: 4, calories: 165)
        )
        lib.upsert(record)
        return (AddFoodViewModel(library: lib, mealLog: log), lib, log, record)
    }

    func testSearchFindsSavedFood() {
        let (vm, _, _, _) = setup()
        vm.query = "chicken"
        vm.refresh()
        XCTAssertEqual(vm.matches.first?.canonicalName, "Chicken breast")
    }

    func testPresetRecalculatesMacros() {
        let (vm, _, _, record) = setup()
        vm.select(record)
        vm.choosePreset(.half)
        XCTAssertEqual(vm.scaledMacros.proteinGrams, 15, accuracy: 0.001)
        XCTAssertEqual(vm.scaledMacros.calories, 82.5, accuracy: 0.001)
        XCTAssertTrue(vm.isPresetSelected(.half))
    }

    func testCustomPercentOverridesPreset() {
        let (vm, _, _, record) = setup()
        vm.select(record)
        vm.choosePreset(.double)
        vm.customPercent = "150"
        XCTAssertEqual(vm.effectiveFactor, 1.5, accuracy: 0.001)
        XCTAssertEqual(vm.scaledMacros.proteinGrams, 45, accuracy: 0.001)
        XCTAssertFalse(vm.isPresetSelected(.double), "Custom percent overrides the chip selection")
    }

    func testLogUsesScaledMacrosAndAmount() {
        let (vm, _, log, record) = setup()
        vm.select(record)
        vm.choosePreset(.threeQuarter)
        vm.category = .lunch
        XCTAssertTrue(vm.log())

        XCTAssertEqual(log.entries.count, 1)
        let entry = log.entries[0]
        XCTAssertEqual(entry.servingAmount, 0.75, accuracy: 0.001)
        XCTAssertEqual(entry.macros.proteinGrams, 22.5, accuracy: 0.001)
        XCTAssertEqual(entry.category, .lunch)
        XCTAssertEqual(entry.libraryRecordID, record.id)
        XCTAssertNil(vm.selected, "Selection clears after logging")
    }
}
