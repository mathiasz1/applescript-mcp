import Foundation
import Observation

/// View model backing `DashboardView`.
///
/// Marked `@MainActor` because it publishes UI state. It owns no dependencies
/// directly; the repository is passed into `load` so the type stays trivially
/// testable.
@MainActor
@Observable
final class DashboardViewModel {
    private(set) var members: [FamilyMember] = []
    private(set) var isLoading = false

    func load(using repository: any FamilyRepository) async {
        isLoading = true
        defer { isLoading = false }
        members = await repository.allMembers()
    }
}
