import SwiftUI

enum AISkinButtonVariant {
    case primary
    case secondary
    case surface
    case destructive
}

enum AISkinButtonLayout {
    case fullWidth
    case compact
}

struct AISkinButton<Label: View>: View {
    let variant: AISkinButtonVariant
    let layout: AISkinButtonLayout
    var isLoading = false
    let action: () -> Void
    private let label: Label

    init(
        variant: AISkinButtonVariant = .primary,
        layout: AISkinButtonLayout = .fullWidth,
        isLoading: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.variant = variant
        self.layout = layout
        self.isLoading = isLoading
        self.action = action
        self.label = label()
    }

    var body: some View {
        styledButton
            .disabled(isLoading)
    }

    private var button: some View {
        Button(role: variant == .destructive ? .destructive : nil, action: action) {
            ZStack {
                // ViewBuilder labels may contain sibling Text and Image views.
                // Lay those out before overlaying the loading indicator.
                HStack(spacing: AISkinSpacing.xSmall) { label }
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .allowsTightening(true)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(foreground)
                }
            }
            .frame(maxWidth: layout == .fullWidth ? .infinity : nil)
        }
        .font(layout == .compact ? AISkinTypography.compactButton : AISkinTypography.button)
        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: AISkinRadius.control))
    }

    @ViewBuilder
    private var styledButton: some View {
        switch variant {
        case .primary:
            button
                .buttonStyle(.borderedProminent)
                .tint(AISkinColor.primaryAction)
        case .secondary:
            button
                .buttonStyle(.bordered)
                .tint(AISkinColor.accent)
        case .surface:
            button
                .buttonStyle(AISkinSurfaceButtonStyle())
        case .destructive:
            button
                .buttonStyle(.bordered)
                .tint(AISkinColor.destructive)
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: AISkinColor.textOnAccent
        case .secondary: AISkinColor.accent
        case .surface: AISkinColor.textPrimary
        case .destructive: AISkinColor.destructive
        }
    }
}

private struct AISkinSurfaceButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AISkinColor.textPrimary)
            .padding(.horizontal, AISkinSpacing.large)
            .frame(minWidth: AISkinLayout.minimumTapHeight, minHeight: AISkinLayout.minimumTapHeight)
            .background(configuration.isPressed ? AISkinColor.surfaceSelected : AISkinColor.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: AISkinRadius.control))
            .overlay {
                RoundedRectangle(cornerRadius: AISkinRadius.control)
                    .stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline)
            }
            .aiSkinShadow()
            .contentShape(RoundedRectangle(cornerRadius: AISkinRadius.control))
            .opacity(isEnabled ? 1 : 0.45)
            .animation(AISkinMotion.emphasized, value: configuration.isPressed)
            .animation(AISkinMotion.emphasized, value: isEnabled)
    }
}

struct AISkinPressableStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.45)
            .animation(AISkinMotion.emphasized, value: configuration.isPressed)
            .animation(AISkinMotion.emphasized, value: isEnabled)
    }
}

#Preview("Buttons") {
    AISkinScreenBackground {
        VStack(spacing: AISkinSpacing.medium) {
            AISkinButton(action: {}) { Text("开始分析") }
            AISkinButton(variant: .secondary, action: {}) { Text("稍后再说") }
        }
        .padding()
    }
}
