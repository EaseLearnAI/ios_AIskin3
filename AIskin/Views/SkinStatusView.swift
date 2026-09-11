//
//  SkinStatusView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI
import PhotosUI

struct SkinStatusView: View {
    @ObservedObject var store: SkinAnalysisStore
    let onCreatePlan: (() -> Void)?
    private var showsPlanCallToAction: Bool { onCreatePlan != nil }
    
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    private let startsInCapture: Bool
    @State private var opensCameraAfterReport = false
    @State private var hasLoadedHistory = false
    @State private var pendingHistoryResult: AnalysisResult?
    @State private var opensPlanAfterReport = false
    @State private var photoLoadError: String?
    @Environment(\.dismiss) private var dismiss
    
    init(store: SkinAnalysisStore, onCreatePlan: (() -> Void)? = nil, startsInCapture: Bool = false) {
        self.store = store
        self.onCreatePlan = onCreatePlan
        self.startsInCapture = startsInCapture
    }
    
    var body: some View {
        contentView
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhoto,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            guard let image = capturedImage else { return }
            capturedImage = nil
            store.selectedImage = image
        }) {
            AISkinCameraCapture(image: $capturedImage)
        }
        .sheet(isPresented: Binding(get: { store.isHistoryPresented && store.result == nil }, set: { store.isHistoryPresented = $0 }), onDismiss: {
            if let result = pendingHistoryResult {
                pendingHistoryResult = nil
                store.selectHistory(result)
            }
        }) {
            SkinHistorySheet(store: store, onSelect: { pendingHistoryResult = $0 })
        }
        .fullScreenCover(isPresented: Binding(get: { isAnalyzing || (showsPlanCallToAction && store.result != nil) }, set: { if !$0 { store.reset() } }), onDismiss: {
            if opensCameraAfterReport {
                opensCameraAfterReport = false
                showCamera = true
            } else if opensPlanAfterReport {
                opensPlanAfterReport = false
                onCreatePlan?()
            }
        }) {
            NavigationStack {
                if isAnalyzing {
                    AISkinProcessingScreen(title: "肌肤检测", message: "正在分析肌肤照片", onCancel: { store.reset() })
                } else {
                    AISkinScreenBackground {
                        SkinReportView(store: store, onBack: { store.reset() }, onRetake: beginCapture, onCreatePlan: {
                            opensPlanAfterReport = true
                            store.reset()
                        })
                    }
                }
            }
        }
        .alert("检测失败", isPresented: Binding(get: {
            if case .failed = store.flow { return true }
            return false
        }, set: { if !$0 { store.dismissError() } })) {
            Button("知道了", role: .cancel) { store.dismissError() }
        } message: {
            if case .failed(let message) = store.flow { Text(message) }
        }
        .task {
            await store.loadHistory()
            guard !Task.isCancelled else { return }
            if !hasLoadedHistory {
                hasLoadedHistory = true
                if startsInCapture { beginCapture() }
            }
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            await loadSelectedPhoto(from: selectedPhoto)
        }
        .onChange(of: store.selectedImage) { _, newValue in
            if newValue != nil {
                store.processSelectedImage()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if store.result != nil && !showsPlanCallToAction {
            SkinReportView(store: store, onBack: { dismiss() }, onRetake: beginCapture)
        } else {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AISkinSpacing.medium) {
                        welcomeContentView
                    }
                    .padding(.horizontal, AISkinSpacing.screenEdge)
                    .padding(.top, AISkinSpacing.small)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
            }
        }
    }

    @ViewBuilder
    private var welcomeContentView: some View {
        if let latest = store.lastResult {
            overviewContent(latest: latest)
        } else if hasLoadedHistory && !store.isLoadingHistory && store.historyError == nil {
            SkinDetectionWelcome(
                onTakePhoto: beginCapture
            )
            .padding(.top, AISkinSpacing.small)
        }
        if let photoLoadError {
            AISkinStateView(content: .error(title: "无法读取照片", message: photoLoadError), actionTitle: "重新选择", action: {
                self.photoLoadError = nil
                showPhotoPicker = true
            })
        }
        if let error = store.historyError {
            AISkinStateView(content: .error(title: "检测历史暂时无法加载", message: error), actionTitle: "重试", action: {
                Task { await store.retryHistory() }
            })
        } else if (!hasLoadedHistory || store.isLoadingHistory) && !store.hasHistory {
            AISkinStateView(content: .loading(message: "加载最近检测…"))
        }
    }

    private func overviewContent(latest: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: AISkinSkinReportTokens.chapterGap) {
            VStack(spacing: AISkinSpacing.small) {
                HStack {
                    Text("最近一次检测").foregroundStyle(AISkinColor.accent)
                    Spacer()
                    if let date = latest.createdAt { Text(date.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(AISkinColor.textSecondary) }
                }.font(AISkinSkinReportTokens.meta)
                summaryCard(latest)
                    .accessibilityIdentifier("skin.overview.summary")
            }
            HStack(spacing: AISkinSpacing.small) {
                AISkinSkinReportAction(title: "查看完整报告", systemImage: "doc.text", action: { store.selectHistory(latest) })
                    .accessibilityIdentifier("skin.overview.report")
                AISkinButton(action: beginCapture) {
                    Text("重新检测")
                }
                .accessibilityIdentifier("skin.overview.capture")
            }
            .padding(.top, -AISkinSpacing.xSmall)
            if let onCreatePlan {
                SkinPlanCallToAction(action: onCreatePlan)
            }
            HStack {
                AISkinSectionHeading(title: "检测历史")
                Spacer()
                AISkinActionLink(title: "全部", layout: .compact) { store.isHistoryPresented = true }
                    .accessibilityIdentifier("skin.overview.history")
            }
            if store.history.count > 1 {
                AISkinCard {
                    VStack(spacing: 0) {
                        ForEach(Array(store.history.dropFirst().prefix(3).enumerated()), id: \.offset) { index, result in
                            if index > 0 { AISkinDivider() }
                            SkinHistoryRow(history: result, scope: .overview) { store.selectHistory(result) }
                        }
                    }
                }
            } else {
                Text("这是你的首次检测，后续记录会显示在这里。")
                    .font(AISkinTypography.callout)
                    .foregroundStyle(AISkinColor.textSecondary)
            }
        }
    }

    private func summaryCard(_ result: AnalysisResult) -> some View {
        AISkinSkinSummaryCard(score: result.healthScore, skinType: result.skinType?.type ?? "未记录肤质", condition: result.context?.reportStatus ?? "未记录状态", metrics: result.reportMetrics, conclusion: result.summary ?? "该次记录暂无结论")
    }

    private func beginCapture() {
        // Wait for a full-screen report to dismiss before presenting the camera.
        let dismissesReport = showsPlanCallToAction && store.result != nil
        opensCameraAfterReport = dismissesReport
        store.reset()
        if !dismissesReport { showCamera = true }
    }

    private var isAnalyzing: Bool {
        if case .analyzing = store.flow { return true }
        return false
    }

    // MARK: - Methods
    
    @MainActor
    private func loadSelectedPhoto(from item: PhotosPickerItem) async {
        defer { if selectedPhoto == item { selectedPhoto = nil } }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                photoLoadError = "所选照片格式暂不支持，请换一张照片重试。"
                return
            }
            try Task.checkCancellation()
            photoLoadError = nil
            store.selectedImage = image
        } catch is CancellationError {
            return
        } catch {
            photoLoadError = "照片读取失败，请确认照片已下载到本机后重试。"
        }
    }
    
}

struct SkinContextForm: View {
    @Environment(\.dismiss) private var dismiss
    let analysisID: String
    @ObservedObject var store: SkinAnalysisStore
    @State private var condition: String
    @State private var light: String
    @State private var feelings: Set<String>

    private let conditions: [(String, String, String)] = [
        ("纯素颜", "未上妆，洁面后未护肤，或护肤已超过 30 分钟", "face.smiling"),
        ("护肤后", "使用护肤品后 30 分钟以内", "drop"),
        ("上妆后", "使用了粉底、隔离等彩妆产品", "sparkles"),
        ("特殊时期", "晒伤、爆痘、泛红不适或医美恢复期等", "heart.text.square")
    ]
    private let feelingOptions = ["干燥", "紧绷", "出油", "刺痛", "泛红", "无明显不适"]

    init(analysisID: String, context: SkinAnalysisContext?, store: SkinAnalysisStore) {
        self.analysisID = analysisID
        self.store = store
        _condition = State(initialValue: context?.condition ?? "")
        _light = State(initialValue: context?.light ?? "")
        _feelings = State(initialValue: Set(context?.feelings ?? []))
    }

    var body: some View {
        NavigationStack {
            AISkinScreenBackground {
                ScrollView {
                    VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                        Text("记录一下拍摄时的状态，帮助理解两次结果的差异。")
                            .font(AISkinSkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
                            .padding(.bottom, AISkinSpacing.xSmall)
                        ForEach(conditions, id: \.0) { item in
                            AISkinSkinConditionOption(title: item.0, detail: item.1, systemImage: item.2, isSelected: condition == item.0) { condition = item.0 }
                        }
                        VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                            AISkinSectionHeading(title: "光线与实际肤感", detail: "选填")
                            VStack(alignment: .leading, spacing: AISkinSpacing.medium) {
                                Picker("拍摄光线", selection: $light) {
                                    Text("未记录").tag("")
                                    Text("自然光").tag("自然光")
                                    Text("室内光").tag("室内光")
                                    Text("不确定").tag("不确定")
                                }.pickerStyle(.segmented)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityIdentifier("skin.context.light")
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AISkinSpacing.small) {
                                    ForEach(feelingOptions, id: \.self) { option in
                                        AISkinTag(title: option, tone: .accent, state: feelings.contains(option) ? .selected : .normal, action: {
                                            feelings = SkinAnalysisContext.togglingFeeling(option, in: feelings)
                                        })
                                        .accessibilityIdentifier("skin.context.feeling.\(option)")
                                    }
                                }
                            }.padding(.vertical, AISkinSpacing.small)
                        }
                        .font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.textSecondary).tint(AISkinColor.accent)
                        if let error = store.contextSaveError {
                            AISkinStateView(content: .error(title: "保存失败", message: error))
                        }
                    }.padding(AISkinSpacing.screenEdge)
                }
                .disabled(store.isSavingContext)
                .safeAreaInset(edge: .bottom) {
                    AISkinReportFooter {
                        AISkinButton(isLoading: store.isSavingContext, action: save) { Text("保存拍摄状态") }
                            .accessibilityIdentifier("skin.context.save")
                            .disabled(condition.isEmpty)
                    }
                }
            }
            .navigationTitle("选择测肤状态").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() }.disabled(store.isSavingContext) } }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(store.isSavingContext)
    }

    private func save() {
        Task {
            if await store.updateContext(analysisID: analysisID, condition: condition, light: light.isEmpty ? nil : light, feelings: feelings.sorted()) {
                dismiss()
            }
        }
    }
}
