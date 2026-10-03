import SwiftUI
import Playgrounds
import SwiftData

struct ContentView: View {

    var body: some View {
        NavigationStack{
            TabView{
                Tab("Meds", systemImage: "pill") {
                        MedPageView()
                    }
            }
        }
    }
}

struct MedPageView: View {

    @Environment(\.modelContext) var modelContext
    @Query(sort: \Medication.name) var meds: [Medication]

    var body: some View {
        List(meds) { med in
            Text(med.name)
        }
        .navigationTitle("Medications")
        .toolbar{
            Button("New", systemImage: "plus", action: { createMedication(modelContext: modelContext) })
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Medication.self, TakeLog.self])
}
