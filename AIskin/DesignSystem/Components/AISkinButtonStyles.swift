import SwiftUI

struct AISkinPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AISkinTypography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, AISkinSpacing.medium)
            .background(AISkinColor.brandGradient.opacity(isEnabled ? 1 : 0.45))
            .clipShape(RoundedRectangle(cornerRadius: AISkinRadius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(AISkinMotion.emphasized, value: configuration.isPressed)
    }
}

struct AISkinSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AISkinTypography.button)
            .foregroundStyle(AISkinColor.brand)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, AISkinSpacing.medium)
            .background(AISkinColor.surface.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AISkinRadius.medium, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AISkinRadius.medium, style: .continuous)
                    .stroke(AISkinColor.brand.opacity(isEnabled ? 1 : 0.45), lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AISkinMotion.emphasized, value: configuration.isPressed)
    }
}

#Preview("Buttons") {
    AISkinScreenBackground {
        VStack(spacing: AISkinSpacing.medium) {
            Button("开始分析") {}
                .buttonStyle(AISkinPrimaryButtonStyle())
            Button("稍后再说") {}
                .buttonStyle(AISkinSecondaryButtonStyle())
        }
        .padding()
    }
}
