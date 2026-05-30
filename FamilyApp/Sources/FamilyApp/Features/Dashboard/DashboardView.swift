import SwiftUI

/// Landing screen summarising family members and upcoming activity.
struct DashboardView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var model = DashboardViewModel()

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(model.members) { member in
                    MemberCard(member: member)
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .overlay {
            if model.isLoading {
                ProgressView()
            } else if model.members.isEmpty {
                ContentUnavailableView(
                    "No Family Members",
                    systemImage: "person.2",
                    description: Text("Add members in Settings to get started.")
                )
            }
        }
        .task {
            await model.load(using: environment.familyRepository)
        }
    }
}

/// Card summarising a single family member.
private struct MemberCard: View {
    let member: FamilyMember

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: member.role.systemImage)
                .font(.largeTitle)
                .foregroundStyle(.tint)
            Text(member.name)
                .font(.headline)
            Text(member.role.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(AppEnvironment.preview())
}
