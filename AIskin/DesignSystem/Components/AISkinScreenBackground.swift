import SwiftUI

struct AISkinScreenBackground<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AISkinColor.screenGradient
                .ignoresSafeArea()
            content
        }
    }
}

#Preview("Screen background") {
    AISkinScreenBackground {
        Text("析肤 AI")
            .font(AISkinTypography.screenTitle)
            .foregroundStyle(AISkinColor.textPrimary)
    }
}
