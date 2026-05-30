import Foundation

/// A member of the family.
struct FamilyMember: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var role: Role

    init(id: UUID = UUID(), name: String, role: Role) {
        self.id = id
        self.name = name
        self.role = role
    }

    /// The role a member plays within the family.
    enum Role: String, Codable, CaseIterable {
        case parent
        case child
        case guardian

        var displayName: String {
            switch self {
            case .parent: "Parent"
            case .child: "Child"
            case .guardian: "Guardian"
            }
        }

        var systemImage: String {
            switch self {
            case .parent: "person.fill"
            case .child: "figure.child"
            case .guardian: "person.badge.shield.checkmark"
            }
        }
    }
}
