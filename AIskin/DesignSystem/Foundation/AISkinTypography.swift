import SwiftUI

/// Dynamic Type-aware type roles used by shared components.
enum AISkinTypography {
    static let screenTitle = Font.system(.title2, design: .rounded, weight: .bold)
    static let sectionTitle = Font.system(.headline, design: .rounded, weight: .bold)
    static let cardTitle = Font.system(.headline, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .rounded)
    static let bodyEmphasized = Font.system(.body, design: .rounded, weight: .semibold)
    static let callout = Font.system(.callout, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
    static let button = Font.system(.body, design: .rounded, weight: .semibold)
}
