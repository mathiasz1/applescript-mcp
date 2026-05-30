import SwiftUI

/// Centralised design tokens. Keep spacing, radii and typography here so the
/// app stays visually consistent and easy to restyle.
enum Theme {
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 16
    }
}
