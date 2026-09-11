import SwiftUI

enum AISkinReportTextStyle {
    case standard, reading
}

struct AISkinReportHeading: View {
    let number: String
    let title: String
    var detail: String? = nil
    var systemImage: String? = nil
    var style: AISkinReportTextStyle = .standard

    var body: some View {
        HStack(spacing: AISkinSpacing.xSmall) {
            Text(number).font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary)
            Text(title).font(style == .reading ? AISkinReportTokens.readingHeading : AISkinReportTokens.heading).foregroundStyle(AISkinColor.textPrimary)
            Spacer(minLength: AISkinSpacing.small)
            if let detail { Text(detail).font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.textSecondary) }
            if let systemImage { Image(systemName: systemImage).font(AISkinTypography.iconButton).foregroundStyle(AISkinColor.accent) }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Fits short content and keeps long or expanded content scrolling inside the card.
struct AISkinReportScrollCard<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var contentHeight: CGFloat = AISkinReportTokens.scrollCardMaxHeight

    private var viewportHeight: CGFloat {
        min(contentHeight, AISkinReportTokens.scrollCardMaxHeight)
    }

    var body: some View {
        AISkinCard(inset: .none) {
            ScrollView(.vertical) {
                content
                    .padding(.horizontal, AISkinReportTokens.ingredientListInset)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { geometry in
                        geometry.size.height
                    } action: { height in
                        contentHeight = height
                    }
            }
            .frame(height: viewportHeight)
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicatorsFlash(trigger: contentHeight)
        }
    }
}

struct AISkinReportDisclosureRow: View {
    let number: String
    let title: String
    let subtitle: String
    let detail: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(AISkinMotion.standard) { isExpanded.toggle() }
            } label: {
                HStack(spacing: AISkinSpacing.small) {
                    Text(number).font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary)
                    VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                        Text(title).font(AISkinReportTokens.itemTitle).foregroundStyle(AISkinColor.textPrimary)
                        Text(subtitle).font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary)
                    }
                    Spacer(minLength: AISkinSpacing.small)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(AISkinTypography.iconCaption).foregroundStyle(AISkinColor.accent)
                }
                .frame(maxWidth: .infinity, minHeight: AISkinReportTokens.ingredientRowHeight, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "已展开" : "已收起")
            if isExpanded {
                AISkinReportTextItem(text: detail)
                    .padding(.bottom, AISkinSpacing.small)
            }
        }
    }
}

struct AISkinReportScore: View {
    enum Layout { case scoreFirst, summaryFirst }

    let label: String
    let score: Double?
    var status: String? = nil
    var hint: String? = nil
    var title: String? = nil
    let summary: String
    var layout: Layout = .scoreFirst

    var body: some View {
        AISkinCard {
          if layout == .summaryFirst {
            VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                HStack {
                    Text(title ?? "产品总结").font(AISkinReportTokens.readingHeading)
                    Spacer()
                    Image(systemName: "sparkles").foregroundStyle(AISkinColor.accent)
                }
                .foregroundStyle(AISkinColor.textPrimary)
                AISkinExpandableReportText(text: summary, role: .summary)
                AISkinDivider()
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(label).font(AISkinReportTokens.readingCaption).foregroundStyle(AISkinColor.textSecondary)
                        Spacer(minLength: AISkinSpacing.small)
                        compactScore
                    }
                    VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                        Text(label).font(AISkinReportTokens.readingCaption).foregroundStyle(AISkinColor.textSecondary)
                        compactScore
                    }
                }
            }
          } else {
            VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                HStack {
                    Text(label).font(AISkinReportTokens.body).foregroundStyle(AISkinColor.textPrimary)
                    Spacer()
                    if let status {
                        Text(status).font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.accent)
                    } else {
                        Image(systemName: "sparkles").font(AISkinTypography.iconControl).foregroundStyle(AISkinColor.accent)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: AISkinSpacing.xSmall) {
                    Text(score.map { String(format: "%.1f", $0) } ?? "—")
                        .font(AISkinReportTokens.score).tracking(AISkinReportTokens.scoreTracking)
                        .foregroundStyle(AISkinColor.textPrimary)
                    Text("/ 5.0").font(AISkinReportTokens.conflictBody).foregroundStyle(AISkinColor.textSecondary)
                    Spacer()
                    if let score {
                        HStack(spacing: AISkinSpacing.xxSmall) {
                            ForEach(0..<5) { index in
                                Circle().fill(index < Int(score.rounded(.down)) ? AISkinColor.accent : AISkinColor.divider)
                                    .frame(width: AISkinReportTokens.dotDiameter, height: AISkinReportTokens.dotDiameter)
                            }
                        }.accessibilityHidden(true)
                    }
                }
                .padding(.vertical, AISkinSpacing.xxSmall)
                if let hint { Text(hint).font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary) }
                if let title, !title.isEmpty { Text(title).font(AISkinReportTokens.heading).foregroundStyle(AISkinColor.textPrimary) }
                if !summary.isEmpty {
                    Text(summary).font(AISkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
                        .lineSpacing(AISkinReportTokens.bodyLineSpacing).fixedSize(horizontal: false, vertical: true)
                }
            }
          }
        }
    }

    private var compactScore: some View {
        HStack(alignment: .firstTextBaseline, spacing: AISkinSpacing.xxSmall) {
            Text(score.map { String(format: "%.1f", $0) } ?? "—")
                .font(AISkinReportTokens.readingScore).foregroundStyle(AISkinColor.textPrimary)
            Text("/ 5.0").font(AISkinReportTokens.readingCaption).foregroundStyle(AISkinColor.textSecondary)
        }.fixedSize()
    }
}

struct AISkinReportAnchorBar<Item: Hashable>: View {
    let items: [Item]
    let title: (Item) -> String
    let onSelect: (Item) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                Button { onSelect(item) } label: {
                    Text(title(item)).font(AISkinReportTokens.body).foregroundStyle(AISkinColor.accent)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: AISkinReportTokens.anchorHeight)
                }.buttonStyle(AISkinPressableStyle())
            }
        }
        .padding(AISkinReportTokens.anchorInset)
        .background { AISkinColor.surfaceElevated.background(.regularMaterial) }
        .clipShape(RoundedRectangle(cornerRadius: AISkinReportTokens.anchorRadius))
        .overlay { RoundedRectangle(cornerRadius: AISkinReportTokens.anchorRadius).stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline) }
    }
}

extension View {
    /// Pins only the rendered directory; scroll geometry never feeds back into layout or state.
    func aiSkinStickyReportDirectory(in coordinateSpace: String) -> some View {
        visualEffect { content, geometry in
            content.offset(y: max(0, -geometry.frame(in: .named(coordinateSpace)).minY))
        }
        .zIndex(1)
    }

    /// Measure the actual heading; ScrollViewReader aligns this small target below the directory.
    func aiSkinReportScrollTarget<ID: Hashable>(_ id: ID) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(key: AISkinReportScrollTargetHeights<ID>.self, value: [id: geometry.size.height])
            }
        }
            .id(id)
    }
}

struct AISkinReportScrollTargetHeights<ID: Hashable>: PreferenceKey {
    static var defaultValue: [ID: CGFloat] { [:] }
    static func reduce(value: inout [ID: CGFloat], nextValue: () -> [ID: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

struct AISkinReportTextItem: View {
    var title: String? = nil
    let text: String
    var number: String? = nil
    var style: AISkinReportTextStyle = .standard

    var body: some View {
        HStack(alignment: .top, spacing: AISkinSpacing.small) {
            if let number { Text(number).font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.accent).padding(.top, AISkinSpacing.xxxSmall) }
            VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                if let title, !title.isEmpty {
                    Text(title).font(style == .reading ? AISkinReportTokens.readingTitle : AISkinReportTokens.itemTitle)
                        .foregroundStyle(AISkinColor.textPrimary)
                }
                if style == .reading {
                    AISkinExpandableReportText(text: text)
                } else {
                    Text(text).font(AISkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
                        .lineSpacing(AISkinReportTokens.bodyLineSpacing).fixedSize(horizontal: false, vertical: true)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Short model copy reads in full. Older, lengthy paragraphs keep an explicit way
/// to read the original; presentation never removes a warning or rewrites a claim.
struct AISkinExpandableReportText: View {
    enum Role { case body, summary }
    let text: String
    var role: Role = .body
    @State private var expanded = false

    private var needsDisclosure: Bool {
        text.count > (role == .summary ? AISkinReportTokens.readingSummaryDisclosureThreshold : AISkinReportTokens.readingDisclosureThreshold)
            || text.contains("\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
            Text(text)
                .font(role == .summary ? AISkinReportTokens.readingSummary : AISkinReportTokens.readingBody)
                .foregroundStyle(role == .summary ? AISkinColor.textPrimary : AISkinColor.textSecondary)
                .lineSpacing(AISkinReportTokens.readingLineSpacing)
                .lineLimit(needsDisclosure && !expanded ? (role == .summary ? AISkinReportTokens.readingSummaryLineLimit : AISkinReportTokens.readingBodyLineLimit) : nil)
                .fixedSize(horizontal: false, vertical: true)
            if needsDisclosure {
                Button {
                    withAnimation(AISkinMotion.standard) { expanded.toggle() }
                } label: {
                    HStack(spacing: AISkinSpacing.xxSmall) {
                        Text(expanded ? "收起" : "展开全文")
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    }
                    .font(AISkinReportTokens.readingCaption)
                    .foregroundStyle(AISkinColor.accent)
                    .frame(minHeight: AISkinLayout.minimumTapHeight, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(AISkinPressableStyle())
                .accessibilityLabel(expanded ? "收起完整说明" : "展开完整说明")
                .accessibilityValue(expanded ? "已展开" : "已收起")
            }
        }
        .onChange(of: text) { _, _ in expanded = false }
    }
}

/// A compact inset within a report, for product grids or a component comparison.
struct AISkinReportInsetCell<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(AISkinSpacing.small)
            .frame(maxWidth: .infinity, minHeight: AISkinReportTokens.cellHeight, alignment: .leading)
            .background(AISkinColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AISkinReportTokens.cellRadius))
            .overlay { RoundedRectangle(cornerRadius: AISkinReportTokens.cellRadius).stroke(AISkinColor.divider, lineWidth: AISkinLayout.hairline) }
    }
}


/// Pins actions below the clipped report viewport and covers the home-indicator area.
struct AISkinReportFooter<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(.horizontal, AISkinSpacing.screenEdge)
            .padding(.vertical, AISkinSpacing.xSmall)
            .frame(maxWidth: .infinity)
            .background {
                Rectangle().fill(.bar).ignoresSafeArea(edges: .bottom)
            }
    }
}
