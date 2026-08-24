import SwiftUI

struct AISkinCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(
        padding: CGFloat = AISkinSpacing.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AISkinColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AISkinRadius.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AISkinRadius.large, style: .continuous)
                    .stroke(AISkinColor.border, lineWidth: 1)
            }
            .aiSkinShadow()
    }
}

#Preview("Card") {
    AISkinScreenBackground {
        AISkinCard {
            VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                Text("今日护肤")
                    .font(AISkinTypography.cardTitle)
                Text("早晚步骤都已为你准备好")
                    .font(AISkinTypography.body)
                    .foregroundStyle(AISkinColor.textSecondary)
            }
        }
        .padding()
    }
}
