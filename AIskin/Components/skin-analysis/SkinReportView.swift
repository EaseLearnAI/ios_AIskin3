import SwiftUI

struct SkinReportView: View {
    @ObservedObject var store: SkinAnalysisStore
    let onBack: () -> Void
    let onRetake: () -> Void
    var onCreatePlan: (() -> Void)? = nil
    @State private var section: SkinReportSection = .issues
    @State private var showContext = false
    @State private var showScoreInfo = false
    @State private var showPhoto = false
    @State private var photoReloadID = UUID()
    @State private var isAtEnd = false
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        AISkinReportScreen {
            AISkinHeader {
                AISkinIconButton(systemName: "chevron.left", accessibilityLabel: "返回", variant: .navigation, action: onBack)
                    .accessibilityIdentifier("skin.report.overview")
            } title: {
                Text("肌肤报告").font(AISkinTypography.screenTitle).foregroundStyle(AISkinColor.textPrimary)
            } trailing: {
                AISkinIconButton(systemName: "clock.arrow.circlepath", accessibilityLabel: "检测历史", variant: .surface, action: { store.isHistoryPresented = true })
                    .accessibilityIdentifier("skin.report.history")
            }
        } content: {
            if let result = store.result {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        AISkinUnderlineTabs(items: SkinReportSection.allCases, selection: $section, title: \.title) { selected in
                            withAnimation(AISkinMotion.emphasized) { proxy.scrollTo(selected, anchor: .top) }
                        }
                        .padding(.horizontal, AISkinSpacing.medium)
                        ScrollView {
                            VStack(spacing: AISkinSkinReportTokens.chapterGap) {
                                issues(result).id(SkinReportSection.issues)
                                overview(result).id(SkinReportSection.overview)
                                advice(result).id(SkinReportSection.actions)
                                comparison(result).aiSkinGeneratedResult().id(SkinReportSection.comparison)
                                Color.clear.frame(height: 0)
                                    .background { GeometryReader { geometry in
                                        Color.clear.preference(key: SkinReportBottomKey.self, value: geometry.frame(in: .named("skin-report-scroll")).minY)
                                    } }
                            }
                            .padding(.horizontal, AISkinSpacing.screenEdge)
                            .padding(.top, AISkinSpacing.small)
                            .padding(.bottom, AISkinSpacing.xLarge)
                        }
                        .coordinateSpace(name: "skin-report-scroll")
                        .accessibilityIdentifier("skin.report.content")
                        .background { GeometryReader { geometry in
                            Color.clear.preference(key: SkinReportViewportKey.self, value: geometry.size.height)
                        } }
                        .onPreferenceChange(SkinReportViewportKey.self) { viewportHeight = $0 }
                        .onPreferenceChange(SkinReportBottomKey.self) { bottom in
                            isAtEnd = bottom > 0 && viewportHeight > 0 && bottom <= viewportHeight + AISkinSpacing.xSmall
                            if isAtEnd { section = .comparison }
                        }
                        .onPreferenceChange(SkinSectionPositionKey.self) { positions in
                            guard !isAtEnd else { return }
                            let ordered = SkinReportSection.allCases.compactMap { id in positions[id].map { (id, $0) } }
                            if let visible = ordered.last(where: { $0.1 <= AISkinSpacing.large }) ?? ordered.first {
                                section = visible.0
                            }
                        }
                    }
                    .onChange(of: result.sourceID) { _, _ in
                        section = .issues
                        proxy.scrollTo(SkinReportSection.issues, anchor: .top)
                    }
                }
            }
        } footer: {
            AISkinSkinReportFooter(onRetake: onRetake, onCreatePlan: onCreatePlan)
        }
        .sheet(isPresented: $store.isHistoryPresented) {
            SkinHistorySheet(store: store)
        }
        .sheet(isPresented: $showContext) {
            if let result = store.result, let id = result.sourceID {
                SkinContextForm(analysisID: id, context: result.context, store: store)
            }
        }
        .sheet(isPresented: $showScoreInfo) {
            AISkinBottomSheet(title: "这项评分如何理解？", closeLabel: "关闭评分说明", onClose: { showScoreInfo = false }) {
                AISkinReportTextItem(text: "综合评分来自本次分析结果。它用于记录和比较，不能替代专业判断；请同时关注具体观察、拍摄条件和实际肤感。")
            } footer: { EmptyView() }
            .presentationDetents([.height(AISkinReportTokens.actionSheetHeight), .large])
        }
        .sheet(isPresented: $showPhoto) {
            NavigationStack {
                AISkinScreenBackground {
                    if let result = store.result { reportPhoto(result, fills: false) }
                }
                .navigationTitle("本次检测照片").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showPhoto = false } } }
            }
        }
    }

    private func overview(_ result: AnalysisResult) -> some View {
        VStack(spacing: AISkinSpacing.small) {
            chapter(.overview) { EmptyView() }
            AISkinSkinSummaryCard(score: result.healthScore, skinType: result.skinType?.type ?? "未记录肤质", condition: result.context?.reportStatus ?? "未记录状态", metrics: result.reportMetrics, conclusion: result.summary ?? "该次记录暂无结论", onScoreInfo: { showScoreInfo = true })
            if let date = result.createdAt {
                Label(date.formatted(date: .abbreviated, time: .shortened), systemImage: "info.circle")
                    .font(AISkinSkinReportTokens.footnote).foregroundStyle(AISkinColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }.reportSectionPosition(.overview)
    }

    private func issues(_ result: AnalysisResult) -> some View {
        VStack(spacing: AISkinSpacing.small) {
            chapter(.issues) {
                AISkinSkinReportLink(title: "查看本次照片", systemImage: "photo") { showPhoto = true }
            }
            AISkinSkinReportPhotoMap(observations: result.reportObservations, assessments: result.reportAssessmentObservations) {
                reportPhoto(result)
            }
            .id(result.sourceID)
        }.reportSectionPosition(.issues)
    }

    @ViewBuilder
    private func reportPhoto(_ result: AnalysisResult, fills: Bool = true) -> some View {
        if let url = result.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: fills ? .fill : .fit)
                        .accessibilityHidden(false)
                        .accessibilityAddTraits(.isImage)
                        .accessibilityLabel("本次检测照片")
                        .accessibilityIdentifier("skin.report.photo")
                case .failure:
                    Button { photoReloadID = UUID() } label: {
                        Label("照片加载失败，重试", systemImage: "arrow.clockwise")
                            .font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.accent)
                    }.buttonStyle(AISkinPressableStyle())
                default: ProgressView().tint(AISkinColor.accent)
                }
            }.id(photoReloadID)
        } else {
            VStack(spacing: AISkinSpacing.xSmall) {
                Image(systemName: "person.crop.rectangle.badge.questionmark").font(AISkinTypography.iconLarge)
                Text("未保存检测照片").font(AISkinSkinReportTokens.small)
            }
            .foregroundStyle(AISkinColor.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AISkinColor.surfaceMuted)
        }
    }

    private func advice(_ result: AnalysisResult) -> some View {
        VStack(spacing: AISkinSpacing.small) {
            chapter(.actions) { Image(systemName: "note.text").foregroundStyle(AISkinColor.accent) }
            AIRecommendations(recommendations: result.recommendations ?? [])
        }.reportSectionPosition(.actions)
    }

    private func comparison(_ result: AnalysisResult) -> some View {
        let previous = previousResult(result)
        return VStack(spacing: AISkinSpacing.small) {
            chapter(.comparison) {
                AISkinSkinReportLink(title: "历史记录") { store.isHistoryPresented = true }
            }
            AISkinSkinReportComparison(previousDate: previous?.createdAt?.formatted(date: .numeric, time: .omitted), previousScore: previous?.healthScore, currentDate: result.createdAt?.formatted(date: .numeric, time: .omitted), currentScore: result.healthScore, hasPrevious: previous != nil)
            DisclosureGroup {
                VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                    Text((result.context ?? SkinAnalysisContext()).reportDetailText)
                        .font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.textSecondary)
                        .lineSpacing(AISkinSpacing.xxSmall)
                    AISkinSkinReportLink(title: "修改记录状态", systemImage: "square.and.pencil") { showContext = true }
                        .accessibilityIdentifier("skin.context.open")
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, AISkinSpacing.small)
            } label: {
                Text("本次记录信息").font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.textSecondary)
            }
            .tint(AISkinColor.textSecondary)
            AISkinDivider()
        }.reportSectionPosition(.comparison)
    }

    private func previousResult(_ result: AnalysisResult) -> AnalysisResult? {
        guard let index = store.history.firstIndex(where: { $0.sourceID == result.sourceID }), store.history.indices.contains(index + 1) else { return nil }
        return store.history[index + 1]
    }

    private func chapter<Content: View>(_ section: SkinReportSection, @ViewBuilder accessory: @escaping () -> Content) -> some View {
        HStack(spacing: AISkinSpacing.xSmall) {
            AISkinReportHeading(number: section.number, title: section.title)
            accessory()
        }.frame(minHeight: AISkinSpacing.xxLarge)
    }
}

enum SkinReportSection: String, CaseIterable, Hashable {
    case issues, overview, actions, comparison
    var title: String {
        switch self {
        case .overview: "肤况概览"
        case .issues: "肌肤问题"
        case .actions: "护肤建议"
        case .comparison: "前后对比"
        }
    }
    var number: String { String(format: "%02d", (Self.allCases.firstIndex(of: self) ?? 0) + 1) }
}

private struct SkinSectionPositionKey: PreferenceKey {
    static let defaultValue: [SkinReportSection: CGFloat] = [:]
    static func reduce(value: inout [SkinReportSection: CGFloat], nextValue: () -> [SkinReportSection: CGFloat]) { value.merge(nextValue(), uniquingKeysWith: { _, new in new }) }
}

private extension View {
    func reportSectionPosition(_ section: SkinReportSection) -> some View {
        background { GeometryReader { geometry in Color.clear.preference(key: SkinSectionPositionKey.self, value: [section: geometry.frame(in: .named("skin-report-scroll")).minY]) } }
    }
}

private struct SkinReportViewportKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct SkinReportBottomKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
