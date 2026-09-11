import SwiftUI

enum AISkinCardInset {
    case none
    case regular

    fileprivate var value: CGFloat {
        switch self {
        case .none: 0
        case .regular: AISkinSpacing.cardPadding
        }
    }
}

enum AISkinCardState {
    case normal
    case selected
}

enum AISkinCardRole {
    case content, feature, routine, overlay, action
    var radius: CGFloat {
        switch self {
        case .content, .overlay: AISkinRadius.card
        case .feature: AISkinRadius.featureCard
        case .routine: AISkinRadius.routineCard
        case .action: AISkinRadius.actionCard
        }
    }
    var surface: Color {
        switch self {
        case .content, .action: AISkinColor.surface
        case .feature: AISkinColor.featureSurface
        case .routine: AISkinColor.routineSurface
        case .overlay: AISkinColor.surfaceElevated
        }
    }
}

struct AISkinCard<Content: View>: View {
    private let inset: AISkinCardInset
    private let state: AISkinCardState
    private let role: AISkinCardRole
    private let content: Content

    init(
        inset: AISkinCardInset = .regular,
        state: AISkinCardState = .normal,
        role: AISkinCardRole = .content,
        @ViewBuilder content: () -> Content
    ) {
        self.inset = inset
        self.state = state
        self.role = role
        self.content = content()
    }

    var body: some View {
        content
            .padding(inset == .none ? 0 : (role == .content || role == .overlay) ? inset.value : AISkinSpacing.homeCardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(state == .selected ? AISkinColor.surfaceSelected : role.surface)
            .background {
                if role == .overlay { Rectangle().fill(.regularMaterial) }
            }
            .clipShape(RoundedRectangle(cornerRadius: role.radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: role.radius, style: .continuous)
                    .stroke(state == .selected ? AISkinColor.accent.opacity(0.38) : AISkinColor.border, lineWidth: AISkinLayout.hairline)
            }
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
