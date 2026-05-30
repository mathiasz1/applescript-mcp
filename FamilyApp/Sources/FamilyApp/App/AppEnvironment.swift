import Foundation
import Observation

/// Dependency container for the app.
///
/// `AppEnvironment` is the composition root. It wires concrete service
/// implementations together and is injected into the SwiftUI environment by
/// `FamilyAppApp`. Use `AppEnvironment.live()` for the real app and
/// `AppEnvironment.preview()` for SwiftUI previews and tests.
@Observable
final class AppEnvironment {
    let familyRepository: any FamilyRepository

    init(familyRepository: any FamilyRepository) {
        self.familyRepository = familyRepository
    }

    /// Real dependencies used when the app runs on device/simulator.
    static func live() -> AppEnvironment {
        AppEnvironment(familyRepository: InMemoryFamilyRepository.seeded())
    }

    /// Lightweight, deterministic dependencies for previews and unit tests.
    static func preview() -> AppEnvironment {
        AppEnvironment(familyRepository: InMemoryFamilyRepository.seeded())
    }
}
