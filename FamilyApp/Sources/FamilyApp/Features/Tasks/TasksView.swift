import SwiftUI

/// Placeholder tasks/chores feature. Replace with the real list UI.
struct TasksView: View {
    var body: some View {
        ContentUnavailableView(
            "Tasks",
            systemImage: "checklist",
            description: Text("Assign and track chores here.")
        )
        .navigationTitle("Tasks")
    }
}

#Preview {
    NavigationStack {
        TasksView()
    }
}
