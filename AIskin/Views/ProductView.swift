//
//  ProductView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ProductView: View {
    var initialConflictMode: Bool = false
    @State private var products: [Product] = []
    @State private var showAddModal = false
    @State private var conflictMode = false
    @State private var selectedProductIds: Set<String> = []
    @State private var selectedCategory: String = "all"
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
                // Header
                AppHeader(
                    title: "护肤产品库",
                    icon: "pawprint.fill"
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Add Product Card
                        AddProduct(
                            showUploadModal: $showAddModal,
                            onEnableConflictMode: {
                                conflictMode = true
                                selectedProductIds.removeAll()
                            }
                        )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Conflict Mode Header
                        if conflictMode {
                            ConflictModeHeader(
                                selectedCount: selectedProductIds.count,
                                onAnalyze: {
                                    // Navigate to conflict analysis
                                    if selectedProductIds.count >= 2 {
                                        analyzeConflict()
                                    }
                                },
                                onCancel: {
                                    conflictMode = false
                                    selectedProductIds.removeAll()
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Product List
                        ProductList(
                            products: products,
                            categories: ProductCategory.defaultCategories,
                            selectedCategory: $selectedCategory,
                            selectionMode: $conflictMode,
                            selectedProductIds: $selectedProductIds,
                            onProductSelected: { product in
                                showIngredientViewForProduct = product.id
                            },
                            onToggleSelection: { productId in
                                if selectedProductIds.contains(productId) {
                                    selectedProductIds.remove(productId)
                                            } else {
                                    selectedProductIds.insert(productId)
                                }
                            },
                            onDeleteProduct: { productId in
                                deleteProduct(productId: productId)
                            }
                        )
                        .padding(.bottom, 80)
                    }
                }
            }
        }
        .overlay {
            if showAddModal {
                AddProductModal(
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
                        loadProducts()
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
                    loadProducts()
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
                    let oldConflictMode = conflictMode
                    let oldSelectedCount = selectedProductIds.count
                    let oldConflictIdsCount = conflictProductIds.count
                    
                    showConflictView = false
                    conflictMode = false
                    selectedProductIds.removeAll()
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
                        print("   - conflictMode当前值: \(conflictMode)")
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
                conflictMode = true
                selectedProductIds.removeAll()
            }
            
            print("============================================================\n")
            loadProducts()
        }
        .onDisappear {
            print("\n============================================================")
            print("📱 ProductView: onDisappear被调用")
            print("============================================================\n")
            print("⚠️ ProductView已隐藏")
            print("============================================================\n")
        }
    }
    
    private func loadProducts() {
        print("\n===== 📚 加载用户产品列表 ======")
        
        guard let userId = AuthService.shared.currentUser?.id else {
            print("❌ 错误: 未找到当前用户ID")
            return
        }
        
        print("📊 用户ID: \(userId)")
        
        Task {
            do {
                let userProducts = try await ProductApiService.shared.getUserProducts(userId: userId)
                
                await MainActor.run {
                    self.products = userProducts
                    print("✅ 产品列表加载成功，共\(userProducts.count)个产品")
                }
            } catch {
                print("❌ 加载产品列表失败: \(error.localizedDescription)")
                await MainActor.run {
                    // 保持空列表，显示空状态
                    self.products = []
                }
            }
        }
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
    
    private func deleteProduct(productId: String) {
        print("\n===== 🗑️ 删除产品 ======")
        print("📊 产品ID: \(productId)")
        
        Task {
            do {
                try await ProductApiService.shared.deleteProduct(productId: productId)
                print("✅ 产品删除成功")
                
                await MainActor.run {
                    products.removeAll { $0.id == productId }
                }
            } catch {
                print("❌ 删除产品失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func analyzeConflict() {
        print("\n============================================================")
        print("🔘 ProductView: 用户点击'分析冲突'按钮")
        print("============================================================\n")
        
        guard selectedProductIds.count >= 2 else {
            print("❌ 错误: 至少需要选择2个产品")
            print("📊 当前选择的产品数量: \(selectedProductIds.count)")
            return
        }
        
        let productIdsArray = Array(selectedProductIds)
        print("📊 准备分析的产品列表:")
        for (index, productId) in productIdsArray.enumerated() {
            print("   \(index + 1). 产品ID: \(productId)")
        }
        
        print("\n📱 步骤1: 立即显示ConflictView（显示加载动画）")
        print("   - 设置conflictProductIds: \(productIdsArray)")
        print("   - 设置showConflictView = true")
        
        // 立即显示ConflictView，让加载动画立即出现
        conflictProductIds = productIdsArray
        conflictMode = false
        selectedProductIds.removeAll()
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
    }
}

struct AddProductModal: View {
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
                }
                
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(9999)
        .allowsHitTesting(true)
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
            do {
                // Step 1: Create product
                await MainActor.run {
                    stepStatus["create"] = "创建中..."
                }
                
                print("📦 步骤1: 创建产品")
                let product = try await ProductApiService.shared.createProduct(
                    name: "未命名产品",
                    description: "这是一个用于成分分析的产品",
                    label: nil,
                    openingDate: nil
                )
                
                let productId = product.id
                print("✅ 产品创建成功，产品ID: \(productId)")
                
                await MainActor.run {
                    stepStatus["create"] = "创建成功"
                    currentStep = 2
                    stepStatus["upload"] = "上传中..."
                }
                
                // Step 2: Upload product image
                print("📷 步骤2: 上传产品图片")
                let imageUrl = try await ProductApiService.shared.uploadProductImage(
                    productId: productId,
                    image: image
                )
                print("✅ 图片上传成功，图片URL: \(imageUrl)")
                
                await MainActor.run {
                    stepStatus["upload"] = "上传成功"
                    currentStep = 3
                    isExtracting = true
                    stepStatus["extract"] = "提取中..."
                }
                
                // Step 3: Extract ingredients
                print("🔬 步骤3: 提取产品成分")
                let (extractedName, ingredients) = try await ProductApiService.shared.extractIngredients(productId: productId)
                print("✅ 成分提取成功")
                print("   - 产品名称: \(extractedName)")
                print("   - 成分数量: \(ingredients.count)")
                print("   - 成分列表: \(ingredients.joined(separator: ", "))")
                
                await MainActor.run {
                    isExtracting = false
                    stepStatus["extract"] = "提取成功，识别到\(ingredients.count)种成分"
                    currentStep = 4
                    isAnalyzing = true
                    stepStatus["analyze"] = "分析中..."
                }
                
                // Step 4: Analyze ingredients
                print("🧪 步骤4: 分析产品成分")
                let analysis = try await IngredientAnalysisApiService.shared.analyzeIngredients(productId: productId)
                print("✅ 成分分析成功")
                print("   - 安全性指数: \(analysis.safetyIndex)")
                print("   - 功效评分: \(analysis.efficacyScore)")
                print("   - 整体评级: \(analysis.overallRating)/5.0")
                
                await MainActor.run {
                    isAnalyzing = false
                    stepStatus["analyze"] = "分析成功"
                    currentStep = 5
                    isLoading = false
                }
                
                print("🎉 产品提交流程完成！")
                
                // Notify parent to reload products list
                await MainActor.run {
                    onProductAdded(productId)
                }
                
            } catch {
                print("❌ 产品提交失败: \(error.localizedDescription)")
                
                await MainActor.run {
                    hasError = true
                    errorMessage = error.localizedDescription
                    isLoading = false
                    isExtracting = false
                    isAnalyzing = false
                    
                    // Update step status based on error
                    if currentStep == 1 {
                        stepStatus["create"] = "创建失败"
                    } else if currentStep == 2 {
                        stepStatus["upload"] = "上传失败"
                    } else if currentStep == 3 {
                        stepStatus["extract"] = "提取失败"
                    } else if currentStep == 4 {
                        stepStatus["analyze"] = "分析失败"
                    }
                }
            }
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
