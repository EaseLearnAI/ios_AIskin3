//
//  IngredientView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct IngredientView: View {
    @Environment(\.dismiss) private var dismiss

    let productId: String

    @StateObject private var store = IngredientAnalysisStore()
    @State private var showDeleteModal = false
    private enum Sheet: String, Identifiable {
        case actions, registration, pairing
        var id: String { rawValue }
    }
    @State private var sheet: Sheet?
    @State private var pendingSheet: Sheet?
    @State private var pendingDelete = false
    @State private var showsDeleteError = false
    @State private var savedNotice = false
    @State private var headingHeights: [IngredientReportSection: CGFloat] = [:]

    var body: some View {
        ZStack {
            if isLoading {
                AISkinProcessingScreen(title: "成分分析", message: "正在准备成分报告", onCancel: { dismiss() })
            } else {
                reportBody
            }
        }

        .task(id: productId) { await store.load(productID: productId) }
        .sheet(item: $sheet, onDismiss: presentPendingAction) { destination in
            switch destination {
            case .actions:
                productActionsSheet
            case .registration:
                registrationSheet
            case .pairing:
                NavigationStack { ConflictSelectionView(initialProductID: productId) }
            }
        }
        .alert("确认删除", isPresented: $showDeleteModal) {
            Button("取消", role: .cancel) {}
            Button("确认删除", role: .destructive, action: deleteProduct)
        } message: {
            Text("将删除这件产品及其分析结果，此操作无法撤销。")
        }
        .alert("删除失败", isPresented: $showsDeleteError) {
            Button("取消", role: .cancel) {}
            Button("重试", action: deleteProduct)
        } message: {
            Text(store.deleteError ?? "删除失败，请重试。")
        }
        .overlay(alignment: .top) {
            if savedNotice {
                AISkinToast(message: "产品信息已保存", systemImage: "checkmark.circle.fill", onDismiss: { savedNotice = false })
                    .padding(AISkinSpacing.screenEdge)
            }
        }
        .task(id: savedNotice) {
            guard savedNotice else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { savedNotice = false }
        }
    }

    private var isLoading: Bool {
        switch store.state {
        case .idle, .loading: true
        default: false
        }
    }

    private var reportBody: some View {
        AISkinReportScreen {
            AppHeader(title: "成分分析结果", rightIcon: isLoaded && !store.isDeleting ? "ellipsis" : nil,
                      rightAction: { sheet = .actions }, rightAccessibilityLabel: "更多产品操作", backAction: { dismiss() })
        } content: {
            content.padding(.top, AISkinSpacing.xSmall)
        } footer: {
            if case .loaded = store.state { ingredientActions }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .idle, .loading:
            EmptyView()
        case .failed(let error):
            AISkinStateView(
                content: .error(title: "成分分析加载失败", message: error),
                actionTitle: "重试",
                action: reload
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let product, let analysis):
            loadedContent(product: product, analysis: analysis)
        }
    }

    private func loadedContent(product: Product, analysis: IngredientAnalysis) -> some View {
        VStack(spacing: 0) {
          GeometryReader { viewport in
          ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: AISkinReportTokens.sectionGap) {
                    ProductInfo(product: product)
                    AnalysisOverview(analysis: analysis)
                        .accessibilityIdentifier("ingredient.summary")
                    AISkinReportAnchorBar(items: IngredientReportSection.allCases, title: \.rawValue) { section in
                        // Align the heading's anchor with the same viewport anchor:
                        // top = y * (viewportHeight - headingHeight).
                        let availableHeight = max(1, viewport.size.height - (headingHeights[section] ?? 0))
                        let alignment = UnitPoint(x: 0, y: AISkinReportTokens.anchorScrollClearance / availableHeight)
                        withAnimation(AISkinMotion.standard) { proxy.scrollTo(section, anchor: alignment) }
                    }
                    .accessibilityIdentifier("ingredient.sections")
                    .aiSkinStickyReportDirectory(in: "ingredient-report-scroll")

                    IngredientTextSection(section: .effects, number: "01", title: "功效分析", systemImage: "sparkles", items: analysis.efficacyAnalysis)
                        .accessibilityIdentifier("ingredient.section.effects")
                    IngredientTextSection(section: .risks, number: "02", title: "潜在风险", systemImage: "exclamationmark.shield", items: analysis.potentialRisks)
                        .accessibilityIdentifier("ingredient.section.risks")
                    IngredientTextSection(section: .advice, number: "03", title: "使用建议", systemImage: "square.and.pencil", items: analysis.recommendations)
                        .accessibilityIdentifier("ingredient.section.advice")
                    IngredientListSection(ingredients: product.ingredients)
                        .aiSkinGeneratedResult()
                        .accessibilityIdentifier("ingredient.section.ingredients")
                    AISkinActionLink(title: "和其他产品检查搭配", layout: .card(systemImage: "square.3.layers.3d")) { sheet = .pairing }
                        .accessibilityIdentifier("ingredient.pair-products")
                }
                .padding(.horizontal, AISkinSpacing.screenEdge)
                .padding(.bottom, AISkinSpacing.large)
            }
            .coordinateSpace(name: "ingredient-report-scroll")
            .onPreferenceChange(AISkinReportScrollTargetHeights<IngredientReportSection>.self) { headingHeights = $0 }
          }
          }
          .frame(maxHeight: .infinity)
          .clipped()
        }
    }

    private var isLoaded: Bool {
        if case .loaded = store.state { return true }
        return false
    }

    @ViewBuilder
    private var registrationSheet: some View {
        if case .loaded(let product, _) = store.state {
            TagSelectorModal(product: product, store: store, onSaved: { savedNotice = true })
                .presentationDetents([.height(AISkinReportTokens.compactSheetHeight), .large])
        }
    }

    private var productActionsSheet: some View {
        AISkinBottomSheet(title: "产品操作", onClose: { sheet = nil }) {
            VStack(spacing: 0) {
                Button { transition(to: .registration) } label: {
                    AISkinSettingsRow(systemImage: "slider.horizontal.3", title: "编辑产品信息")
                }.accessibilityIdentifier("ingredient.actions.edit")
                AISkinDivider()
                Button { transition(to: .pairing) } label: {
                    AISkinSettingsRow(systemImage: "square.3.layers.3d", title: "和其他产品检查搭配")
                }.accessibilityIdentifier("ingredient.actions.pair")
                AISkinDivider()
                Button(role: .destructive) {
                    pendingDelete = true
                    sheet = nil
                } label: {
                    AISkinSettingsRow(systemImage: "trash", title: "删除这件产品", isDestructive: true)
                }.accessibilityIdentifier("ingredient.actions.delete")
            }
            .buttonStyle(AISkinPressableStyle())
        } footer: { EmptyView() }
        .presentationDetents([.height(AISkinReportTokens.actionSheetHeight), .large])
    }

    private func transition(to destination: Sheet) {
        pendingSheet = destination
        sheet = nil
    }

    private func presentPendingAction() {
        if let next = pendingSheet {
            pendingSheet = nil
            sheet = next
        } else if pendingDelete {
            pendingDelete = false
            showDeleteModal = true
        }
    }

    private var ingredientActions: some View {
        AISkinReportFooter {
          HStack(spacing: AISkinSpacing.xSmall) {
            AISkinIconButton(systemName: "trash", accessibilityLabel: "删除分析结果", variant: .outlined, action: { showDeleteModal = true })
                .frame(width: AISkinReportTokens.deleteWidth, height: AISkinReportTokens.deleteWidth)
                .accessibilityIdentifier("ingredient.delete")
            AISkinButton(isLoading: store.isDeleting, action: { savedNotice = false; sheet = .registration }) {
                Label(store.isDeleting ? "正在删除…" : "保存分析结果", systemImage: "bookmark")
            }
            .accessibilityIdentifier("ingredient.registration")
        }
        .disabled(store.isDeleting)
        }
    }

    private func reload() {
        Task { await store.load(productID: productId) }
    }

    private func deleteProduct() {
        Task {
            if await store.delete(productID: productId) {
                dismiss()
            } else {
                showsDeleteError = true
            }
        }
    }
}

struct TagSelectorModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var store: IngredientAnalysisStore
    let onSaved: () -> Void
    private let productID: String

    @State private var productName: String
    @FocusState private var isNameFocused: Bool
    @State private var nameError: String?
    @State private var unopened: Bool
    @State private var validationError: String?
    @State private var selectedTag: String
    @State private var openingDate: Date?
    @State private var showsDatePicker = false
    @State private var pendingDate = Date()

    init(product: Product, store: IngredientAnalysisStore, onSaved: @escaping () -> Void) {
        self.productID = product.id
        self.store = store
        self.onSaved = onSaved
        _productName = State(initialValue: product.name)
        _unopened = State(initialValue: product.openingStatus == "unopened")
        _selectedTag = State(initialValue: product.label ?? "")
        _openingDate = State(initialValue: product.openingDate)
    }

    var body: some View {
        AISkinBottomSheet(title: "保存产品信息", closeLabel: "取消", isBusy: store.isSaving, onClose: { dismiss() }) {
            VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                    AISkinSectionHeading(title: "产品名称")
                    AISkinField(state: nameError != nil ? .error : (isNameFocused ? .focused : .normal), variant: .form) {
                        TextField("请输入产品名称", text: $productName)
                            .focused($isNameFocused)
                            .submitLabel(.done)
                            .onSubmit { isNameFocused = false }
                            .accessibilityLabel("产品名称")
                            .accessibilityIdentifier("ingredient.registration.name")
                    }
                    if let nameError {
                        AISkinStateView(content: .error(title: "请补充产品名称", message: nameError), layout: .inline)
                            .accessibilityIdentifier("ingredient.registration.name-error")
                    }
                }
                AISkinSectionHeading(title: "产品标签", detail: "单选")
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: AISkinSpacing.xxSmall), count: dynamicTypeSize.isAccessibilitySize ? 3 : 5),
                    spacing: AISkinSpacing.xSmall
                ) {
                    ForEach(ProductCategory.registrationCategories) { category in
                        AISkinTag(title: category.name, tone: .accent,
                                  state: selectedTag == category.id ? .selected : .normal,
                                  variant: .selectionPill,
                                  action: { selectedTag = category.id; validationError = nil })
                            .accessibilityIdentifier("ingredient.registration.category.\(category.id)")
                            .accessibilityValue(selectedTag == category.id ? "已选择" : "未选择")
                    }
                }
                VStack(spacing: AISkinSpacing.xxSmall) {
                    HStack {
                        AISkinSectionHeading(title: "开封日期")
                        Toggle("尚未开封", isOn: $unopened)
                            .toggleStyle(AISkinCheckboxStyle())
                            .fixedSize()
                            .accessibilityIdentifier("ingredient.registration.unopened")
                    }
                    Button {
                        pendingDate = openingDate ?? Date()
                        showsDatePicker = true
                    } label: {
                        AISkinField(variant: .form) {
                            Text(unopened ? "尚未开封" : openingDate.map { $0.formatted(date: .numeric, time: .omitted) } ?? "年 / 月 / 日")
                            Spacer()
                            Image(systemName: "calendar")
                        }
                    }
                    .buttonStyle(AISkinPressableStyle())
                    .disabled(unopened)
                    .accessibilityLabel("开封日期")
                    .accessibilityValue(unopened ? "尚未开封" : openingDate.map { $0.formatted(date: .numeric, time: .omitted) } ?? "未记录")
                    .accessibilityIdentifier("ingredient.registration.record-opening")
                }
                if let validationError {
                    AISkinStateView(content: .error(title: "保存未完成", message: validationError), layout: .inline)
                        .accessibilityIdentifier("ingredient.registration.error")
                }
            }
        } footer: {
            AISkinButton(isLoading: store.isSaving, action: saveProductTag) { Text("保存") }
                .accessibilityIdentifier("ingredient.registration.save")
        }
        .onChange(of: productName) { _, _ in
            nameError = nil
            validationError = nil
        }
        .sheet(isPresented: $showsDatePicker) {
            AISkinBottomSheet(title: "开封日期", closeLabel: "取消日期选择", onClose: { showsDatePicker = false }) {
                DatePicker("开封日期", selection: $pendingDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(AISkinColor.accent)
                    .accessibilityIdentifier("ingredient.registration.calendar")
            } footer: {
                AISkinButton(action: { openingDate = pendingDate; showsDatePicker = false }) { Text("确定日期") }
                    .accessibilityIdentifier("ingredient.registration.confirm-date")
            }
            .presentationDetents([.height(AISkinReportTokens.dateSheetHeight), .large])
        }
    }

    private func saveProductTag() {
        guard !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            nameError = "照片未识别到名称时，可以在这里手动填写。"
            isNameFocused = true
            return
        }
        guard !selectedTag.isEmpty else {
            validationError = "请选择产品分类"
            return
        }
        validationError = nil
        isNameFocused = false
        let status = unopened ? "unopened" : (openingDate == nil ? "unknown" : "opened")
        Task {
            let saved = await store.saveRegistration(productID: productID, name: productName, label: selectedTag,
                                                     openingStatus: status, openingDate: unopened ? nil : openingDate)
            if saved {
                onSaved()
                dismiss()
            } else {
                validationError = store.saveError ?? "保存失败，已保留填写内容，请重试。"
            }
        }
    }
}
