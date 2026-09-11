import SwiftUI

enum AISkinIconButtonVariant {
    case plain
    case surface
    case navigation
    case destructive
    case outlined
}

struct AISkinIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var variant: AISkinIconButtonVariant = .plain
    let action: () -> Void

    var body: some View {
        standardButton
        .accessibilityLabel(accessibilityLabel)
    }

    private var standardButton: some View {
        Button(role: variant == .destructive ? .destructive : nil, action: action) {
            icon
                .background(background)
                .clipShape(Circle())
                .overlay {
                    if variant != .plain {
                        Circle().stroke(border, lineWidth: AISkinLayout.hairline)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(AISkinPressableStyle())
    }

    @ViewBuilder
    private var navigationButton: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                icon
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        } else {
            Button(action: action) {
                icon
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle().stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline)
                    }
            }
            .buttonStyle(AISkinPressableStyle())
        }
    }

    private var icon: some View {
        Image(systemName: systemName)
            .font(variant == .outlined ? AISkinTypography.iconSmall : AISkinTypography.iconButton)
            .foregroundStyle(foreground)
            .frame(width: variant == .outlined ? AISkinReportTokens.deleteWidth : AISkinLayout.minimumTapHeight, height: variant == .outlined ? AISkinReportTokens.deleteWidth : AISkinLayout.minimumTapHeight)
            .contentShape(Circle())
    }

    private var foreground: Color {
        switch variant {
        case .plain, .navigation: AISkinColor.textPrimary
        case .surface: AISkinColor.primaryAction
        case .outlined: AISkinColor.accent
        case .destructive: AISkinColor.destructive
        }
    }

    private var background: Color {
        switch variant {
        case .plain: .clear
        case .surface: AISkinColor.surface
        case .outlined: AISkinColor.surface
        case .navigation: AISkinColor.featureSurface
        case .destructive: AISkinColor.destructive.opacity(0.10)
        }
    }

    private var border: Color {
        switch variant {
        case .outlined: AISkinColor.divider
        case .destructive: AISkinColor.destructive.opacity(0.20)
        default: AISkinColor.border
        }
    }
}

#Preview("Icon button") {
    AISkinIconButton(
        systemName: "clock.arrow.circlepath",
        accessibilityLabel: "查看历史记录",
        variant: .surface
    ) {}
    .padding()
}
