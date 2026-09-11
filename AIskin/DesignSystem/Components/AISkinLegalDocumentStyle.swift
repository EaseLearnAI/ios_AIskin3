import SwiftUI
import UIKit

/// Adapts the bundled, unmodified public policies to the app's reading surface.
/// Only presentation is appended; policy text, dates, selection and links survive.
@MainActor
enum AISkinLegalDocumentStyle {
    static func applying(to source: String) -> String {
        let style = "<style id=\"aiskin-native-reader\">\(css)</style>"
        guard let headEnd = source.range(of: "</head>", options: .caseInsensitive) else {
            return style + source
        }
        var result = source
        result.insert(contentsOf: style, at: headEnd.lowerBound)
        return result
    }

    private static var css: String {
        let primary = cssColor(AISkinColor.textPrimary)
        let secondary = cssColor(AISkinColor.textSecondary)
        let accent = cssColor(AISkinColor.accent)
        return """
        :root { color-scheme: light; --ink: \(primary); --muted: \(secondary); --green: \(accent); --rose: \(accent); --line: \(cssColor(AISkinColor.divider)); }
        html, body, body *, body *::before, body *::after {
          background: transparent !important; box-shadow: none !important;
          text-shadow: none !important; color: \(primary) !important;
          border-color: var(--line) !important;
        }
        html, body { margin: 0 !important; padding: 0 !important; }
        body, body * {
          font-family: "PingFang SC", -apple-system, BlinkMacSystemFont, sans-serif !important;
          letter-spacing: normal !important;
        }
        body {
          font-size: \(AISkinReportTokens.conflictBodySize)px !important;
          line-height: \(AISkinReportTokens.conflictBodySize + AISkinReportTokens.bodyLineSpacing)px !important;
          overflow-wrap: anywhere;
        }
        .site-header, .document-header h1, .document-header .eyebrow { display: none !important; }
        .page-shell, .document {
          width: auto !important; max-width: none !important; margin: 0 !important;
          border: 0 !important; border-radius: 0 !important;
        }
        .page-shell { padding: 0 !important; }
        .document { padding: \(AISkinSpacing.medium)px \(AISkinSpacing.screenEdge)px \(AISkinSpacing.xLarge)px !important; }
        .document-header { margin: 0 0 \(AISkinReportTokens.sectionGap)px !important; padding: 0 !important; border: 0 !important; }
        .lede, .notice, .path, .contact-card, .data-table { font-size: inherit !important; line-height: inherit !important; }
        .lede { margin: 0 !important; max-width: none !important; }
        .meta {
          display: grid !important; gap: \(AISkinSpacing.xxSmall)px !important;
          margin-top: \(AISkinSpacing.small)px !important;
          font-size: \(AISkinReportTokens.metadataSize)px !important;
        }
        .meta, .meta *, .site-footer { color: \(secondary) !important; }
        .meta span + span::before { content: none !important; }
        .notice, .path, .contact-card { padding: 0 !important; border: 0 !important; border-radius: 0 !important; }
        .notice { margin: \(AISkinSpacing.medium)px 0 !important; }
        .path { display: inline !important; margin: 0 !important; }
        .contact-card { margin-top: \(AISkinSpacing.small)px !important; }
        .document section { scroll-margin-top: \(AISkinSpacing.small)px; }
        .document section + section { margin-top: \(AISkinReportTokens.sectionGap)px !important; padding-top: 0 !important; border: 0 !important; }
        h2 {
          font-size: \(AISkinReportTokens.headingSize)px !important;
          line-height: \(AISkinReportTokens.headingSize + AISkinReportTokens.bodyLineSpacing)px !important;
          margin: 0 0 \(AISkinReportTokens.headingGap)px !important;
        }
        h3 {
          font-size: \(AISkinReportTokens.conflictTitleSize)px !important;
          line-height: \(AISkinReportTokens.conflictTitleSize + AISkinReportTokens.bodyLineSpacing)px !important;
          margin: \(AISkinSpacing.medium)px 0 \(AISkinSpacing.xSmall)px !important;
        }
        p, ul, ol { margin-top: \(AISkinSpacing.xSmall)px !important; margin-bottom: \(AISkinSpacing.xSmall)px !important; }
        li + li { margin-top: \(AISkinSpacing.xSmall)px !important; }
        .data-table { margin: \(AISkinSpacing.small)px 0 !important; }
        .data-table tr { padding: \(AISkinSpacing.small)px 0 !important; }
        .data-table td { padding: \(AISkinSpacing.xxSmall)px 0 !important; }
        .site-footer { padding: 0 \(AISkinSpacing.screenEdge)px \(AISkinSpacing.xLarge)px !important; font-size: \(AISkinReportTokens.metadataSize)px !important; border: 0 !important; }
        body a, body a:visited, body a:hover, body a:focus { color: \(accent) !important; text-decoration: underline; }
        """
    }

    private static func cssColor(_ color: Color) -> String {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return "rgb(\(red * 100)% \(green * 100)% \(blue * 100)% / \(alpha))"
    }
}
