import SwiftUI

enum AISkinSheetContentLayout { case scrolling, embeddedScroll }

/// Shared compact sheet chrome. The surface continues behind the footer and
/// home indicator; page backgrounds must not be repeated inside this panel.
struct AISkinBottomSheet<Content: View, Footer: View>: View {
    let title: String
    var detail: String? = nil
    var closeLabel = "关闭"
    var isBusy = false
    var contentLayout: AISkinSheetContentLayout = .scrolling
    let onClose: () -> Void
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        VStack(spacing: AISkinSpacing.small) {
            HStack(spacing: AISkinSpacing.xSmall) {
                AISkinSectionHeading(title: title, detail: detail)
                AISkinIconButton(systemName: "xmark", accessibilityLabel: closeLabel, variant: .plain, action: onClose)
                    .disabled(isBusy)
            }
            .padding(.horizontal, AISkinSpacing.screenEdge)
            .padding(.top, AISkinSpacing.medium)

            Group {
                if contentLayout == .scrolling {
                    ScrollView(showsIndicators: false) {
                        content
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AISkinSpacing.screenEdge)
                    }
                } else {
                    content
                }
            }
            .disabled(isBusy)

            footer
                .padding(.horizontal, AISkinSpacing.screenEdge)
                .padding(.bottom, AISkinSpacing.small)
        }
        .background(AISkinColor.sheetSurface.ignoresSafeArea())
        .tint(AISkinColor.accent)
        .presentationBackground(AISkinColor.sheetSurface)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(AISkinRadius.xLarge)
        .presentationContentInteraction(.scrolls)
        .interactiveDismissDisabled(isBusy)
    }
}

struct AISkinCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: AISkinSpacing.xSmall) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(AISkinTypography.iconControl)
                configuration.label
                    .font(AISkinTypography.callout)
            }
            .foregroundStyle(configuration.isOn ? AISkinColor.accent : AISkinColor.textSecondary)
            .frame(minHeight: AISkinLayout.minimumTapHeight)
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityValue(configuration.isOn ? "已选中" : "未选中")
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}
