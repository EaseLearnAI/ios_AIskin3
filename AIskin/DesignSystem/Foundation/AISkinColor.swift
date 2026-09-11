import SwiftUI

enum AISkinColor {
    // MARK: - Screen background

    static let screenBaseTop = Color(red: 0.933, green: 0.914, blue: 0.973)
    static let screenBaseMiddle = Color(red: 0.965, green: 0.937, blue: 0.969)
    static let screenBaseBottom = Color(red: 0.976, green: 0.973, blue: 0.984)
    static let screenGlowTopLeading = Color(red: 0.914, green: 0.635, blue: 0.867).opacity(0.74)
    static let screenGlowTopTrailing = Color(red: 0.761, green: 0.663, blue: 0.937).opacity(0.68)
    static let screenGlowMiddleLower = Color(red: 0.933, green: 0.776, blue: 0.902).opacity(0.58)

    // MARK: - Brand and content

    static let accent = Color(red: 0.420, green: 0.302, blue: 0.525)
    static let primaryAction = Color(red: 0.176, green: 0.169, blue: 0.196)
    static let textPrimary = Color(red: 0.161, green: 0.149, blue: 0.184)
    static let textSecondary = Color(red: 0.439, green: 0.408, blue: 0.471)
    static let textOnAccent = Color.white

    // MARK: - Surfaces

    static let surface = Color.white.opacity(0.58)
    static let featureSurface = Color.white.opacity(0.32)
    static let routineSurface = Color.white.opacity(0.37)
    static let surfaceElevated = Color.white.opacity(0.82)
    static let sheetSurface = screenBaseBottom
    static let surfaceMuted = Color(red: 0.969, green: 0.941, blue: 0.976).opacity(0.56)
    static let surfaceSelected = accent.opacity(0.10)
    static let border = Color.white.opacity(0.72)
    static let divider = textSecondary.opacity(0.18)
    static let scrim = primaryAction.opacity(0.24)

    // MARK: - Semantic states

    static let success = Color(red: 0.200, green: 0.620, blue: 0.420)
    static let warning = Color(red: 0.941, green: 0.588, blue: 0.180)
    static let destructive = Color(red: 0.831, green: 0.180, blue: 0.200)
    // Reuse the existing semantic red for recorded skin concerns. This role
    // never applies to a negative finding, an unknown state, or the background.
    static let skinConcern = destructive
    static let skinConcernSelected = skinConcern.opacity(0.08)

}
