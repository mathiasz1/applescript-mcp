import SwiftUI

/// Placeholder calendar feature. Replace with the real scheduling UI.
struct CalendarView: View {
    var body: some View {
        ContentUnavailableView(
            "Calendar",
            systemImage: "calendar",
            description: Text("Shared family calendar coming soon.")
        )
        .navigationTitle("Calendar")
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
