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
                    Text("Hi")
                }
            }

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
