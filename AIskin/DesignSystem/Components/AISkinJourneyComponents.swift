import SwiftUI

/// Shared circular progress and translucent surface, using the app's existing palette.
struct AISkinProgressSummary: View {
    let completed: Int
    let total: Int
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: AISkinSpacing.medium) {
            ZStack {
                Circle().fill(AISkinColor.surface)
                Circle().stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline)
                Circle()
                    .stroke(AISkinColor.surfaceSelected, lineWidth: AISkinLayout.progressRingStroke)
                    .padding(AISkinLayout.progressRingInset)
                Circle()
                    .trim(from: 0, to: CGFloat(completed) / CGFloat(max(total, 1)))
                    .stroke(AISkinColor.accent, style: StrokeStyle(lineWidth: AISkinLayout.progressRingStroke, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(AISkinLayout.progressRingInset)
                VStack(spacing: AISkinSpacing.xxSmall) {
                    Text("创建进度").font(AISkinTypography.caption).foregroundStyle(AISkinColor.textSecondary)
                    Text("\(completed) / \(total)").font(AISkinTypography.heroMetric).foregroundStyle(AISkinColor.textPrimary)
                    Text("已完成").font(AISkinTypography.caption).foregroundStyle(AISkinColor.accent)
                }
            }
            .frame(width: AISkinLayout.progressRingDiameter, height: AISkinLayout.progressRingDiameter)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("创建进度，已完成 \(completed) 项，共 \(total) 项")

            VStack(spacing: AISkinSpacing.xSmall) {
                Text(title).font(AISkinTypography.screenTitle).foregroundStyle(AISkinColor.textPrimary)
                Text(message).font(AISkinTypography.callout).foregroundStyle(AISkinColor.textSecondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

enum AISkinStepState {
    case completed, current, upcoming
}

struct AISkinStepRow: View {
    let number: Int
    let title: String
    let message: String
    let state: AISkinStepState

    var body: some View {
        HStack(alignment: .center, spacing: AISkinSpacing.small) {
            ZStack {
                Circle().fill(state == .completed ? AISkinColor.accent : AISkinColor.surfaceSelected)
                if state == .completed {
                    Image(systemName: "checkmark").foregroundStyle(AISkinColor.textOnAccent)
                } else {
                    Text(String(format: "%02d", number)).foregroundStyle(state == .current ? AISkinColor.accent : AISkinColor.textSecondary)
                }
            }
            .font(AISkinTypography.iconSmall)
            .frame(width: AISkinLayout.stepIndicatorDiameter, height: AISkinLayout.stepIndicatorDiameter)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                Text(title).font(AISkinTypography.bodyEmphasized).foregroundStyle(AISkinColor.textPrimary)
                Text(message).font(AISkinTypography.caption).foregroundStyle(AISkinColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if state == .current {
                Text("当前步骤").font(AISkinTypography.caption).foregroundStyle(AISkinColor.accent)
            }
        }
        .padding(.vertical, AISkinSpacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityValue(state == .completed ? "已完成" : state == .current ? "当前步骤" : "待完成")
    }
}

struct AISkinSectionHeading: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(AISkinTypography.sectionTitle).foregroundStyle(AISkinColor.textPrimary)
            Spacer()
            if let detail {
                Text(detail).font(AISkinTypography.callout).foregroundStyle(AISkinColor.textSecondary)
                    .monospacedDigit()
            }
        }
    }
}

struct AISkinDivider: View {
    var body: some View {
        Rectangle().fill(AISkinColor.divider).frame(height: AISkinLayout.hairline)
            .accessibilityHidden(true)
    }
}

struct AISkinActionLink: View {
    enum Layout: Equatable {
        case row
        case compact
        case card(systemImage: String)
    }

    let title: String
    var layout: Layout = .row
    let action: () -> Void

    var body: some View {
        Button(action: action) {
          if case .card(let systemImage) = layout {
            AISkinCard(inset: .none, role: .action) {
                HStack(spacing: AISkinSpacing.small) {
                    Image(systemName: systemImage)
                        .font(AISkinTypography.iconControl)
                        .foregroundStyle(AISkinColor.accent)
                    Spacer(minLength: AISkinSpacing.small)
                    Text(title)
                        .font(AISkinTypography.callout)
                        .foregroundStyle(AISkinColor.textPrimary)
                }
                .padding(AISkinReportTokens.actionCardInset)
                .frame(maxWidth: .infinity, minHeight: AISkinLayout.minimumTapHeight)
            }
          } else {
            HStack(spacing: AISkinSpacing.xSmall) {
                Text(title)
                if layout == .row {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
            }
            .font(AISkinTypography.callout)
            .foregroundStyle(AISkinColor.accent)
            .frame(minWidth: AISkinLayout.minimumTapHeight, minHeight: AISkinLayout.minimumTapHeight)
            .contentShape(Rectangle())
          }
        }
        .buttonStyle(AISkinPressableStyle())
        .fixedSize(horizontal: layout == .compact, vertical: false)
    }
}

struct AISkinChecklistRow: View {
    let title: String
    let message: String?
    let number: Int
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AISkinSpacing.small) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(AISkinTypography.routineCheck)
                    .frame(width: AISkinLayout.routineCheckDiameter)
                    .foregroundStyle(isCompleted ? AISkinColor.accent : AISkinColor.textSecondary)
                VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                    Text(title)
                        .font(AISkinTypography.routineTitle)
                        .lineLimit(1)
                        .strikethrough(isCompleted)
                        .foregroundStyle(isCompleted ? AISkinColor.textSecondary : AISkinColor.textPrimary)
                    if let message, !message.isEmpty {
                        Text(message).font(AISkinTypography.routineSubtitle).foregroundStyle(AISkinColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: AISkinSpacing.xSmall)
                Text(String(format: "%02d", number))
                    .font(AISkinTypography.caption).foregroundStyle(AISkinColor.textSecondary)
            }
            .padding(.vertical, AISkinSpacing.routineRowPadding)
            .frame(minHeight: AISkinLayout.routineRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityValue(isCompleted ? "已完成" : "未完成")
        .accessibilityHint("点击切换完成状态")
    }
}
