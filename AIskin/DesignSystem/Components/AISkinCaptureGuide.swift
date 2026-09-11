import SwiftUI

enum AISkinCaptureGuideKind {
    case product, skin
}

/// Decorative capture illustration shared by first-use and upload screens.
struct AISkinCaptureGuide: View {
    let kind: AISkinCaptureGuideKind

    @ViewBuilder
    var body: some View {
        if kind == .product {
            Image("PrototypeProductCapture")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: AISkinCaptureAssetLayout.productWidth, height: AISkinCaptureAssetLayout.productHeight)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
        } else {
            skinGuide
        }
    }

    private var skinGuide: some View {
        ZStack {
            Circle().fill(AISkinColor.surface)
            Circle().stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline)
            Circle().stroke(AISkinColor.surfaceSelected, lineWidth: AISkinLayout.captureGuideStroke)
                .frame(width: AISkinLayout.captureGuideInnerDiameter, height: AISkinLayout.captureGuideInnerDiameter)
            Image(systemName: "faceid")
                .font(AISkinTypography.captureGuideIcon)
                .foregroundStyle(AISkinColor.accent)
        }
        .frame(width: AISkinLayout.captureGuideDiameter, height: AISkinLayout.captureGuideDiameter)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AISkinSpacing.medium)
        .accessibilityHidden(true)
    }
}
