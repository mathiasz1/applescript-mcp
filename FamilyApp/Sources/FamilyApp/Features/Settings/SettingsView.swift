import SwiftUI

/// App settings and family management entry point.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var members: [FamilyMember] = []

    var body: some View {
        Form {
            Section("Family") {
                ForEach(members) { member in
                    Label(member.name, systemImage: member.role.systemImage)
                }
            }
            Section("About") {
                LabeledContent("Version", value: Bundle.main.appVersion)
            }
        }
        .navigationTitle("Settings")
        .task {
            members = await environment.familyRepository.allMembers()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppEnvironment.preview())
}
