//
//  MedEditView.swift
//  ssriapp
//
//  Created by Finlay Carson Moretti on 03/10/2026.
//

import SwiftUI
import SwiftData

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

#Preview {
    MedEditView(medication: Medication(name: "Example Med", daysOfWeek: [.monday, .wednesday, .friday]))
        .modelContainer(for: [Medication.self, TakeLog.self], inMemory: true)
}
