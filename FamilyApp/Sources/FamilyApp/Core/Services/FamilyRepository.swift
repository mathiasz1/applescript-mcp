import Foundation

/// Abstraction over family-member storage.
///
/// Defining a protocol keeps the UI layer independent of the concrete
/// persistence mechanism, so the in-memory implementation used today can be
/// swapped for SwiftData/CloudKit later without touching view code.
protocol FamilyRepository: Sendable {
    func allMembers() async -> [FamilyMember]
    func add(_ member: FamilyMember) async
    func remove(id: FamilyMember.ID) async
}

/// Simple in-memory implementation, suitable for development, previews and tests.
actor InMemoryFamilyRepository: FamilyRepository {
    private var members: [FamilyMember]

    init(members: [FamilyMember] = []) {
        self.members = members
    }

    func allMembers() async -> [FamilyMember] {
        members
    }

    func add(_ member: FamilyMember) async {
        members.append(member)
    }

    func remove(id: FamilyMember.ID) async {
        members.removeAll { $0.id == id }
    }

    /// A repository pre-populated with sample data.
    static func seeded() -> InMemoryFamilyRepository {
        InMemoryFamilyRepository(members: [
            FamilyMember(name: "Alex", role: .parent),
            FamilyMember(name: "Sam", role: .parent),
            FamilyMember(name: "Jordan", role: .child),
            FamilyMember(name: "Riley", role: .child),
        ])
    }
}
