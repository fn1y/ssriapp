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
                        ForEach(medications) { medication in
                            Text(medication.name)
                                .tag(medication)
                        }
                    }
                }

                Section("Dose") {
                    Stepper(value: $log.dose, in: 0...10_000, step: 5) {
                        HStack {
                            Text("Dose")
                            Spacer()
                            Text(log.dose, format: .number)
                                .contentTransition(.numericText(value: Double(log.dose)))
                                .animation(.default, value: log.dose)
                            Text("mg")
                        }
                    }
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

#Preview {
    let medication = Medication(name: "Example Med", daysOfWeek: [.monday])
    let log = TakeLog(medication: medication, dose: 20)

    LogEditView(log: log)
        .modelContainer(for: [Medication.self, TakeLog.self], inMemory: true)
}
