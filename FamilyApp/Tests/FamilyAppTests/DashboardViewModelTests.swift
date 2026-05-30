import XCTest
@testable import FamilyApp

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testLoadPopulatesMembersFromRepository() async {
        let repository = InMemoryFamilyRepository(members: [
            FamilyMember(name: "Test Parent", role: .parent),
            FamilyMember(name: "Test Child", role: .child),
        ])
        let model = DashboardViewModel()

        await model.load(using: repository)

        XCTAssertEqual(model.members.count, 2)
        XCTAssertFalse(model.isLoading)
    }

    func testLoadWithEmptyRepositoryYieldsNoMembers() async {
        let model = DashboardViewModel()

        await model.load(using: InMemoryFamilyRepository())

        XCTAssertTrue(model.members.isEmpty)
    }
}
