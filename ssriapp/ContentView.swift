import SwiftUI
import Playgrounds
import SwiftData

struct ContentView: View {

    var body: some View {

            TabView{
                Tab("Home", systemImage: "house"){
                    Text("There's nothing here yet")
                    Text("In fact the fancy UI stuff will come last")
                }
                Tab("(Debug) Meds", systemImage: "pill") {
                        MedPageView()
                    }
                Tab("(Debug) Logs", systemImage: "list.bullet") {
                    LogPageView()
                }
            }

    }
}

struct LogPageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TakeLog.date, order: .reverse) private var logs: [TakeLog]
    @Query(sort: \Medication.name) private var medications: [Medication]
    @State private var presentedLog: TakeLog?

    var body: some View {
        NavigationStack {
            List {
                ForEach(logs) { log in
                    NavigationLink(destination: LogEditView(log: log)) {
                        VStack(alignment: .leading) {
                            Text(log.medication.name)
                            Text("Dose: \(log.dose) • \(log.date.formatted(date: .abbreviated, time: .shortened))")
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
                if medications.isEmpty {
                    ContentUnavailableView(
                        "No Medications",
                        systemImage: "pill",
                        description: Text("Create a medication before creating a log.")
                    )
                }
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


struct MedPageView: View {

    @Environment(\.modelContext) var modelContext
    @Query(sort: \Medication.name) var meds: [Medication]
    @State private var presentedMed: Medication? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(meds) { med in
                    NavigationLink(destination: MedEditView(medication: med)) {
                        Text(med.name)
                    }
                }
                .onDelete(perform: deleteMed)
            }
            .navigationTitle("Medications")
            .toolbar {
                Button("New", systemImage: "plus", action: { createMed() })
            }
        }
        .sheet(item: $presentedMed) { med in
            MedEditView(medication: med)
        }
    }
    
    private func deleteMed(_ indexSet: IndexSet) {
            for index in indexSet {
                let destination = meds[index]
                modelContext.delete(destination)
            }
        }

    private func createMed() {
        let med = Medication(name: "Untitled Medication", daysOfWeek: [.monday])
        modelContext.insert(med)
        presentedMed = med
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Medication.self, TakeLog.self])
}
