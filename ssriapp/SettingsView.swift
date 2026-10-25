import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var presentedMedication: Medication?

    var body: some View {
        List {
            MyMedicationsSection(presentedMedication: $presentedMedication)

            Section {
                NavigationLink {
                    LogPageView()
                } label: {
                    Label("Logs", systemImage: "list.bullet")
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(item: $presentedMedication) { medication in
            MedEditView(medication: medication)
        }
    }
}

private struct MyMedicationsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medication.name) private var medications: [Medication]
    @Binding var presentedMedication: Medication?

    var body: some View {
        Section {
            if medications.isEmpty {
                Text("No medications yet")
                    .foregroundStyle(.secondary)
            }

            ForEach(medications) { medication in
                NavigationLink {
                    MedEditView(medication: medication)
                } label: {
                    Text(medication.name)
                }
            }
            .onDelete(perform: deleteMedications)

            Button(action: createMedication) {
                Label("Add medication", systemImage: "plus.circle")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.tint)
        } header: {
            Text("My medications")
                .textCase(nil)
        }
    }

    private func deleteMedications(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(medications[index])
        }
    }

    private func createMedication() {
        let medication = Medication(name: "Untitled Medication", daysOfWeek: [.monday])
        modelContext.insert(medication)
        presentedMedication = medication
    }
}

struct LogPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TakeLog.date, order: .reverse) private var logs: [TakeLog]
    @Query(sort: \Medication.name) private var medications: [Medication]
    @State private var presentedLog: TakeLog?

    var body: some View {
        List {
            ForEach(logs) { log in
                NavigationLink(destination: LogEditView(log: log)) {
                    VStack(alignment: .leading) {
                        if let medication = log.medication {
                            Text(medication.name)
                        } else {
                            Text("Deleted Medication")
                        }
                        Text("\(log.dose)mg • \(log.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteLogs)
        }
        .navigationTitle("Logs")
        .toolbar {
            Button("New", systemImage: "plus", action: createLog)
                .disabled(medications.isEmpty)
        }
        .overlay {
            if medications.isEmpty && logs.isEmpty {
                ContentUnavailableView(
                    "No Medications",
                    systemImage: "pill",
                    description: Text("Create a medication before creating a log.")
                )
            }
        }
        .sheet(item: $presentedLog) { log in
            LogEditView(log: log)
        }
    }

    private func deleteLogs(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(logs[index])
        }
    }

    private func createLog() {
        guard let medication = medications.first else { return }

        let log = TakeLog(medication: medication)
        modelContext.insert(log)
        presentedLog = log
    }
}

struct MedEditView: View {
    //view will expect a Medication object
    //Bindable means any changes user makes in the ui get passed through and saved immediately
    @Bindable var medication: Medication
    
    //Weekdays is a struct that can be used everywhere now
    //let weekdayItems equal a list of sets, one string for the ui, and the actual Weekdays option it corresponds to
    private let weekdayItems: [(label: String, option: Weekdays)] = [
        ("Sunday", .sunday),
        ("Monday", .monday),
        ("Tuesday", .tuesday),
        ("Wednesday", .wednesday),
        ("Thursday", .thursday),
        ("Friday", .friday),
        ("Saturday", .saturday)
    ]
    
    var body: some View {
        NavigationStack{
            Form {
                Section("Name") {
                    TextField("Medication name", text: $medication.name)
                }
                Section {
                    DoseControls(dose: $medication.presetDose)
                } header: {
                    Text("Preset Dose")
                } footer: {
                    Text("QuickLog uses this dose. Set a dose above 0mg to enable QuickLog.")
                }
                Section("Schedule") {
                    //for each 
                    ForEach(weekdayItems, id: \.label) { item in
                        Toggle(item.label, isOn: Binding(
                            get: { medication.daysOfWeek.contains(item.option) },
                            set: { isOn in
                                if isOn {
                                    medication.daysOfWeek.insert(item.option)
                                } else {
                                    medication.daysOfWeek.remove(item.option)
                                }
                            }
                        ))
                    }
                }
            }
        }
    }
}

struct LogEditView: View {
    @Bindable var log: TakeLog
    @Query(sort: \Medication.name) private var medications: [Medication]

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    Picker("Medication", selection: $log.medication) {
                        if log.medication == nil {
                            Text("Deleted Medication")
                                .tag(nil as Medication?)
                        }
                        ForEach(medications) { medication in
                            Text(medication.name)
                                .tag(medication)
                        }
                    }
                }

                Section("Dose") {
                    DoseControls(dose: $log.dose)
                }

                Section("Date") {
                    DatePicker(
                        "Taken at",
                        selection: $log.date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle("Edit Log")
        }
    }
}

struct DoseControls: View {
    @Binding var dose: Int

    private let presets = Array(stride(from: 25, through: 300, by: 25))

    var body: some View {
        Stepper(value: $dose, in: 0...10_000, step: 5) {
            Text("\(dose)mg")
                .contentTransition(.numericText(value: Double(dose)))
                .animation(.default, value: dose)
                .font(.custom("SNPro-Regular", size: 50, relativeTo: .largeTitle).bold())
        }

        ScrollView(.horizontal) {
            HStack {
                ForEach(presets, id: \.self) { preset in
                    Button("\(preset)mg") {
                        dose = preset
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .clipShape(.capsule)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Medication.self, TakeLog.self], inMemory: true)
}
