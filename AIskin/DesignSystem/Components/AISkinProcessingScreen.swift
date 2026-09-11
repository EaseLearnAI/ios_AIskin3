import SwiftUI

/// One complete waiting page for every operation: background, header, centered
/// panel, cancellation and failure. Feature views supply only copy and actions.
struct AISkinProcessingScreen: View {
    let title: String
    let message: String
    var detail: String = "稍等一下，细节也想照顾到"
    var error: String? = nil
    var onRetry: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    var body: some View {
        AISkinScreenBackground {
            AISkinReportScreen {
                AISkinHeader {
                    if let onCancel {
                        AISkinIconButton(systemName: "xmark", accessibilityLabel: "取消", variant: .navigation, action: onCancel)
                            .accessibilityIdentifier("analysis.processing.cancel")
                    } else {
                        Color.clear.accessibilityHidden(true)
                    }
                } title: {
                    Text(title)
                        .font(AISkinTypography.screenTitle)
                        .foregroundStyle(AISkinColor.textPrimary)
                } trailing: {
                    Color.clear.accessibilityHidden(true)
                }
            } content: {
                Group {
                    if let error {
                        AISkinCard {
                            AISkinStateView(content: .error(title: "处理失败", message: error),
                                            actionTitle: onRetry == nil ? nil : "重新分析", action: onRetry)
                        }
                        .accessibilityIdentifier("analysis.processing.error")
                    } else {
                        AISkinProcessingPanel(title: message, message: detail)
                    }
                }
                .padding(.horizontal, AISkinSpacing.screenEdge)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("analysis.processing.screen")
    }
}
