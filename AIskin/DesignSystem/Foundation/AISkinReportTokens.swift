import SwiftUI

/// Measurements from the shared ingredient/conflict report prototype.
enum AISkinReportTokens {
    // Shared with the native WebKit policy reader's CSS typography.
    static let headingSize: CGFloat = 17
    static let conflictTitleSize: CGFloat = 14
    static let conflictBodySize: CGFloat = 13
    static let metadataSize: CGFloat = 11
    static let score = Font.system(size: 53, weight: .medium)
    static let productTitle = Font.system(size: 20, weight: .semibold)
    static let heading = Font.system(size: headingSize, weight: .semibold)
    static let itemTitle = Font.system(size: 13, weight: .medium)
    static let conflictTitle = Font.system(size: conflictTitleSize, weight: .semibold)
    static let body = Font.system(size: 12)
    static let conflictBody = Font.system(size: conflictBodySize)
    static let caption = Font.system(size: 10)
    static let metadata = Font.system(size: metadataSize)
    // Reading roles retain the existing chapter hierarchy and follow Dynamic Type.
    static let readingHeading = Font.system(.headline, weight: .semibold)
    static let readingTitle = Font.system(.subheadline, weight: .semibold)
    static let readingBody = Font.system(.subheadline)
    static let readingSummary = Font.system(.callout)
    static let readingCaption = Font.system(.footnote)
    static let readingScore = Font.system(.title3, weight: .semibold)
    static let readingLineSpacing: CGFloat = 4
    static let readingRowGap: CGFloat = 18
    static let readingSummaryLineLimit = 4
    static let readingBodyLineLimit = 3
    static let readingDisclosureThreshold = 50
    static let readingSummaryDisclosureThreshold = 70
    static let scoreTracking: CGFloat = -2
    static let sectionGap: CGFloat = 27
    static let headingGap: CGFloat = 12
    static let rowGap: CGFloat = 15
    static let bodyLineSpacing: CGFloat = 6
    static let thumbnailWidth: CGFloat = 65
    static let thumbnailHeight: CGFloat = 78
    static let thumbnailRadius: CGFloat = 17
    static let thumbnailIcon = Font.system(size: 28, weight: .light)
    static let compactSheetHeight: CGFloat = 520
    static let actionSheetHeight: CGFloat = 300
    static let explanationSheetHeight: CGFloat = 220
    static let dateSheetHeight: CGFloat = 470
    static let ingredientRowHeight: CGFloat = 70
    static let ingredientListInset: CGFloat = 17
    static let scrollCardMaxHeight = ingredientRowHeight * 4 + AISkinLayout.hairline * 3
    static let actionCardInset: CGFloat = 18
    static let cellHeight: CGFloat = 46
    static let deleteWidth: CGFloat = 48
    static let dotDiameter: CGFloat = 6
    static let anchorRadius: CGFloat = 10
    static let cellRadius: CGFloat = 12
    static let anchorInset: CGFloat = 3
    static let anchorHeight: CGFloat = 44
    static var anchorScrollClearance: CGFloat { anchorHeight + anchorInset * 2 + headingGap }
}
