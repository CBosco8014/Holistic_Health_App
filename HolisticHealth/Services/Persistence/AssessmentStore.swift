import Foundation
import Combine

/// Stores saved acne assessments and manual health assessments. Acne assessments
/// never include the source image (only the derived summary/findings).
@MainActor
final class AssessmentStore: ObservableObject {
    @Published private(set) var acneAssessments: [AcneAssessment] = []
    @Published private(set) var healthAssessments: [HealthAssessment] = []
    @Published private(set) var consultSessions: [ConsultSession] = []

    private let persistence: DataPersisting
    private let acneFile: String
    private let healthFile: String
    private let consultFile: String

    init(
        persistence: DataPersisting = FileDataStore(),
        acneFile: String = "acne_assessments.json",
        healthFile: String = "health_assessments.json",
        consultFile: String = "consult_sessions.json"
    ) {
        self.persistence = persistence
        self.acneFile = acneFile
        self.healthFile = healthFile
        self.consultFile = consultFile
        acneAssessments = (try? persistence.load([AcneAssessment].self, from: acneFile)) ?? []
        healthAssessments = (try? persistence.load([HealthAssessment].self, from: healthFile)) ?? []
        consultSessions = (try? persistence.load([ConsultSession].self, from: consultFile)) ?? []
    }

    // MARK: - Acne

    func saveAcne(_ assessment: AcneAssessment) {
        upsert(assessment, into: &acneAssessments)
        try? persistence.save(acneAssessments, to: acneFile)
    }

    func deleteAcne(_ assessment: AcneAssessment) {
        acneAssessments.removeAll { $0.id == assessment.id }
        try? persistence.save(acneAssessments, to: acneFile)
    }

    // MARK: - Health assessments

    func saveHealth(_ assessment: HealthAssessment) {
        upsert(assessment, into: &healthAssessments)
        try? persistence.save(healthAssessments, to: healthFile)
    }

    func deleteHealth(_ assessment: HealthAssessment) {
        healthAssessments.removeAll { $0.id == assessment.id }
        try? persistence.save(healthAssessments, to: healthFile)
    }

    // MARK: - Consult sessions

    func saveConsult(_ session: ConsultSession) {
        upsert(session, into: &consultSessions)
        try? persistence.save(consultSessions, to: consultFile)
    }

    var acneSorted: [AcneAssessment] { acneAssessments.sorted { $0.createdAt > $1.createdAt } }
    var healthSorted: [HealthAssessment] { healthAssessments.sorted { $0.createdAt > $1.createdAt } }

    func clear() {
        acneAssessments.removeAll()
        healthAssessments.removeAll()
        consultSessions.removeAll()
        try? persistence.save(acneAssessments, to: acneFile)
        try? persistence.save(healthAssessments, to: healthFile)
        try? persistence.save(consultSessions, to: consultFile)
    }

    private func upsert<T: Identifiable>(_ value: T, into array: inout [T]) where T.ID == UUID {
        if let idx = array.firstIndex(where: { $0.id == value.id }) {
            array[idx] = value
        } else {
            array.append(value)
        }
    }
}
