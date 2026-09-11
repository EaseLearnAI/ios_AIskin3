import SwiftUI

/// Values from the standalone three-page 20260911 reference.
enum AISkinOnboardingTokens {
    static let titleSize: CGFloat = 29
    static let compactTitleSize: CGFloat = 27
    static let bodySize: CGFloat = 12
    static let numberSize: CGFloat = 13
    static let titleSpacing: CGFloat = 7
    static let copyLineSpacing: CGFloat = 7
    static let titleTracking: CGFloat = -0.65
    static let numberTracking: CGFloat = 1
    static let numberOpacity = 0.75
    static let topInset: CGFloat = 31
    static let compactTopInset: CGFloat = 17
    static let compactHeight: CGFloat = 520
    static let headingHeight: CGFloat = 215
    static let artworkMaxSize: CGFloat = 372
    static let artworkMinimumSize: CGFloat = 160
    static let artworkInset: CGFloat = 14
    static let contentMaxWidth: CGFloat = 430
    static let dotSize: CGFloat = 6
    static let inactiveDotOpacity = 0.22
    static let footerGap: CGFloat = 14
    static let footerBottom: CGFloat = 8
    static let buttonRadius: CGFloat = 19
    static let entranceOffset: CGFloat = 9
    static let entranceAnimation = Animation.easeOut(duration: 0.6)
    static let autoAdvanceInterval: Duration = .seconds(5)
    static let autoAdvanceCheckInterval: Duration = .milliseconds(250)

    // Alpha masks soften artwork edges without altering the screen background.
    static let verticalMask = Gradient(stops: [
        .init(color: AISkinColor.textPrimary.opacity(0), location: 0),
        .init(color: AISkinColor.textPrimary, location: 0.05),
        .init(color: AISkinColor.textPrimary, location: 0.89),
        .init(color: AISkinColor.textPrimary.opacity(0), location: 1)
    ])
    static let horizontalMask = Gradient(stops: [
        .init(color: AISkinColor.textPrimary.opacity(0), location: 0),
        .init(color: AISkinColor.textPrimary, location: 0.05),
        .init(color: AISkinColor.textPrimary, location: 0.95),
        .init(color: AISkinColor.textPrimary.opacity(0), location: 1)
    ])
}
