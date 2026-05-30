import Foundation

/// A chore or to-do assigned to a family member.
///
/// Named `FamilyTask` to avoid colliding with Swift Concurrency's `Task`.
struct FamilyTask: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var assigneeID: FamilyMember.ID?
    var dueDate: Date?
    var isComplete: Bool

    init(
        id: UUID = UUID(),
        title: String,
        assigneeID: FamilyMember.ID? = nil,
        dueDate: Date? = nil,
        isComplete: Bool = false
    ) {
        self.id = id
        self.title = title
        self.assigneeID = assigneeID
        self.dueDate = dueDate
        self.isComplete = isComplete
    }
}
