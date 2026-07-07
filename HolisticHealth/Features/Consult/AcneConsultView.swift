import SwiftUI
import PhotosUI

/// Acne flare photo consult (US-017). Consent-gated; the image is never stored;
/// output is wellness education only.
struct AcneConsultView: View {
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var assessments: AssessmentStore
    @StateObject private var vm: AcneConsultViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraDenied = false

    init(aiConfig: AIConfigStore) {
        _vm = StateObject(wrappedValue: AcneConsultViewModel(aiConfig: aiConfig))
    }

    init(viewModel: AcneConsultViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                switch vm.step {
                case .consent: consentStep
                case .capture: captureStep
                case .questions: questionsStep
                case .result: resultStep
                }
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Acne Flare Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in vm.setImage(data) }.ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { if let data = try? await item.loadTransferable(type: Data.self) { vm.setImage(data) } }
        }
    }

    private var consentStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Skin", title: "Before we begin")
            SafetyNote(text: SafetyText.acne)
            FramedCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Label("Your photo is sent to Gemini for visual review only.", systemImage: "eye")
                    Label(SafetyText.photoNotStored, systemImage: "lock")
                    Label("You can stop and continue manually at any time.", systemImage: "hand.raised")
                }
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)
            }
            Button("I understand — continue") {
                profile.setConsent(.acnePhotoReview, granted: true)
                vm.grantConsentAndContinue()
            }
            .buttonStyle(.decoPrimary)
        }
    }

    private var captureStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Skin", title: "Add a flare photo")

            if let data = vm.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            } else {
                PhotoPlaceholder(systemImage: "face.smiling",
                                 title: "Add a photo (optional)",
                                 subtitle: SafetyText.photoNotStored)
            }

            HStack(spacing: Theme.Spacing.m) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text("Upload").frame(maxWidth: .infinity)
                }
                .buttonStyle(.decoSecondary)
                Button("Take photo") { handleCameraTap() }
                    .buttonStyle(.decoSecondary)
            }
            if cameraDenied {
                SafetyNote(text: "Camera unavailable or off. Upload a photo or continue with notes only.",
                           systemImage: "camera")
            }

            DecoTextField(label: "Notes (optional)", placeholder: "e.g. flared along jaw this week",
                          text: $vm.contextNote)

            Button {
                Task { await vm.review() }
            } label: {
                HStack {
                    if vm.isWorking { ProgressView().tint(Theme.Colors.textOnInk) }
                    Text(vm.isWorking ? "Reviewing…" : "Get a wellness reflection")
                }
            }
            .buttonStyle(.decoPrimary)
            .disabled(vm.isWorking)

            if let error = vm.errorMessage {
                SafetyNote(text: error, systemImage: "exclamationmark.triangle")
            }
        }
    }

    private var questionsStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "A few questions", title: "Help us reflect")
            Text("A little more context helps tailor the reflection.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            ForEach($vm.answers, id: \.question) { $qa in
                DecoTextField(label: qa.question, placeholder: "Your answer", text: $qa.answer)
            }

            Button {
                Task { await vm.submitAnswers() }
            } label: {
                HStack {
                    if vm.isWorking { ProgressView().tint(Theme.Colors.textOnInk) }
                    Text(vm.isWorking ? "Thinking…" : "Get suggestions")
                }
            }
            .buttonStyle(.decoPrimary)
            .disabled(vm.isWorking)

            if let error = vm.errorMessage {
                SafetyNote(text: error, systemImage: "exclamationmark.triangle")
            }
        }
    }

    private var resultStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Reflection", title: "Wellness notes")

            if let result = vm.result {
                FramedCard {
                    Text(result.summary)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let findings = result.contextualFindings, !findings.isEmpty {
                    listCard("Patterns noticed", findings)
                }
                if let suggestions = result.wellnessSuggestions, !suggestions.isEmpty {
                    listCard("Gentle ideas to explore", suggestions)
                }
                if let refs = result.references, !refs.isEmpty {
                    listCard("References", refs.map { $0.title })
                }
            }

            SafetyNote(text: SafetyText.acne)

            HStack(spacing: Theme.Spacing.m) {
                Button("Done") { dismiss() }
                    .buttonStyle(.decoSecondary)
                Button("Save reflection") {
                    if let assessment = vm.buildAssessment() { assessments.saveAcne(assessment) }
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
            }
        }
    }

    private func listCard(_ title: String, _ items: [String]) -> some View {
        FramedCard {
            VStack(alignment: .leading, spacing: 6) {
                EyebrowText(text: title)
                ForEach(items, id: \.self) { item in
                    Text("• \(item)")
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func handleCameraTap() {
        guard CameraPermission.isAvailable else { cameraDenied = true; return }
        switch CameraPermission.status {
        case .authorized: showCamera = true
        case .notDetermined:
            Task { let ok = await CameraPermission.request(); if ok { showCamera = true } else { cameraDenied = true } }
        default: cameraDenied = true
        }
    }
}
