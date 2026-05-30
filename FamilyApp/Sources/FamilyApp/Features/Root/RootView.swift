import SwiftUI

/// Top-level navigation for the iPad layout.
///
/// Uses `NavigationSplitView` to present a persistent sidebar alongside the
/// detail content — the idiomatic structure for a large-canvas iPad app.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                NavigationLink(value: item) {
                    Label(item.title, systemImage: item.systemImage)
                }
            }
            .navigationTitle("FamilyApp")
        } detail: {
            NavigationStack {
                switch selection ?? .dashboard {
                case .dashboard:
                    DashboardView()
                case .calendar:
                    CalendarView()
                case .tasks:
                    TasksView()
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}

/// Sections shown in the sidebar.
enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case calendar
    case tasks
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .calendar: "Calendar"
        case .tasks: "Tasks"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "house"
        case .calendar: "calendar"
        case .tasks: "checklist"
        case .settings: "gearshape"
        }
    }
}

#Preview {
    RootView()
        .environment(AppEnvironment.preview())
}
