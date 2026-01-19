import SwiftUI

struct AppShellView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 210)
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .navigationTitle("TutorDesk")
        .tint(.blue)
        .onAppear {
            TD.uiLanguage = store.state.settings.appLanguage
        }
        .onChange(of: store.state.settings.appLanguage) { _, newValue in
            TD.uiLanguage = newValue
        }
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch store.sidebar {
        case .schedule: ScheduleView()
        case .booking: BookingView()
        case .students: StudentsView()
        case .teacher: TeacherProfileView()
        case .settings: SettingsView()
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch store.sidebar {
        case .schedule: ScheduleDetailView()
        case .booking: BookingDetailView()
        case .students: StudentDetailView()
        case .teacher: TeacherDetailView()
        case .settings: SettingsDetailView()
        }
    }
}
