import SwiftUI

/// Add or edit a tracked supplement. Dosage/schedule/timing are free text — the
/// app records what the user takes, it never prescribes amounts.
struct SupplementEditView: View {
    @EnvironmentObject private var store: SupplementStore
    @Environment(\.dismiss) private var dismiss

    var existing: Supplement?
    @State private var draft = Supplement(name: "")
    @State private var hasStartDate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                SectionHeader(eyebrow: "Supplement", title: existing == nil ? "Add" : "Edit")

                DecoTextField(label: "Name", placeholder: "e.g. Magnesium glycinate", text: $draft.name)
                DecoTextField(label: "Dosage notes", placeholder: "e.g. 1 capsule",
                              text: Binding($draft.dosageNotes, replacingNilWith: ""))
                DecoTextField(label: "Schedule", placeholder: "e.g. Daily, Mon/Wed/Fri",
                              text: Binding($draft.schedule, replacingNilWith: ""))
                DecoTextField(label: "Timing", placeholder: "e.g. With dinner",
                              text: Binding($draft.timing, replacingNilWith: ""))
                DecoTextField(label: "Reason", placeholder: "e.g. sleep, skin support",
                              text: Binding($draft.reason, replacingNilWith: ""))

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    EyebrowText(text: "Status")
                    FlowChips(items: AdherenceState.allCases,
                              isSelected: { draft.adherence == $0 },
                              label: { $0.displayName },
                              toggle: { draft.adherence = $0 })
                }

                Toggle("Set start date", isOn: $hasStartDate)
                    .font(Theme.Typography.body)
                    .tint(Theme.Colors.accent)
                    .onChange(of: hasStartDate) { _, on in draft.startDate = on ? (draft.startDate ?? Date()) : nil }
                if hasStartDate {
                    DatePicker("Start date", selection: Binding(
                        get: { draft.startDate ?? Date() },
                        set: { draft.startDate = $0 }
                    ), displayedComponents: .date)
                    .font(Theme.Typography.body)
                    .tint(Theme.Colors.accent)
                }

                DecoTextField(label: "Notes", placeholder: "Anything to remember",
                              text: Binding($draft.notes, replacingNilWith: ""))

                Button("Save") {
                    draft.name = draft.name.trimmingCharacters(in: .whitespaces)
                    guard !draft.name.isEmpty else { return }
                    store.save(draft)
                    dismiss()
                }
                .buttonStyle(.decoPrimary)
                .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)

                if existing != nil {
                    Button("Delete", role: .destructive) {
                        if let existing { store.delete(existing) }
                        dismiss()
                    }
                    .buttonStyle(.decoSecondary)
                }
            }
            .padding(Theme.Spacing.l)
        }
        .decoBackground()
        .navigationTitle(existing == nil ? "Add Supplement" : "Edit Supplement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        .onAppear {
            if let existing { draft = existing; hasStartDate = existing.startDate != nil }
        }
    }
}

#Preview {
    NavigationStack { SupplementEditView() }.environmentObject(SupplementStore())
}
