import SwiftUI

@main
struct TutorDeskApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(store)
                .frame(minWidth: 1100, minHeight: 720)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                let lang = store.state.settings.appLanguage

                Button(L.t(.cmdNewStudent, lang: lang)) {
                    store.quickAddStudent()
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button(L.t(.cmdNewSession, lang: lang)) {
                    store.quickAddSessionForSelection()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}
