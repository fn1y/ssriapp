import SwiftUI
import Playgrounds
import SwiftData
import Gradiente

struct ContentView: View {
    var body: some View {
        HomePageView()
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink {
                MedPageView()
            } label: {
                Label("Medications", systemImage: "pill")
            }
            NavigationLink {
                LogPageView()
            } label: {
                Label("Logs", systemImage: "list.bullet")
            }
        }
        .navigationTitle("Settings")
    }
}

struct HomePageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Medication.name) private var medications: [Medication]
    @Query private var logs: [TakeLog]
    @State private var showingSaveError = false

    private let completionColor = Color.green

    var body: some View {
        NavigationStack {
            ZStack {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let due = medicationsDue(on: context.date)
                    let pending = pendingMedications(on: context.date)
                    let allDone = !due.isEmpty && pending.isEmpty
                    let needsDose = pending.contains { $0.presetDose <= 0 }

                    ScrollView {
                        VStack(spacing: 24) {
                            ZStack{
                                Button(action: quickLog) {
                                    Color.clear
                                        .aspectRatio(1, contentMode: .fit)
                                        .glassEffect(
                                            .regular.tint(allDone ? completionColor : nil).interactive(),
                                            in: WavyStamp()
                                        )
                                        .contentShape(WavyStamp())
                                        .overlay {
                                            ZStack {
                                                VStack(spacing: 8) {
                                                    Image(systemName: allDone ? "checkmark" : "plus")
                                                        .font(.largeTitle.bold())
                                                        .contentTransition(.symbolEffect(.replace))
                                                        .symbolEffect(.bounce, value: allDone)
                                                        .symbolEffectsRemoved(reduceMotion)
                                                    Text(allDone ? "All Done" : "Tap to QuickLog")
                                                        .font(.headline)
                                                        .contentTransition(.numericText())
                                                }
                                                Circle()
                                                    .strokeBorder(.primary.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [10]))
                                                    .frame(width: 200, height: 200)
                                                    .accessibilityHidden(true)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                                .disabled(pending.isEmpty || needsDose)
                                .accessibilityLabel(allDone ? "All Done" : "QuickLog today's medications")
                            }
                            
                            HStack{
                                Button(action: {}) {
                                    Label("Undo", systemImage: "trash")
                                }
                                Button(action: {}) {
                                    Label("Edit Dose", systemImage: "pencil.line")
                                }
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .foregroundStyle(.primary)
                            .padding([.bottom,.top], -5)
        
                            Text(due.isEmpty ? "Nothing due today" : (allDone ? "Medication logged" : "Take your meds!"))
                                .font(.largeTitle.bold())
                                .foregroundStyle(allDone ? completionColor : Color.primary)
                                .contentTransition(.numericText())
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            
        
    //                        if medications.isEmpty {
    //                            Text("Open Medications using the top-right toolbar button to add a medication.")
    //                                .foregroundStyle(.secondary)
    //                        } else if needsDose {
    //                            Text("Set a preset dose in Medications using the top-right toolbar button to use QuickLog.")
    //                                .foregroundStyle(.secondary)
    //                        }
                            
                            TimeWindowView()
                            
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: allDone)
                    }
                    .scrollEdgeEffectStyle(.soft, for: .top)
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .background {
                GeometryReader { geometry in
                    Circle()
                        .fill(.gray)
                        .frame(width: 600, height: 600)
                        .blur(radius: 100)
                        // Position the circle's center at the screen's top edge.
                        .position(x: geometry.size.width / 2, y: 0)
                        .opacity(0.7)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Median")
                        .font(.headline)
                        .fontWidth(.expanded)
                        .accessibilityAddTraits(.isHeader)
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
        .alert("Couldn't save your logs", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your medications haven't been marked as taken. Please try again.")
        }
    }

    //function that gets the current date and returns a list of due meds
    private func medicationsDue(on date: Date) -> [Medication] {
        let weekday = Weekdays(rawValue: 1 << (Calendar.current.component(.weekday, from: date) - 1))
        return medications.filter { $0.daysOfWeek.contains(weekday) }
    }

    //function that gets due meds that haven't been taken
    //going to need this explained
    private func pendingMedications(on date: Date) -> [Medication] {
        let takenIDs = Set(logs.compactMap { log in
            Calendar.current.isDate(log.date, inSameDayAs: date) && log.dose > 0
                ? log.medication?.persistentModelID : nil
        })
        return medicationsDue(on: date).filter { !takenIDs.contains($0.persistentModelID) }
    }

    private func quickLog() {
        // Recheck the current day at tap time, including logs entered manually.
        let now = Date.now
        let pending = pendingMedications(on: now)
        guard !pending.isEmpty, pending.allSatisfy({ $0.presetDose > 0 }) else { return }
        
        let newLogs = pending.map {
            TakeLog(medication: $0, dose: $0.presetDose, date: now)
        }
        for log in newLogs {
            modelContext.insert(log)
        }
        do {
            try modelContext.save()
        } catch {
            for log in newLogs {
                modelContext.delete(log)
            }
            showingSaveError = true
        }
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


struct MedPageView: View {

    @Environment(\.modelContext) var modelContext
    @Query(sort: \Medication.name) var meds: [Medication]
    @State private var presentedMed: Medication? = nil

    var body: some View {
        List {
            ForEach(meds) { med in
                NavigationLink(destination: MedEditView(medication: med)) {
                    Text(med.name)
                }
            }
            .onDelete(perform: deleteMed)
        }
        .scrollContentBackground(.hidden)
        .gradienteBackground(position: .top,
                                   opacity: 1,
                                   height: 300.0,
                                   colors: [.cyan, .purple])
        .navigationTitle("Medications")
        .toolbar {
            Button("New", systemImage: "plus", action: { createMed() })
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

struct WavyStamp: Shape {
    var waves: Int = 12
    var depth: CGFloat = 0.055

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let amplitude = radius * depth
        let centre = CGPoint(x: rect.midX, y: rect.midY)

        return Path { path in
            for step in 0..<720 {
                let angle = CGFloat(step) / 720 * .pi * 2
                let r = radius - amplitude
                    + amplitude * cos(CGFloat(waves) * angle)

                let point = CGPoint(
                    x: centre.x + r * cos(angle),
                    y: centre.y + r * sin(angle)
                )

                if step == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            path.closeSubpath()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Medication.self, TakeLog.self])
}
