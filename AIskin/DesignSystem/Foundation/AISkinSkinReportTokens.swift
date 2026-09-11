import SwiftUI

/// Skin-specific roles from the final embedded skin report and empty guide.
enum AISkinSkinReportTokens {
    static let chapter = Font.system(size: 17, weight: .semibold)
    static let title = Font.system(size: 14, weight: .semibold)
    static let body = Font.system(size: 13)
    static let label = Font.system(size: 12)
    static let small = Font.system(size: 11)
    static let meta = Font.system(size: 10)
    static let footnote = Font.system(size: 9)
    static let score = Font.system(size: 37, weight: .medium)
    static let comparisonScore = Font.system(size: 29, weight: .medium)
    static let delta = Font.system(size: 19, weight: .medium)
    static let emptyTitle = Font.system(size: 35, weight: .medium)
    static let emptyEmphasis = Font.custom("Songti SC", size: 35, relativeTo: .largeTitle)
    static let ringDiameter: CGFloat = 112
    static let ringStroke: CGFloat = 6
    static let metricGap: CGFloat = 3
    static let metricHeight: CGFloat = 3
    static let summaryGap: CGFloat = 18
    static let summaryHorizontal: CGFloat = 19
    static let summaryBottom: CGFloat = 17
    static let chapterGap: CGFloat = 23
    static let photoMapHeight: CGFloat = 204
    static let observationsMaximumHeight: CGFloat = 260
    static let photoMaximumDiameter: CGFloat = 164
    static let photoBorder: CGFloat = 4
    static let orbitInset: CGFloat = 10
    static let orbitStroke: CGFloat = 3
    static let orbitSegments: [ClosedRange<CGFloat>] = [0.02...0.22, 0.29...0.47, 0.55...0.72, 0.80...0.96]
    static let pinTitle = Font.system(size: 15, weight: .bold)
    static let observationSummary = Font.system(size: 13, weight: .semibold)
    static let pinStatus = Font.system(size: 12)
    static let pinHorizontalPadding: CGFloat = 10
    static let pinVerticalPadding: CGFloat = 10
    static let pinMinimumWidth: CGFloat = 96
    static let pinMaximumWidth: CGFloat = 104
    static let pinWidthFraction: CGFloat = 0.27
    static let pinPhotoGap: CGFloat = 8
    static let pinIndicatorDiameter: CGFloat = 6
    static let pinVerticalFractions: [CGFloat] = [0.24, 0.57, 0.78]
    static let metricFill = AISkinColor.accent.opacity(0.5)
    static let inlineWidth: CGFloat = 68
    static let emptyMinimumHeight: CGFloat = 440
    static let emptyCopyGap: CGFloat = 25
    static let emptyBottomSpace: CGFloat = 56
    static let conditionIconSize: CGFloat = 38
}
