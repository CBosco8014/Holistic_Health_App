import SwiftUI
import PhotosUI

/// Meal photo / upload macro capture (US-011). Take or upload a meal photo,
/// analyze with Gemini, edit the itemized results, and confirm to log + save.
struct MealPhotoView: View {
    @StateObject private var vm: MealPhotoViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraDenied = false

    init(library: MacroLibraryStore, mealLog: MealLogStore, aiConfig: AIConfigStore) {
        _vm = StateObject(wrappedValue: MealPhotoViewModel(library: library, mealLog: mealLog, aiConfig: aiConfig))
    }

    init(viewModel: MealPhotoViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                switch vm.phase {
                case .capture: captureStep
                case .review: reviewStep
                }
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Meal Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in vm.setImage(data) }
                .ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    vm.setImage(data)
                }
            }
        }
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.environment["HH_PHOTO_DEMO"] == "review" {
                vm.debugSeedReview()
            }
        }
        #endif
    }

    // MARK: - Capture

    private var captureStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Macro", title: "Capture a meal")

            if let data = vm.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .strokeBorder(Theme.Colors.goldLine, lineWidth: 1)
                    )
            } else {
                PhotoPlaceholder(systemImage: "fork.knife",
                                 title: "Add a meal photo",
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
                SafetyNote(text: CameraPermission.isAvailable
                    ? "Camera access is off. Enable it in Settings → Holistic Health to take photos. You can still upload from your library."
                    : "No camera is available on this device. You can upload a photo from your library instead.",
                    systemImage: "camera")
            }

            if vm.hasImage {
                Button {
                    Task { await vm.analyze() }
                } label: {
                    HStack {
                        if vm.isAnalyzing { ProgressView().tint(Theme.Colors.textOnInk) }
                        Text(vm.isAnalyzing ? "Analyzing…" : "Analyze meal")
                    }
                }
                .buttonStyle(.decoPrimary)
                .disabled(vm.isAnalyzing)
            }

            if let error = vm.errorMessage {
                SafetyNote(text: error, systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func handleCameraTap() {
        guard CameraPermission.isAvailable else { cameraDenied = true; return }
        switch CameraPermission.status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            Task {
                let granted = await CameraPermission.request()
                if granted { showCamera = true } else { cameraDenied = true }
            }
        default:
            cameraDenied = true
        }
    }

    // MARK: - Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            HStack {
                SectionHeader(eyebrow: "Review", title: "Confirm items")
                Spacer()
                StatusTag(text: "Needs review", role: .warning)
            }

            Text("Edit anything before saving. Untick items you don't want to log.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            ForEach($vm.items) { $item in
                itemCard($item)
            }

            FramedCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    EyebrowText(text: "Included total")
                    HStack(spacing: Theme.Spacing.s) {
                        MacroStat(value: vm.includedTotals.proteinGrams, label: "Protein",
                                  emphasized: true, tint: Theme.Colors.accentText)
                        MacroStat(value: vm.includedTotals.carbGrams, label: "Carbs")
                        MacroStat(value: vm.includedTotals.fatGrams, label: "Fat")
                    }
                    Text("Secondary: \(MacroFormat.calories(vm.includedTotals.calories))")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textFaint)
                }
            }

            SafetyNote(text: "Estimates are approximate. Confirmed foods are saved to your library for next time.")

            HStack(spacing: Theme.Spacing.m) {
                Button("Back") { vm.reset() }
                    .buttonStyle(.decoSecondary)
                Button("Confirm & Log") {
                    vm.confirm()
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
            }
        }
    }

    private func itemCard(_ item: Binding<EditableFoodItem>) -> some View {
        FramedCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack {
                    Toggle("", isOn: item.include)
                        .labelsHidden()
                        .tint(Theme.Colors.accent)
                    DecoTextField(label: "Food", text: item.name)
                }
                DecoTextField(label: "Serving", text: item.serving)
                HStack(spacing: Theme.Spacing.s) {
                    DecoTextField(label: "P (g)", text: item.protein, keyboard: .decimalPad)
                    DecoTextField(label: "C (g)", text: item.carbs, keyboard: .decimalPad)
                    DecoTextField(label: "F (g)", text: item.fat, keyboard: .decimalPad)
                }
                DecoTextField(label: "Calories", text: item.calories, keyboard: .decimalPad)
                FlowChips(items: MealCategory.allCases,
                          isSelected: { item.wrappedValue.category == $0 },
                          label: { $0.displayName },
                          toggle: { item.wrappedValue.category = $0 })
            }
            .opacity(item.wrappedValue.include ? 1 : 0.5)
        }
    }
}
