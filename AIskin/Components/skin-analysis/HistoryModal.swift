import SwiftUI

/// Shared native sheet for overview and independent reports.
struct SkinHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: SkinAnalysisStore
    var onSelect: ((AnalysisResult) -> Void)? = nil

    var body: some View {
        AISkinBottomSheet(title: "检测历史", closeLabel: "关闭检测历史", contentLayout: .embeddedScroll, onClose: { dismiss() }) {
            SkinHistoryList(store: store) { result in
                if let onSelect { onSelect(result) }
                else { store.selectHistory(result) }
                dismiss()
            }
        } footer: { EmptyView() }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// The same history rows and loading states serve report sheets and the profile page.
struct SkinHistoryList: View {
    @ObservedObject var store: SkinAnalysisStore
    var scope: SkinHistoryRow.Scope = .history
    let onSelect: (AnalysisResult) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AISkinSpacing.small) {
                if store.isLoadingHistory && store.history.isEmpty {
                    AISkinStateView(content: .loading(message: "加载检测历史…"))
                } else if store.history.isEmpty && store.historyError == nil {
                    AISkinStateView(content: .empty(title: "暂无检测历史", message: "完成首次肌肤检测后，历史结果会显示在这里。", systemImage: "clock.arrow.circlepath"))
                }
                ForEach(Array(store.history.enumerated()), id: \.offset) { _, result in
                    AISkinCard(inset: .none) {
                        SkinHistoryRow(history: result, scope: scope) { onSelect(result) }
                            .padding(.horizontal, AISkinSpacing.medium)
                    }
                }
                if let error = store.historyError {
                    AISkinStateView(content: .error(title: "加载检测历史失败", message: error), actionTitle: "重试", action: { Task { await store.retryHistory() } })
                }
                if store.hasMoreHistory {
                    AISkinButton(variant: .secondary, isLoading: store.isLoadingHistory, action: { Task { await store.loadMoreHistory() } }) { Text("加载更早的记录") }
                }
            }
            .padding(AISkinSpacing.screenEdge)
        }
        .refreshable { await store.loadHistory() }
    }
}

struct SkinHistoryRow: View {
    enum Scope {
        case overview, history, profile

        var accessibilityPrefix: String {
            switch self {
            case .overview: "skin.overview.history"
            case .history: "skin.history.report"
            case .profile: "profile.skin-report"
            }
        }
    }

    let history: AnalysisResult
    var scope: Scope = .history
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AISkinSpacing.small) {
                Text(history.healthScore.map { String($0) } ?? "—")
                    .font(AISkinSkinReportTokens.comparisonScore)
                    .foregroundStyle(AISkinColor.accent)
                    .frame(minWidth: AISkinLayout.minimumTapHeight, alignment: .leading)
                VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                    Text(history.context?.reportStatus ?? "未记录状态")
                        .font(AISkinSkinReportTokens.label).foregroundStyle(AISkinColor.textPrimary)
                    Text(history.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "日期未记录")
                        .font(AISkinSkinReportTokens.footnote).foregroundStyle(AISkinColor.textSecondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(AISkinTypography.iconChevron).foregroundStyle(AISkinColor.textSecondary)
            }
            .padding(.vertical, AISkinSpacing.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityIdentifier("\(scope.accessibilityPrefix).\(history.sourceID ?? "unknown")")
    }
}
