import SwiftUI
import UIKit

enum AISkinColor {
    static let brand = dynamic(
        light: UIColor(red: 0.91, green: 0.30, blue: 0.24, alpha: 1),
        dark: UIColor(red: 1.00, green: 0.48, blue: 0.42, alpha: 1)
    )

    static let brandSecondary = dynamic(
        light: UIColor(red: 0.46, green: 0.29, blue: 0.64, alpha: 1),
        dark: UIColor(red: 0.68, green: 0.52, blue: 0.86, alpha: 1)
    )

    static let background = dynamic(
        light: UIColor(red: 1.00, green: 0.98, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.07, green: 0.06, blue: 0.08, alpha: 1)
    )

    static let backgroundSecondary = dynamic(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.11, green: 0.10, blue: 0.13, alpha: 1)
    )

    static let surface = dynamic(
        light: .white,
        dark: UIColor(red: 0.15, green: 0.14, blue: 0.17, alpha: 1)
    )

    static let surfaceElevated = dynamic(
        light: .white,
        dark: UIColor(red: 0.20, green: 0.18, blue: 0.22, alpha: 1)
    )

    static let textPrimary = dynamic(
        light: UIColor(red: 0.12, green: 0.16, blue: 0.23, alpha: 1),
        dark: UIColor(red: 0.96, green: 0.95, blue: 0.97, alpha: 1)
    )

    static let textSecondary = dynamic(
        light: UIColor(red: 0.39, green: 0.42, blue: 0.48, alpha: 1),
        dark: UIColor(red: 0.70, green: 0.68, blue: 0.73, alpha: 1)
    )

    static let border = dynamic(
        light: UIColor(red: 0.90, green: 0.91, blue: 0.93, alpha: 1),
        dark: UIColor(red: 0.29, green: 0.27, blue: 0.31, alpha: 1)
    )

    static let success = Color(red: 0.20, green: 0.62, blue: 0.42)
    static let warning = Color(red: 0.94, green: 0.59, blue: 0.18)
    static let destructive = Color(red: 0.83, green: 0.18, blue: 0.20)

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [brand, brandSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [background, backgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
