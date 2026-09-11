import SwiftUI

struct ConflictView: View {
    @Environment(\.dismiss) private var dismiss
    let productIds: [String]?
    @StateObject private var store = ConflictAnalysisStore()
    @State private var retryTask: Task<Void, Never>?

    init(productIds: [String]? = nil) { self.productIds = productIds }

    var body: some View {
        ZStack {
            if isLoading {
                AISkinProcessingScreen(title: "冲突检测", message: "正在分析产品搭配", onCancel: { dismiss() })
            } else {
                reportBody
            }
        }

        .task(id: productIds ?? []) { await store.analyze(productIDs: productIds ?? []) }
        .onDisappear(perform: cancelRetry)
    }

    private var isLoading: Bool {
        switch store.state {
        case .idle, .loading: true
        default: false
        }
    }

    private var reportBody: some View {
        AISkinReportScreen {
            AppHeader(title: "冲突检测报告", subtitle: reportSubtitle, layout: .leadingTitleSubtitle, backAction: {
                cancelRetry()
                dismiss()
            })
        } content: {
          Group {
            switch store.state {
            case .idle, .loading:
                EmptyView()
            case .failed(let error):
                AISkinStateView(content: .error(title: "冲突分析失败", message: error), actionTitle: "重试", action: analyze)
                    .frame(maxHeight: .infinity)
            case .loaded(let data):
                ConflictReportContent(data: data)
            }
          }
          .padding(.top, AISkinSpacing.medium)
        }
    }

    private func analyze() {
        guard retryTask == nil else { return }
        retryTask = Task {
            defer { retryTask = nil }
            await store.analyze(productIDs: productIds ?? [])
        }
    }
    private func cancelRetry() { retryTask?.cancel() }
    private var reportSubtitle: String? {
        guard case .loaded(let data) = store.state else { return nil }
        return "\(data.products?.count ?? 0) 件产品 · 分析完成"
    }
}

struct ConflictReportContent: View {
    let data: ConflictAnalysisData
    @State private var reanalyze = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AISkinReportTokens.sectionGap) {
                ConflictOverviewSection(data: data)
                TestedProductsSection(products: data.products ?? [])
                if data.hasProductReport {
                    ConflictsDetailSection(data: data)
                    RecommendationsDetailSection(data: data)
                } else if let products = data.products, products.compactMap(\.id).count >= 2 {
                    AISkinButton(action: { reanalyze = true }) {
                        Text("重新检测这些产品")
                    }
                    .navigationDestination(isPresented: $reanalyze) {
                        ConflictView(productIds: products.compactMap(\.id))
                    }
                }
                AISkinAIGeneratedNotice()
            }
            .padding(.horizontal, AISkinSpacing.screenEdge)
            .padding(.bottom, AISkinSpacing.xxLarge)
        }
    }
}

struct ConflictHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = ConflictHistoryStore()
    @State private var showsSelection = false

    var body: some View {
        VStack(spacing: AISkinSpacing.medium) {
            AppHeader(title: "冲突检测历史", backAction: { dismiss() })
            ScrollView {
                VStack(spacing: AISkinSpacing.medium) {
                    switch store.state {
                    case .idle, .loading:
                        AISkinStateView(content: .loading(message: "加载检测记录…"))
                    case .failed(let message):
                        AISkinStateView(content: .error(title: "记录加载失败", message: message), actionTitle: "重试", action: { Task { await store.load() } })
                    case .loaded(let records):
                        if records.isEmpty {
                            AISkinStateView(content: .empty(title: "还没有冲突检测报告", message: "选择至少 2 件护肤品完成检测，报告会保存在这里。", systemImage: "square.3.layers.3d"))
                        }
                        if !records.isEmpty {
                            AISkinSectionHeading(title: "历史报告", detail: "共 \(records.count) 份")
                        }
                        ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                            NavigationLink {
                                ConflictHistoryDetailView(record: record)
                            } label: {
                                ConflictHistoryRecordCard(record: record)
                            }
                            .buttonStyle(AISkinPressableStyle())
                            .accessibilityIdentifier("profile.conflict-report.\(record.id ?? "unknown")")
                        }
                    }
                }
                .padding(.horizontal, AISkinSpacing.screenEdge)
            }
            .refreshable { await store.load() }
            AISkinButton(action: { showsSelection = true }) {
                Label("开始新的检测", systemImage: "plus")
            }
            .padding(.horizontal, AISkinSpacing.screenEdge)
        }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
        .task { await store.load() }
        .navigationDestination(isPresented: $showsSelection) { ConflictSelectionView() }
    }
}

private struct ConflictHistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: ConflictRecord

    var body: some View {
        AISkinReportScreen {
            AppHeader(title: "冲突检测报告", subtitle: "\(record.products?.count ?? 0) 件产品 · 分析完成", layout: .leadingTitleSubtitle, backAction: { dismiss() })
        } content: {
            ConflictReportContent(data: record.reportData)
                .padding(.top, AISkinSpacing.medium)
        }
    }
}

struct ConflictSelectionView: View {
    var initialProductID: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AISkinScreenBackground {
            VStack(spacing: AISkinSpacing.medium) {
                AppHeader(title: "选择检测产品", backAction: { dismiss() })
                ProductView(initialEntry: .conflictSelection(productID: initialProductID))
            }
        }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
    }
}
