import SwiftUI

/// Original logo embedded in the approved prototype, reused without image changes.
struct AISkinLogoMark: View {
    var size: CGFloat = AISkinAuthLayout.logoSize

    var body: some View {
        Image("PrototypeLogo")
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: AISkinAuthLayout.logoCornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview("Product icon mark") {
    AISkinScreenBackground { AISkinLogoMark() }
}
