import SwiftUI

/// A single source disclosure at the end of a generated result. No surface,
/// icon, interaction, or navigation behavior is added to the result itself.
struct AISkinAIGeneratedNotice: View {
    var body: some View {
        Text("本内容由 AI 生成，仅供参考。")
            .font(AISkinTypography.aiDisclosure)
            .foregroundStyle(AISkinColor.textSecondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("ai.generated.notice")
    }
}

private struct AISkinGeneratedResultModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.small) {
            content
            AISkinAIGeneratedNotice()
        }
    }
}

extension View {
    /// Apply to the last content block, inside its existing scroll container.
    func aiSkinGeneratedResult() -> some View {
        modifier(AISkinGeneratedResultModifier())
    }
}
