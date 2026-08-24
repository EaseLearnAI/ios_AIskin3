//
//  ProductView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ProductView: View {
    var initialConflictMode: Bool = false
    @StateObject private var store = ProductsStore()
    @State private var showAddModal = false
    @State private var showIngredientViewForProduct: String?
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var currentStep = 0
    @State private var stepStatus: [String: String] = [
        "create": "等待创建",
        "upload": "等待上传",
        "extract": "等待提取",
        "analyze": "等待分析"
    ]
    @State private var showConflictView = false
    @State private var conflictProductIds: [String] = []
    
    var body: some View {
        ZStack {
            Color(red: 0.973, green: 0.973, blue: 0.980)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Add Product Card
                        AddProduct(
                            showUploadModal: $showAddModal,
                            onEnableConflictMode: {
                                store.beginConflictSelection()
                            }
                        )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Conflict Mode Header
                        if store.isSelectingConflicts {
                            ConflictModeHeader(
                                selectedCount: store.selectedProductIDs.count,
                                onAnalyze: {
                                    // Navigate to conflict analysis
                                    if store.selectedProductIDs.count >= 2 {
                                        analyzeConflict()
                                    }
                                },
                                onCancel: {
                                    store.cancelConflictSelection()
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Product List
                        ProductList(
                            products: store.products,
                            categories: ProductCategory.defaultCategories,
                            selectedCategory: $store.selectedCategory,
                            selectionMode: $store.isSelectingConflicts,
                            selectedProductIds: $store.selectedProductIDs,
                            onProductSelected: { product in
                                showIngredientViewForProduct = product.id
                            },
                            onToggleSelection: { productId in
                                store.toggleConflictSelection(productID: productId)
                            },
                            onDeleteProduct: { productId in
                                Task { await store.delete(productID: productId) }
                            }
                        )
                        .padding(.bottom, 80)
                    }
                }
                .lookinName("product.content-scroll")
            }
        }
        .overlay {
            if showAddModal {
                AddProductModal(
                    store: store,
                    selectedImage: $selectedImage,
                    isLoading: $isLoading,
                    currentStep: $currentStep,
                    stepStatus: $stepStatus,
                    onProductAdded: { productId in
                        if let productId = productId {
                            showIngredientViewForProduct = productId
                        }
                        showAddModal = false
                        resetAddProductState()
                        // Reload products list after adding new product
                        store.load()
                    },
                    onDismiss: {
                        showAddModal = false
                        resetAddProductState()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showAddModal)
            }
        }
        .sheet(isPresented: Binding(
            get: { showIngredientViewForProduct != nil },
            set: { 
                if !$0 { 
                    showIngredientViewForProduct = nil
                    // 确保返回到产品分析页面时刷新产品列表
                    store.load()
                }
            }
        )) {
            if let productId = showIngredientViewForProduct {
                NavigationView {
                    IngredientView(productId: productId)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { showConflictView },
            set: { newValue in
                print("\n============================================================")
                print("📱 ProductView: ConflictView sheet Binding setter被调用")
                print("============================================================\n")
                print("📱 步骤1: sheet状态变化")
                print("   - 新值: \(newValue)")
                print("   - 旧值: \(showConflictView)")
                
                if !newValue {
                    print("\n📱 步骤2: sheet正在关闭")
                    print("   - ConflictView sheet被关闭")
                    print("   - 用户返回到ProductView（产品分析页面）")
                    
                    print("\n📱 步骤3: 重置冲突模式相关状态")
                    let oldShowConflictView = showConflictView
                    let oldConflictMode = store.isSelectingConflicts
                    let oldSelectedCount = store.selectedProductIDs.count
                    let oldConflictIdsCount = conflictProductIds.count
                    
                    showConflictView = false
                    store.cancelConflictSelection()
                    conflictProductIds = []
                    
                    print("   - showConflictView: \(oldShowConflictView) -> false")
                    print("   - conflictMode: \(oldConflictMode) -> false")
                    print("   - selectedProductIds: \(oldSelectedCount)个 -> 0个")
                    print("   - conflictProductIds: \(oldConflictIdsCount)个 -> 0个")
                    
                    print("\n📱 步骤4: 确认返回到产品分析页面")
                    print("   - ProductView现在应该可见")
                    print("   - ProductView是BottomNavigationView的tab 1（产品分析）")
                    print("   - 用户应该能看到产品列表和底部导航栏")
                    print("   - 底部导航栏的'产品分析'tab应该处于选中状态")
                    
                    // 确保在主线程上执行，以便UI能正确更新
                    DispatchQueue.main.async {
                        print("\n📱 步骤5: 在主线程上确认状态")
                        print("   - showConflictView当前值: \(showConflictView)")
                        print("   - conflictMode当前值: \(store.isSelectingConflicts)")
                        print("   - ProductView应该已经完全显示")
                    }
                    
                    print("\n============================================================")
                    print("✅ ProductView: 状态重置完成，已返回到产品分析页面")
                    print("============================================================\n")
                } else {
                    print("\n📱 步骤2: sheet正在打开")
                    print("   - 显示ConflictView")
                    showConflictView = newValue
                    print("   ✅ showConflictView = true")
                    print("============================================================\n")
                }
            }
        )) {
            ConflictView(productIds: conflictProductIds)
                .onAppear {
                    print("\n============================================================")
                    print("📱 ProductView: ConflictView sheet已显示")
                    print("============================================================\n")
                    print("✅ ConflictView现在在sheet中显示")
                    print("📱 用户可以看到冲突分析界面")
                    print("============================================================\n")
                }
        }
        .onAppear {
            print("\n============================================================")
            print("📱 ProductView: onAppear被调用")
            print("============================================================\n")
            print("✅ ProductView已显示")
            print("📱 这是BottomNavigationView的tab 1（产品分析页面）")
            print("📱 开始加载产品列表...")
            
            // 如果从核心功能页面跳转过来需要启用冲突模式
            if initialConflictMode {
                print("📱 检测到需要启用冲突模式")
                store.beginConflictSelection()
            }
            
            print("============================================================\n")
            store.load()
        }
        .onDisappear {
            print("\n============================================================")
            print("📱 ProductView: onDisappear被调用")
            print("============================================================\n")
            print("⚠️ ProductView已隐藏")
            print("============================================================\n")
        }
        .lookinName("product.screen")
    }
    
    private func resetAddProductState() {
        selectedImage = nil
        isLoading = false
        currentStep = 0
        stepStatus = [
            "create": "等待创建",
            "upload": "等待上传",
            "extract": "等待提取",
            "analyze": "等待分析"
        ]
    }
    
    private func analyzeConflict() {
        print("\n============================================================")
        print("🔘 ProductView: 用户点击'分析冲突'按钮")
        print("============================================================\n")
        
        guard store.selectedProductIDs.count >= 2 else {
            print("❌ 错误: 至少需要选择2个产品")
            print("📊 当前选择的产品数量: \(store.selectedProductIDs.count)")
            return
        }
        
        guard let productIdsArray = store.consumeConflictSelection() else { return }
        print("📊 准备分析的产品列表:")
        for (index, productId) in productIdsArray.enumerated() {
            print("   \(index + 1). 产品ID: \(productId)")
        }
        
        print("\n📱 步骤1: 立即显示ConflictView（显示加载动画）")
        print("   - 设置conflictProductIds: \(productIdsArray)")
        print("   - 设置showConflictView = true")
        
        // 立即显示ConflictView，让加载动画立即出现
        conflictProductIds = productIdsArray
        showConflictView = true
        
        print("✅ ConflictView已显示，用户应该立即看到加载动画")
        print("📱 步骤2: ConflictView将在onAppear时开始API调用")
        print("============================================================\n")
    }
}

struct ConflictModeHeader: View {
    let selectedCount: Int
    let onAnalyze: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0))
                
                Text("选择需要检测冲突的产品")
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                Button("取消", action: onCancel)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lookinName("product.conflict-selection.cancel")
            }
            
            HStack {
                Button(action: onAnalyze) {
                    Text("分析冲突")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedCount >= 2 ?
                            Color(red: 0.808, green: 0.576, blue: 0.847) :
                            Color.gray
                        )
                        .cornerRadius(8)
                }
                .disabled(selectedCount < 2)
                .lookinName("product.conflict-selection.analyze")
                
                Spacer()
                
                Text("已选择 \(selectedCount) 个产品 (至少需要2个)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .lookinName("product.conflict-selection")
    }
}

struct AddProductModal: View {
    @ObservedObject var store: ProductsStore
    @Environment(\.dismiss) var dismiss
    @Binding var selectedImage: UIImage?
    @Binding var isLoading: Bool
    @Binding var currentStep: Int
    @Binding var stepStatus: [String: String]
    let onProductAdded: (String?) -> Void
    let onDismiss: () -> Void
    
    @State private var showProgressSteps = false
    @State private var isExtracting = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var hasError = false
    
    var canSubmit: Bool {
        selectedImage != nil
    }
    
    var submitButtonText: String {
        if isExtracting {
            return "正在提取成分..."
        }
        if isAnalyzing {
            return "正在分析成分..."
        }
        return "上传图片并分析"
    }
    
    var body: some View {
        ZStack {
            // Backdrop with blur effect - matches image description
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .onTapGesture {
                    onDismiss()
                }
                .lookinName("product.add-modal.backdrop")
            
            // Modal Container - matches image: white rounded rectangle, centered, floating
            VStack(spacing: 0) {
                // Modal Header - matches image: title in top-left, close button in top-right
                ZStack(alignment: .topTrailing) {
                    // Title and Subtitle Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("添加护肤产品")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                            .padding(.top, 24)
                            .padding(.leading, 24)
                        
                        Text("上传产品图片，AI将自动识别产品成分并进行分析")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.400, green: 0.400, blue: 0.400))
                            .padding(.leading, 24)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Close Button - matches image: circular, light grey background, X icon
                    Button(action: {
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.400, green: 0.400, blue: 0.400))
                            .frame(width: 32, height: 32)
                            .background(Color(red: 0.961, green: 0.961, blue: 0.969))
                            .clipShape(Circle())
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                    .lookinName("product.add-modal.close")
                }
                .lookinName("product.add-modal.header")
                
                // Modal Content - matches image: image upload area with dashed border
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Error Message
                            if hasError, let error = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 16))
                                    Text(error)
                                        .font(.system(size: 14))
                                        .lineLimit(3)
                                }
                                .foregroundColor(Color(red: 0.827, green: 0.157, blue: 0.129))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(red: 1.0, green: 0.922, blue: 0.933))
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                                .lookinName("product.add-modal.error")
                            }
                            
                            // Image Upload Area - matches image: dashed border, green icon
                            ImageUploader(
                                selectedImage: $selectedImage,
                                placeholder: "点击选择产品图片"
                            )
                            .padding(.horizontal, 24)
                            .id("imageUploader")
                            
                            // Progress Steps
                            if showProgressSteps {
                                VStack(spacing: 16) {
                                    ProgressStepRow(
                                        step: 1,
                                        title: "创建产品",
                                        description: stepStatus["create"] ?? "等待创建",
                                        isActive: currentStep >= 1,
                                        isComplete: currentStep > 1
                                    )
                                    
                                    ProgressStepRow(
                                        step: 2,
                                        title: "上传图片",
                                        description: stepStatus["upload"] ?? "等待上传",
                                        isActive: currentStep >= 2,
                                        isComplete: currentStep > 2
                                    )
                                    
                                    ProgressStepRow(
                                        step: 3,
                                        title: "提取成分",
                                        description: stepStatus["extract"] ?? "等待提取",
                                        isActive: currentStep >= 3,
                                        isComplete: currentStep > 3
                                    )
                                    
                                    ProgressStepRow(
                                        step: 4,
                                        title: "分析成分",
                                        description: stepStatus["analyze"] ?? "等待分析",
                                        isActive: currentStep >= 4,
                                        isComplete: currentStep > 4
                                    )
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.6))
                                .cornerRadius(16)
                                .padding(.horizontal, 24)
                                .id("progressSteps")
                                .lookinName("product.add-modal.progress")
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .onChange(of: showProgressSteps) { newValue in
                        if newValue {
                            // 当显示进度步骤时，延迟滚动以确保视图已更新
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo("progressSteps", anchor: .top)
                                }
                            }
                        }
                    }
                    .lookinName("product.add-modal.content-scroll")
                }
                
                // Modal Footer - matches image: gradient button at bottom
                VStack(spacing: 0) {
                    Button(action: {
                        submitProduct()
                    }) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text(submitButtonText)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.604, blue: 0.620),
                                    Color(red: 0.996, green: 0.812, blue: 0.937)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(red: 1.0, green: 0.604, blue: 0.620).opacity(0.4), radius: 15, x: 0, y: 4)
                    }
                    .disabled(!canSubmit || isLoading || isExtracting || isAnalyzing)
                    .opacity((!canSubmit || isLoading || isExtracting || isAnalyzing) ? 0.7 : 1.0)
                    .lookinName("product.add-modal.submit")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .background(Color.white)
            }
            .frame(width: min(UIScreen.main.bounds.width * 0.85, 500))
            .frame(maxHeight: UIScreen.main.bounds.height * 0.48)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
            .lookinName("product.add-modal.container")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(9999)
        .allowsHitTesting(true)
        .lookinName("product.add-modal")
    }
    
    private func submitProduct() {
        guard canSubmit, let image = selectedImage else { return }
        
        print("\n===== 🚀 开始产品提交流程 ======")
        
        isLoading = true
        hasError = false
        errorMessage = nil
        showProgressSteps = true
        currentStep = 1
        
        Task {
            stepStatus["create"] = "创建中..."
            let productID = await store.addProduct(from: image)

            switch store.addStep {
            case .completed:
                stepStatus["create"] = "创建成功"
                stepStatus["upload"] = "上传成功"
                stepStatus["extract"] = "提取成功"
                stepStatus["analyze"] = "分析成功"
                currentStep = 5
                isLoading = false
                isExtracting = false
                isAnalyzing = false
                onProductAdded(productID)
            default:
                hasError = true
                errorMessage = store.addError ?? "产品处理失败，请重试"
                isLoading = false
                isExtracting = false
                isAnalyzing = false
                stepStatus[stepKey(for: currentStep)] = "处理失败"
            }
        }
    }

    private func stepKey(for step: Int) -> String {
        switch step {
        case 2: return "upload"
        case 3: return "extract"
        case 4: return "analyze"
        default: return "create"
        }
    }
}

struct ProgressStepRow: View {
    let step: Int
    let title: String
    let description: String
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step Number Circle - matches Vue .step-number
            ZStack {
                Circle()
                    .fill(stepNumberBackground)
                    .frame(width: 28, height: 28)
                
                Text("\(step)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(stepNumberTextColor)
            }
            
            // Step Content - matches Vue .step-content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
            }
            
            Spacer()
        }
        .opacity(isActive || isComplete ? 1.0 : 0.5)
        .lookinName("product.add-modal.progress-step.\(step)")
    }
    
    private var stepNumberBackground: LinearGradient {
        if isComplete {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.659, green: 0.929, blue: 0.918),
                    Color(red: 0.996, green: 0.839, blue: 0.886)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isActive {
            return LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.604, blue: 0.620),
                                Color(red: 0.996, green: 0.812, blue: 0.937)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.878, green: 0.878, blue: 0.878),
                    Color(red: 0.878, green: 0.878, blue: 0.878)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var stepNumberTextColor: Color {
        (isActive || isComplete) ? .white : Color(red: 0.459, green: 0.459, blue: 0.459)
    }
}
