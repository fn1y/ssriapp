import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Medication.name) private var medications: [Medication]
    @Query private var logs: [TakeLog]
    @State private var presentedMedication: Medication?
    @State private var showingSaveError = false
    @State private var refreshDate = Date.now

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: refreshDate, by: 60)) { timeline in
                let now = max(timeline.date, refreshDate)
                let due = medications.filter { MedicationCompletion.isDue($0, on: now) }
                let completedIDs = Set(logs.filter {
                    $0.dose > 0 && Calendar.current.isDate($0.date, inSameDayAs: now)
                }.compactMap { $0.medication?.persistentModelID })

                ScrollView {
                    VStack(spacing: 16) {
                        if due.isEmpty {
                            ContentUnavailableView(
                                medications.isEmpty ? "No medications yet" : "Nothing due today",
                                systemImage: "pill",
                                description: medications.isEmpty
                                    ? Text("Add a medication in Settings to get started.")
                                    : nil
                            )
                        }

                        ForEach(due) { medication in
                            MedicationCard(
                                medication: medication,
                                isDone: completedIDs.contains(medication.persistentModelID),
                                toggleCompletion: { toggleCompletion(for: medication) },
                                edit: { presentedMedication = medication }
                            )
                        }
                    }
                    .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack {
                            Text(now.formatted(.dateTime.weekday(.wide)))
                                .accessibilityAddTraits(.isHeader)
                            Text(now.formatted(.dateTime.day()))
                                .foregroundStyle(.teal)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.teal.opacity(0.2))
                                }
                            Text(now.formatted(.dateTime.month(.abbreviated)))
                        }
                        .font(.title3.bold())
                        .padding()
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    ToolbarSpacer()
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("New", systemImage: "plus")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                }
            }
        }
        .sheet(item: $presentedMedication) { medication in
            MedEditView(medication: medication)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshDate = .now
            }
        }
        .alert("Couldn't update your logs", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The completion change wasn't saved. Please try again.")
        }
    }

    private func toggleCompletion(for medication: Medication) {
        do {
            try MedicationCompletion.toggle(medication, in: modelContext)
        } catch {
            showingSaveError = true
        }
        refreshDate = .now
    }
}

private struct MedicationCard: View {
    let medication: Medication
    let isDone: Bool
    let toggleCompletion: () -> Void
    let edit: () -> Void

    private var schedule: String {
        if medication.daysOfWeek.rawValue & 127 == 127 {
            return String(localized: "Daily")
        }
        let symbols = Calendar.current.shortWeekdaySymbols
        return (0..<7).filter {
            medication.daysOfWeek.contains(Weekdays(rawValue: 1 << $0))
        }.map { symbols[$0] }.formatted(.list(type: .and, width: .short))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(medication.name)
                        .font(.headline.bold())
                    Text("\(schedule) ∙ \(medication.presetDose)mg")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: toggleCompletion) {
                    Image(systemName: isDone ? "checkmark" : "plus")
                        .font(.title3.bold())
                        .frame(width: 52, height: 52)
                        .glassEffect(
                            .regular.tint(isDone ? .green : nil).interactive(),
                            in: WavyStamp()
                        )
                        .contentShape(WavyStamp())
                }
                .buttonStyle(.plain)
                .disabled(!isDone && medication.presetDose <= 0)
                .accessibilityLabel(isDone
                    ? "Undo today's logs for \(medication.name)"
                    : "Mark \(medication.name) as done")
                .accessibilityValue(isDone ? "Done" : "Not taken")
                .accessibilityHint(isDone
                    ? "Removes all positive-dose logs for this medication today."
                    : "Logs the preset dose.")
            }

            if !isDone && medication.presetDose <= 0 {
                Text("Set a dose using Edit Medication to enable logging.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
            TimeWindowView()
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 30))
        .contentShape(.rect(cornerRadius: 30))
        .contextMenu {
            Button("Edit Medication", systemImage: "pencil", action: edit)
        }
        .accessibilityAction(named: "Edit Medication", edit)
    }
}

/// Uses saved logs as the source of truth for each day's completion.
enum MedicationCompletion {
    static func isDue(_ medication: Medication, on date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date) - 1
        return medication.daysOfWeek.contains(Weekdays(rawValue: 1 << weekday))
    }

    @MainActor
    static func toggle(_ medication: Medication, in context: ModelContext, now: Date = .now) throws {
        guard isDue(medication, on: now), !medication.isDeleted else { return }

        // Commit existing edits first so rollback can only undo this operation.
        // If this save fails, leave those edits in memory and do not change logs.
        try context.save()
        let todaysLogs = try context.fetch(FetchDescriptor<TakeLog>()).filter {
            $0.medication?.persistentModelID == medication.persistentModelID
                && $0.dose > 0
                && Calendar.current.isDate($0.date, inSameDayAs: now)
        }
        guard !todaysLogs.isEmpty || medication.presetDose > 0 else { return }

        do {
            if todaysLogs.isEmpty {
                context.insert(TakeLog(medication: medication, dose: medication.presetDose, date: now))
            } else {
                for log in todaysLogs {
                    context.delete(log)
                }
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

@MainActor
private func medicationPreviewContainer() throws -> ModelContainer {
    let container = try ModelContainer(
        for: Medication.self, TakeLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let daily = Weekdays(rawValue: 127)
    let pending = Medication(name: "Sertraline", daysOfWeek: daily, presetDose: 50)
    let completed = Medication(name: "Example completed medication", daysOfWeek: daily, presetDose: 25)
    let needsDose = Medication(name: "Example without a dose", daysOfWeek: daily)
    container.mainContext.insert(pending)
    container.mainContext.insert(completed)
    container.mainContext.insert(needsDose)
    container.mainContext.insert(TakeLog(medication: completed, dose: 25))
    return container
}

#Preview("Medications") {
    if let container = try? medicationPreviewContainer() {
        ContentView()
            .modelContainer(container)
    } else {
        Text("Unable to create preview data")
    }
}

#Preview("Empty") {
    ContentView()
        .modelContainer(for: [Medication.self, TakeLog.self], inMemory: true)
}
