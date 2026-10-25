import SwiftUI
import SwiftData

@main struct MyApp: App {
    init() {
        AppFonts.configureNavigationTitles()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.body)
                .tint(.teal)
        }
        .modelContainer(for: [Medication.self, TakeLog.self])
    }
}
