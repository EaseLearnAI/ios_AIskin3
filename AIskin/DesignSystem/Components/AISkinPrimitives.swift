import SwiftUI

enum AISkinFieldState {
    case normal
    case focused
    case loading
    case error
}

enum AISkinFieldVariant {
    case standard, form

    var radius: CGFloat {
        self == .form ? AISkinRadius.medium : AISkinRadius.control
    }

    var minimumHeight: CGFloat {
        self == .form ? AISkinLayout.listRowMinimumHeight : AISkinLayout.fieldMinimumHeight
    }
}

struct AISkinField<Content: View>: View {
    var state: AISkinFieldState = .normal
    var variant: AISkinFieldVariant = .standard
    private let content: Content

    init(state: AISkinFieldState = .normal, variant: AISkinFieldVariant = .standard, @ViewBuilder content: () -> Content) {
        self.state = state
        self.variant = variant
        self.content = content()
    }

    var body: some View {
        HStack(spacing: AISkinSpacing.xSmall) {
            content
            if state == .loading {
                ProgressView().tint(AISkinColor.accent)
            }
        }
        .font(AISkinAccountPlanTokens.fieldText)
        .foregroundStyle(AISkinColor.textPrimary)
        .padding(.horizontal, AISkinSpacing.medium)
        .frame(minHeight: variant.minimumHeight)
        .background(AISkinColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: variant.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: variant.radius, style: .continuous)
                .stroke(borderColor, lineWidth: state == .focused || state == .error ? AISkinLayout.emphasisLineWidth : AISkinLayout.hairline)
        }
    }

    private var borderColor: Color {
        switch state {
        case .focused: AISkinColor.accent
        case .error: AISkinColor.destructive
        case .normal, .loading: AISkinColor.border
        }
    }
}

enum AISkinTagTone {
    case neutral
    case accent
    case success
    case warning
    case destructive
}

enum AISkinTagState {
    case normal
    case selected
    case disabled
}

enum AISkinTagSize {
    case compact
    case regular

    fileprivate var font: Font {
        switch self {
        case .compact: AISkinTypography.caption
        case .regular: AISkinTypography.reportBody
        }
    }

    fileprivate var horizontalPadding: CGFloat {
        switch self {
        case .compact: AISkinSpacing.small
        case .regular: AISkinSpacing.medium
        }
    }

    fileprivate var minHeight: CGFloat {
        switch self {
        case .compact: AISkinLayout.compactTagHeight
        case .regular: AISkinLayout.regularTagHeight
        }
    }
}

enum AISkinTagVariant {
    case badge
    case selectionCell
    case selectionPill
}

struct AISkinTag: View {
    let title: String
    var systemImage: String?
    var tone: AISkinTagTone = .neutral
    var state: AISkinTagState = .normal
    var size: AISkinTagSize = .compact
    var variant: AISkinTagVariant = .badge
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                if variant != .badge {
                    Button(action: action) { label }
                        .buttonStyle(AISkinPressableStyle())
                        .accessibilityAddTraits(state == .selected ? .isSelected : [])
                } else {
                    Button(action: action) { label }
                        .buttonStyle(.plain)
                        .frame(minWidth: AISkinLayout.minimumTapHeight, minHeight: AISkinLayout.minimumTapHeight)
                }
            } else {
                label
            }
        }
        .opacity(state == .disabled ? 0.45 : 1)
        .disabled(state == .disabled)
        .accessibilityAddTraits(state == .selected ? .isSelected : [])
    }

    private var label: some View {
        HStack(spacing: AISkinSpacing.xxSmall) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.80)
            if variant == .selectionCell, state == .selected {
                Image(systemName: "checkmark").font(AISkinTypography.compactCaption)
            }
        }
        .font(variant != .badge ? AISkinAccountPlanTokens.fieldText : size.font)
        .foregroundStyle(foreground)
        .padding(.horizontal, variant == .selectionPill ? AISkinSpacing.xxSmall : size.horizontalPadding)
        .frame(maxWidth: variant != .badge ? .infinity : nil,
               minHeight: variant != .badge ? AISkinLayout.listRowMinimumHeight : size.minHeight)
        .background {
            if variant == .selectionCell {
                RoundedRectangle(cornerRadius: AISkinAccountPlanTokens.goalCornerRadius, style: .continuous)
                    .fill(state == .selected ? AISkinColor.surfaceElevated : AISkinColor.surface)
            } else { Capsule().fill(variant == .selectionPill ? (state == .selected ? AISkinColor.surfaceSelected : AISkinColor.surface) : background) }
        }
        .overlay {
            if variant == .selectionCell {
                RoundedRectangle(cornerRadius: AISkinAccountPlanTokens.goalCornerRadius, style: .continuous)
                    .stroke(state == .selected ? AISkinColor.accent : AISkinColor.border, lineWidth: AISkinLayout.hairline)
            } else {
                Capsule().stroke(variant == .selectionPill && state == .selected ? AISkinColor.accent : foreground.opacity(0.24),
                                 lineWidth: variant == .selectionPill && state == .selected ? AISkinLayout.emphasisLineWidth : AISkinLayout.hairline)
            }
        }
    }

    private var foreground: Color {
        if variant == .selectionCell { return state == .selected ? AISkinColor.accent : AISkinColor.textPrimary }
        return switch tone {
        case .neutral: AISkinColor.textSecondary
        case .accent: AISkinColor.accent
        case .success: AISkinColor.success
        case .warning: AISkinColor.warning
        case .destructive: AISkinColor.destructive
        }
    }

    private var background: Color {
        if state == .selected {
            return foreground.opacity(0.18)
        }
        return tone == .neutral ? AISkinColor.surfaceMuted : foreground.opacity(0.10)
    }
}

enum AISkinHeaderLayout {
    case centered
    case leadingTitleSubtitle
}

struct AISkinHeader<Leading: View, Title: View, Trailing: View>: View {
    private let layout: AISkinHeaderLayout
    private let leading: Leading
    private let title: Title
    private let trailing: Trailing

    init(
        layout: AISkinHeaderLayout = .centered,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder title: () -> Title,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.layout = layout
        self.leading = leading()
        self.title = title()
        self.trailing = trailing()
    }

    var body: some View {
        Group {
          if layout == .leadingTitleSubtitle {
            HStack(spacing: AISkinSpacing.xSmall) {
                leading.frame(width: AISkinLayout.leadingHeaderControlWidth, height: AISkinLayout.minimumTapHeight)
                title.frame(maxWidth: .infinity, alignment: .leading)
                trailing.frame(width: AISkinLayout.minimumTapHeight, height: AISkinLayout.minimumTapHeight)
            }
          } else {
           ZStack {
            title
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AISkinLayout.headerTitleSideInset)

            HStack {
                leading.frame(width: AISkinLayout.minimumTapHeight, height: AISkinLayout.minimumTapHeight)
                Spacer()
                trailing.frame(width: AISkinLayout.minimumTapHeight, height: AISkinLayout.minimumTapHeight)
            }
           }
          }
        }
        .frame(minHeight: AISkinLayout.headerHeight)
        .padding(.horizontal, AISkinSpacing.screenEdge)
        .background(Color.clear)
    }
}

struct AISkinListRow<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: AISkinLayout.listRowMinimumHeight, alignment: .leading)
            .padding(.vertical, AISkinSpacing.xSmall)
    }
}

/// Full-width period/filter selection with a consistent, accessible tap height.
struct AISkinSegmentedControl<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let title: (Item) -> String
    let systemImage: (Item) -> String

    var body: some View {
        HStack(spacing: AISkinSpacing.xxSmall) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Label(title(item), systemImage: systemImage(item))
                        .font(AISkinTypography.segmentedLabel)
                        .foregroundStyle(selection == item ? AISkinColor.textPrimary : AISkinColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: AISkinLayout.minimumTapHeight)
                        .padding(.vertical, AISkinSpacing.xxxSmall)
                        .background(selection == item ? AISkinColor.surfaceElevated : .clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(AISkinPressableStyle())
                .accessibilityAddTraits(selection == item ? .isSelected : [])
            }
        }
        .padding(AISkinSpacing.xxxSmall)
        .background(AISkinColor.surfaceSelected, in: Capsule())
    }
}

enum AISkinUnderlineTabSize {
    case compact, regular

    var font: Font {
        self == .regular ? AISkinTypography.categoryTab : AISkinTypography.reportTab
    }

    var selectedFont: Font {
        self == .regular ? AISkinTypography.categoryTabSelected : AISkinTypography.reportTabSelected
    }

    var minimumHeight: CGFloat {
        self == .regular ? AISkinLayout.regularUnderlineTabHeight : AISkinLayout.minimumTapHeight
    }

    var indicatorSpacing: CGFloat {
        self == .regular ? AISkinSpacing.xSmall : AISkinSpacing.xxSmall
    }
}

struct AISkinUnderlineTabs<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let title: (Item) -> String
    var size: AISkinUnderlineTabSize = .compact
    var onSelect: ((Item) -> Void)?
    var itemAccessibilityIdentifier: ((Item) -> String)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                    onSelect?(item)
                } label: {
                    VStack(spacing: size.indicatorSpacing) {
                        Text(title(item))
                            .font(selection == item ? size.selectedFont : size.font)
                            .foregroundStyle(selection == item ? AISkinColor.textPrimary : AISkinColor.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Capsule()
                            .fill(AISkinColor.accent.opacity(selection == item ? 1 : 0))
                            .frame(width: AISkinLayout.tabIndicatorWidth, height: AISkinLayout.tabIndicatorHeight)
                    }
                    .frame(maxWidth: .infinity, minHeight: size.minimumHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(AISkinPressableStyle())
                .accessibilityAddTraits(selection == item ? .isSelected : [])
                .accessibilityIdentifier(itemAccessibilityIdentifier?(item) ?? "report.tab.\(title(item))")
            }
        }
    }
}

struct AISkinUploadTile: View {
    let title: String
    let subtitle: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AISkinSpacing.xSmall) {
                if isLoading {
                    ProgressView().tint(AISkinColor.accent)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(AISkinTypography.iconUpload)
                        .foregroundStyle(AISkinColor.accent)
                }
                Text(title)
                    .font(AISkinTypography.bodyEmphasized)
                    .foregroundStyle(AISkinColor.textPrimary)
                Text(subtitle)
                    .font(AISkinTypography.caption)
                    .foregroundStyle(AISkinColor.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: AISkinLayout.uploadTileMinimumHeight)
            .background(AISkinColor.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AISkinRadius.control, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AISkinRadius.control, style: .continuous)
                    .stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline)
            }
        }
        .buttonStyle(AISkinPressableStyle())
        .disabled(isLoading)
    }
}
