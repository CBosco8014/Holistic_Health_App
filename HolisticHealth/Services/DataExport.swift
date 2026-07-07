import Foundation

/// A portable export of the user's personal data. The Gemini API key is NEVER
/// included — it lives only in the Keychain and is intentionally absent here.
struct ExportBundle: Codable, Equatable {
    var exportedAt: Date
    var profile: UserProfile
    var consents: [ConsentRecord]
    var macroLibrary: [MacroLibraryRecord]
    var mealLog: [MealLogEntry]
    var checkIns: [HormoneSkinCheckIn]
    var supplements: [Supplement]
    var supplementLogs: [SupplementLogEntry]
    var practiceLogs: [LifestylePracticeLog]
    var exerciseSessions: [ExerciseSession]
    var acneAssessments: [AcneAssessment]
    var healthAssessments: [HealthAssessment]
    var consultSessions: [ConsultSession]
    var usageEvents: [APIUsageEvent]
}

@MainActor
enum DataExport {
    static func buildBundle(
        profile: ProfileStore,
        library: MacroLibraryStore,
        mealLog: MealLogStore,
        checkIns: CheckInStore,
        supplements: SupplementStore,
        lifestyle: LifestyleStore,
        exercise: ExerciseStore,
        assessments: AssessmentStore,
        aiConfig: AIConfigStore,
        now: Date = Date()
    ) -> ExportBundle {
        ExportBundle(
            exportedAt: now,
            profile: profile.profile,
            consents: profile.consents,
            macroLibrary: library.records,
            mealLog: mealLog.entries,
            checkIns: checkIns.checkIns,
            supplements: supplements.supplements,
            supplementLogs: supplements.logs,
            practiceLogs: lifestyle.logs,
            exerciseSessions: exercise.sessions,
            acneAssessments: assessments.acneAssessments,
            healthAssessments: assessments.healthAssessments,
            consultSessions: assessments.consultSessions,
            usageEvents: aiConfig.usageEvents
        )
    }

    /// Writes the bundle to a temporary file and returns its URL for sharing.
    static func writeFile(_ bundle: ExportBundle) throws -> URL {
        let data = try JSONCoding.encoder.encode(bundle)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("holistic_health_export.json")
        try data.write(to: url, options: [.atomic])
        return url
    }
}

@MainActor
enum DataReset {
    /// Deletes all personal health data and clears the macro library. The API
    /// key (a credential, not health data) is left intact unless `clearKey` is
    /// set.
    static func deleteAll(
        profile: ProfileStore,
        library: MacroLibraryStore,
        mealLog: MealLogStore,
        checkIns: CheckInStore,
        supplements: SupplementStore,
        lifestyle: LifestyleStore,
        exercise: ExerciseStore,
        assessments: AssessmentStore,
        aiConfig: AIConfigStore,
        clearKey: Bool = false
    ) {
        library.clear()
        mealLog.clear()
        checkIns.clear()
        supplements.clear()
        lifestyle.clear()
        exercise.clear()
        assessments.clear()
        aiConfig.clearUsage()
        profile.resetProfile()
        if clearKey { aiConfig.clearAPIKey() }
    }
}
