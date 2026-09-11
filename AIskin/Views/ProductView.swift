//
//  ProductView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

enum ProductEntry: Equatable {
    case library
    case capture
    case conflictSelection(productID: String?)
}

struct ProductView: View {
    var initialEntry: ProductEntry = .library
    @Binding var requestedEntry: ProductEntry?
    var onProductAdded: ((String) -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var store: ProductsStore
    @StateObject private var editingStore = IngredientAnalysisStore()
    @State private var editingProduct: Product?
    @State private var analysisImage: ProductAnalysisImage?
    @State private var showPhotoLibrary = false
    @State private var showCapture = false
    @State private var capturedImage: UIImage?
    @State private var presentedDestination: ProductDestination?
    @State private var pendingDestination: ProductDestination?
    @State private var hasAppliedInitialEntry = false

    init(initialEntry: ProductEntry = .library, requestedEntry: Binding<ProductEntry?> = .constant(nil), store: ProductsStore? = nil, onProductAdded: ((String) -> Void)? = nil) {
        self.initialEntry = initialEntry
        self._requestedEntry = requestedEntry
        self._store = StateObject(wrappedValue: store ?? ProductsStore())
        self.onProductAdded = onProductAdded
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: AISkinSpacing.sectionGap) {
                    if case .failed(let message) = store.loadState {
                        AISkinCard {
                            AISkinStateView(content: .error(title: "护肤柜加载失败", message: message), actionTitle: "重试", action: store.load)
                        }
                    }
                    if store.products.isEmpty {
                        if case .loading = store.loadState {
                            AISkinStateView(content: .loading(message: "正在整理护肤柜…"))
                        } else if case .empty = store.loadState {
                            AddProduct { source in
                                if source == .camera {
                                    beginCapture()
                                } else {
                                    capturedImage = nil
                                    showPhotoLibrary = true
                                }
                            }
                        }
                    } else {
                        ProductList(
                            products: store.products,
                            categories: ProductCategory.defaultCategories,
                            selectedCategory: $store.selectedCategory,
                            selectionMode: $store.isSelectingConflicts,
                            selectedProductIds: $store.selectedProductIDs,
                            onProductSelected: { presentedDestination = .ingredient(productID: $0.id) },
                            onToggleSelection: { toggleConflictSelection(productID: $0) },
                            onDeleteProduct: { id in Task { await store.delete(productID: id) } },
                            onBeginConflict: { productID in
                                beginConflictSelection(using: proxy)
                                if let productID { store.toggleConflictSelection(productID: productID) }
                            },
                            onCancelConflict: cancelConflictSelection,
                            onAddProduct: beginCapture,
                            onEditProduct: { editingProduct = $0 }
                        )
                        .id(ProductScrollTarget.library)
                    }
                }
                .padding(.horizontal, AISkinSpacing.screenEdge)
                .padding(.top, AISkinSpacing.xxSmall)
                .padding(.bottom, AISkinSpacing.xxLarge)
            }
            .lookinName("product.content-scroll")
            .refreshable { await store.loadProducts() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if store.isSelectingConflicts {
                    Group {
                        if store.selectedProductIDs.count >= 2 {
                            HStack(spacing: AISkinSpacing.xSmall) {
                                AISkinButton(action: analyzeConflict) {
                                    Text("开始检测")
                                }
                                .frame(maxWidth: AISkinLayout.floatingActionMaxWidth)
                                .accessibilityLabel("开始检测，已选择 \(store.selectedProductIDs.count) 个产品")
                                .accessibilityIdentifier("cabinet.analyze-conflict")
                                .lookinName("product.conflict-selection.analyze")

                            }
                        } else {
                            AISkinToast(
                                message: "请选择 2 个产品进行冲突检测",
                                systemImage: "checkmark.circle.fill",
                                dismissAccessibilityLabel: "退出冲突检测",
                                onDismiss: cancelConflictSelection
                            )
                            .lookinName("product.conflict-selection.toast")
                        }
                    }
                    .padding(.horizontal, AISkinSpacing.screenEdge)
                    .padding(.bottom, AISkinSpacing.xLarge)
                    .transition(conflictOverlayTransition)
                }
            }
            .onAppear {
                if !hasAppliedInitialEntry {
                    applyEntry(requestedEntry ?? initialEntry, using: proxy)
                    requestedEntry = nil
                    hasAppliedInitialEntry = true
                }
                store.load()
            }
            .onChange(of: requestedEntry) { _, entry in
                guard let entry else { return }
                applyEntry(entry, using: proxy)
                requestedEntry = nil
            }
        }
        .sheet(item: $editingProduct) { product in
            TagSelectorModal(product: product, store: editingStore, onSaved: store.load)
                .presentationDetents([.height(AISkinReportTokens.compactSheetHeight), .large])
        }
        .fullScreenCover(isPresented: $showCapture, onDismiss: {
            if let capturedImage { analysisImage = ProductAnalysisImage(image: capturedImage) }
        }) {
            AISkinCameraCapture(image: $capturedImage)
        }
        .sheet(isPresented: $showPhotoLibrary, onDismiss: {
            if let capturedImage { analysisImage = ProductAnalysisImage(image: capturedImage) }
        }) {
            AISkinPhotoLibraryPicker { image in
                capturedImage = image
                showPhotoLibrary = false
            }
        }
        .fullScreenCover(item: $analysisImage, onDismiss: presentPendingDestination) { selection in
            NavigationStack {
                AISkinScreenBackground {
                    ProductAnalysisView(
                        image: selection.image,
                        store: store,
                        onProductAdded: { productId in
                            pendingDestination = .ingredient(productID: productId)
                            onProductAdded?(productId)
                            analysisImage = nil
                            store.load()
                        },
                        onDismiss: {
                            analysisImage = nil
                        }
                    )
                }
            }
        }
        .fullScreenCover(item: $presentedDestination, onDismiss: destinationDidDismiss) { destination in
            NavigationStack {
                AISkinScreenBackground {
                    switch destination {
                    case .ingredient(let productID):
                        IngredientView(productId: productID)
                    case .conflict(let productIDs):
                        ConflictView(productIds: productIDs)
                    }
                }
            }
        }
        .lookinName("product.screen")
    }

    private var conflictOverlayTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }

    private func applyEntry(_ entry: ProductEntry, using proxy: ScrollViewProxy) {
        switch entry {
        case .library:
            cancelConflictSelection()
        case .capture:
            cancelConflictSelection()
            beginCapture()
        case .conflictSelection(let productID):
            beginConflictSelection(using: proxy)
            if let productID { store.selectedProductIDs.insert(productID) }
        }
    }

    private func beginConflictSelection(using proxy: ScrollViewProxy) {
        withAnimation(reduceMotion ? nil : AISkinMotion.standard) {
            store.beginConflictSelection()
        }

        if reduceMotion {
            proxy.scrollTo(ProductScrollTarget.library, anchor: .top)
        } else {
            withAnimation(AISkinMotion.emphasized) {
                proxy.scrollTo(ProductScrollTarget.library, anchor: .top)
            }
        }
    }

    private func cancelConflictSelection() {
        withAnimation(reduceMotion ? nil : AISkinMotion.standard) {
            store.cancelConflictSelection()
        }
    }

    private func toggleConflictSelection(productID: String) {
        withAnimation(reduceMotion ? nil : AISkinMotion.standard) {
            store.toggleConflictSelection(productID: productID)
        }
    }

    private func clearCaptureSource() {
        capturedImage = nil
    }

    private func beginCapture() {
        clearCaptureSource()
        showCapture = true
    }

    private func analyzeConflict() {
        guard store.selectedProductIDs.count >= 2 else {
            return
        }
        guard let productIdsArray = store.consumeConflictSelection() else { return }
        presentedDestination = .conflict(productIDs: productIdsArray)
    }

    private func destinationDidDismiss() {
        store.cancelConflictSelection()
        store.load()
    }

    private func presentPendingDestination() {
        clearCaptureSource()
        guard let pendingDestination else { return }
        self.pendingDestination = nil
        presentedDestination = pendingDestination
    }
}

private enum ProductScrollTarget: Hashable {
    case library
}

private struct ProductAnalysisImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

private enum ProductDestination: Identifiable {
    case ingredient(productID: String)
    case conflict(productIDs: [String])

    var id: String {
        switch self {
        case .ingredient(let productID):
            return "ingredient-\(productID)"
        case .conflict(let productIDs):
            return "conflict-\(productIDs.sorted().joined(separator: "-"))"
        }
    }
}

private struct ProductAnalysisView: View {
    let image: UIImage
    @ObservedObject var store: ProductsStore
    let onProductAdded: (String) -> Void
    let onDismiss: () -> Void

    @State private var submissionTask: Task<Void, Never>?

    var body: some View {
        AISkinProcessingScreen(title: "成分分析", message: "正在分析成分表",
                               error: store.addError, onRetry: submitProduct, onCancel: {
            cancelSubmission()
            onDismiss()
        })
        .onAppear {
            guard submissionTask == nil else { return }
            store.resetAddFlow()
            submitProduct()
        }
        .onDisappear(perform: cancelSubmission)
        .lookinName("product.analysis")
    }

    private func submitProduct() {
        guard !store.isAdding else { return }
        submissionTask = Task {
            guard let productID = await store.addProduct(from: image), !Task.isCancelled else { return }
            onProductAdded(productID)
        }
    }

    private func cancelSubmission() {
        submissionTask?.cancel()
        submissionTask = nil
        store.resetAddFlow()
    }
}
