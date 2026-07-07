import XCTest
@testable import HolisticHealth

@MainActor
final class DataExportTests: XCTestCase {

    private func makeStores() -> (ProfileStore, MacroLibraryStore, MealLogStore, CheckInStore,
                                  SupplementStore, LifestyleStore, ExerciseStore, AssessmentStore, AIConfigStore) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fs = FileDataStore(baseDirectory: dir)
        return (
            ProfileStore(persistence: fs),
            MacroLibraryStore(persistence: fs, fileName: "lib.json"),
            MealLogStore(persistence: fs, fileName: "log.json"),
            CheckInStore(persistence: fs, fileName: "ci.json"),
            SupplementStore(persistence: fs, supplementsFile: "s.json", logsFile: "sl.json"),
            LifestyleStore(persistence: fs, fileName: "pl.json"),
            ExerciseStore(persistence: fs, fileName: "ex.json"),
            AssessmentStore(persistence: fs, acneFile: "a.json", healthFile: "h.json", consultFile: "c.json"),
            AIConfigStore(persistence: fs, keychainAccount: "test_export_\(UUID().uuidString)")
        )
    }

    func testExportBundleRoundTripsAndExcludesAPIKey() throws {
        let (profile, library, mealLog, checkIns, supplements, lifestyle, exercise, assessments, aiConfig) = makeStores()
        aiConfig.saveAPIKey("super-secret-key")
        library.upsert(MacroLibraryRecord(canonicalName: "Eggs", servingDescription: "2",
                                          macros: MacroNutrients(proteinGrams: 12)))
        checkIns.save(HormoneSkinCheckIn(stress: 3))

        let bundle = DataExport.buildBundle(profile: profile, library: library, mealLog: mealLog,
                                            checkIns: checkIns, supplements: supplements, lifestyle: lifestyle,
                                            exercise: exercise, assessments: assessments, aiConfig: aiConfig)
        let data = try JSONCoding.encoder.encode(bundle)
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(json.contains("super-secret-key"), "Export must never contain the API key")

        let decoded = try JSONCoding.decoder.decode(ExportBundle.self, from: data)
        XCTAssertEqual(decoded.macroLibrary.count, 1)
        XCTAssertEqual(decoded.checkIns.count, 1)
    }

    func testDeleteAllClearsHealthDataButKeepsKey() {
        let (profile, library, mealLog, checkIns, supplements, lifestyle, exercise, assessments, aiConfig) = makeStores()
        aiConfig.saveAPIKey("keep-me")
        library.upsert(MacroLibraryRecord(canonicalName: "Eggs", servingDescription: "2", macros: .zero))
        mealLog.add(MealLogEntry(foodName: "Eggs", servingDescription: "2", macros: .zero))
        checkIns.save(HormoneSkinCheckIn(stress: 2))
        supplements.save(Supplement(name: "Zinc"))
        profile.completeOnboarding()

        DataReset.deleteAll(profile: profile, library: library, mealLog: mealLog, checkIns: checkIns,
                            supplements: supplements, lifestyle: lifestyle, exercise: exercise,
                            assessments: assessments, aiConfig: aiConfig)

        XCTAssertTrue(library.records.isEmpty)
        XCTAssertTrue(mealLog.entries.isEmpty)
        XCTAssertTrue(checkIns.checkIns.isEmpty)
        XCTAssertTrue(supplements.supplements.isEmpty)
        XCTAssertFalse(profile.hasCompletedOnboarding, "Profile reset")
        XCTAssertTrue(aiConfig.hasAPIKey, "API key kept unless explicitly cleared")
    }

    func testDeleteAllWithClearKey() {
        let (profile, library, mealLog, checkIns, supplements, lifestyle, exercise, assessments, aiConfig) = makeStores()
        aiConfig.saveAPIKey("remove-me")
        DataReset.deleteAll(profile: profile, library: library, mealLog: mealLog, checkIns: checkIns,
                            supplements: supplements, lifestyle: lifestyle, exercise: exercise,
                            assessments: assessments, aiConfig: aiConfig, clearKey: true)
        XCTAssertFalse(aiConfig.hasAPIKey)
    }
}
