import SwiftUI
import PhotosUI

/// Visualize a dish from a menu photo, screenshot, or text, then estimate macros
/// (US-012). All three inputs reach the same confirmation flow.
struct VisualizeFoodView: View {
    @StateObject private var vm: VisualizeFoodViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraDenied = false

    init(library: MacroLibraryStore, mealLog: MealLogStore, aiConfig: AIConfigStore) {
        _vm = StateObject(wrappedValue: VisualizeFoodViewModel(library: library, mealLog: mealLog, aiConfig: aiConfig))
    }

    init(viewModel: VisualizeFoodViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                switch vm.step {
                case .input: inputStep
                case .confirm: confirmStep
                }
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle("Visualize Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in vm.setImage(data) }.ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) { vm.setImage(data) }
            }
        }
    }

    // MARK: - Input

    private var inputStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            SectionHeader(eyebrow: "Macro", title: "Visualize a dish")
            Text("Describe a dish, photograph a menu, or upload a menu screenshot. We'll picture the plate and estimate its macros.")
                .font(Theme.Typography.callout)
                .foregroundStyle(Theme.Colors.textSecondary)

            DecoTextField(label: "Describe the dish", placeholder: "e.g. chicken pesto pasta", text: $vm.dishText)

            if let data = vm.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .strokeBorder(Theme.Colors.goldLine, lineWidth: 1))
            }

            HStack(spacing: Theme.Spacing.m) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text("Menu screenshot").frame(maxWidth: .infinity)
                }
                .buttonStyle(.decoSecondary)
                Button("Photograph menu") { handleCameraTap() }
                    .buttonStyle(.decoSecondary)
            }

            if cameraDenied {
                SafetyNote(text: CameraPermission.isAvailable
                    ? "Camera access is off. Enable it in Settings, or upload a menu screenshot instead."
                    : "No camera available on this device. Upload a menu screenshot instead.",
                    systemImage: "camera")
            }

            Button {
                Task { await vm.visualize() }
            } label: {
                HStack {
                    if vm.isWorking { ProgressView().tint(Theme.Colors.textOnInk) }
                    Text(vm.isWorking ? "Visualizing…" : "Visualize & estimate")
                }
            }
            .buttonStyle(.decoPrimary)
            .disabled(!vm.canVisualize || vm.isWorking)

            if let error = vm.errorMessage {
                SafetyNote(text: error, systemImage: "exclamationmark.triangle")
            }
        }
    }

    // MARK: - Confirm

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            HStack {
                SectionHeader(eyebrow: "Confirm", title: "Review estimate")
                Spacer()
                StatusTag(text: "Needs review", role: .warning)
            }

            if !vm.visualDescription.isEmpty {
                FramedCard {
                    VStack(alignment: .leading, spacing: 6) {
                        EyebrowText(text: "Visualization")
                        Text(vm.visualDescription)
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }

            DecoTextField(label: "Food name", text: $vm.draftName)
            DecoTextField(label: "Serving", text: $vm.draftServing)
            HStack(spacing: Theme.Spacing.m) {
                DecoTextField(label: "P (g)", text: $vm.draftProtein, keyboard: .decimalPad)
                DecoTextField(label: "C (g)", text: $vm.draftCarbs, keyboard: .decimalPad)
                DecoTextField(label: "F (g)", text: $vm.draftFat, keyboard: .decimalPad)
            }
            DecoTextField(label: "Calories (secondary)", text: $vm.draftCalories, keyboard: .decimalPad)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                EyebrowText(text: "Meal")
                FlowChips(items: MealCategory.allCases,
                          isSelected: { vm.draftCategory == $0 },
                          label: { $0.displayName },
                          toggle: { vm.draftCategory = $0 })
            }

            if let assumptions = vm.draftAssumptions, !assumptions.isEmpty {
                Text("Assumptions: \(assumptions)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            SafetyNote(text: "Estimates are approximate. Edit before saving — confirmed dishes are saved to your library.")

            HStack(spacing: Theme.Spacing.m) {
                Button("Back") { vm.backToInput() }
                    .buttonStyle(.decoSecondary)
                Button("Save & Log") {
                    vm.confirmAndLog()
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
            }
        }
    }

    private func handleCameraTap() {
        guard CameraPermission.isAvailable else { cameraDenied = true; return }
        switch CameraPermission.status {
        case .authorized: showCamera = true
        case .notDetermined:
            Task {
                let granted = await CameraPermission.request()
                if granted { showCamera = true } else { cameraDenied = true }
            }
        default: cameraDenied = true
        }
    }
}
