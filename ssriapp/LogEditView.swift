import SwiftUI
import SwiftData

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
                .font(.system(size: 50, weight: .bold, design: .rounded))
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
    let medication = Medication(name: "Example Med", daysOfWeek: [.monday])
    let log = TakeLog(medication: medication, dose: 20)

    LogEditView(log: log)
        .modelContainer(for: [Medication.self, TakeLog.self], inMemory: true)
}
