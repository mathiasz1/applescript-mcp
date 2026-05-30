import SwiftUI

/// Application entry point.
///
/// FamilyApp is an iPad-first SwiftUI application. The app uses a single
/// `AppEnvironment` injected into the SwiftUI environment so that views and
/// view models can resolve their dependencies (services, repositories) without
/// global singletons.
@main
struct FamilyAppApp: App {
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
    }
}
