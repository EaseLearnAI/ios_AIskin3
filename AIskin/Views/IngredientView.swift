//
//  IngredientView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct IngredientView: View {
    let productId: String
    @Environment(\.dismiss) var dismiss
    @State private var product: Product?
    @State private var analysis: IngredientAnalysis?
    @State private var loading = true
    @State private var errorMessage: String?
    @State private var showTagModal = false
    @State private var showDeleteModal = false
    
    var body: some View {
        ZStack {
            Color(red: 0.973, green: 0.973, blue: 0.980)
                .ignoresSafeArea()
            
            if loading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ErrorStateView(message: error) {
                    loadData()
                }
            } else if let product = product, let analysis = analysis {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        AppHeader(
                            title: "成分分析",
                            rightIcon: "square.and.arrow.up",
                            backAction: { dismiss() }
                        )
                        
                        // Product Info
                        ProductInfo(product: product)
                            .padding(.horizontal, 20)
                        
                        // Analysis Overview
                        AnalysisOverview(analysis: analysis)
                            .padding(.horizontal, 20)
                        
                        // Analysis Summary
                        AnalysisSummary(analysis: analysis)
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
                .overlay(
                    // Action Buttons
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: { showTagModal = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("保存分析结果")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.298, green: 0.686, blue: 0.314),
                                            Color(red: 0.255, green: 0.588, blue: 0.271)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            
                            Button(action: { showDeleteModal = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("删除")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(red: 1.0, green: 0.878, blue: 0.878))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .background(Color.white.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2))
                    }
                    .edgesIgnoringSafeArea(.bottom),
                    alignment: .bottom
                )
                .sheet(isPresented: $showTagModal) {
                    TagSelectorModal(product: product) {
                        showTagModal = false
                        // 保存成功后，延迟关闭整个IngredientView并返回产品分析页面
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                }
                .alert("确认删除", isPresented: $showDeleteModal) {
                    Button("取消", role: .cancel) {}
                    Button("确认删除", role: .destructive) {
                        deleteProduct()
                    }
                } message: {
                    Text("确定要删除这个分析结果吗？此操作无法撤销。")
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        print("\n===== 📋 加载产品成分分析 ======")
        print("📊 产品ID: \(productId)")
        
        loading = true
        errorMessage = nil
        
        Task {
            do {
                // Step 1: Get product details first
                print("\n📦 步骤1: 获取产品详情")
                let productData = try await ProductApiService.shared.getProduct(productId: productId)
                
                print("✅ 产品信息加载成功")
                print("   - 产品名称: \(productData.name)")
                print("   - 产品描述: \(productData.description ?? "无")")
                print("   - 产品标签: \(productData.label ?? "未设置")")
                print("   - 成分数量: \(productData.ingredients.count)")
                print("   - 图片URL: \(productData.imageUrl ?? "无")")
                
                await MainActor.run {
                    self.product = productData
                }
                
                // Step 2: Try to get ingredient analysis
                print("\n🧪 步骤2: 获取成分分析结果")
                do {
                    let (_, analysisData) = try await IngredientAnalysisApiService.shared.getIngredientAnalysis(productId: productId)
                    
                    print("✅ 成分分析加载成功")
                    print("   - 安全性指数: \(analysisData.safetyIndex)")
                    print("   - 功效评分: \(analysisData.efficacyScore)")
                    print("   - 活性成分数: \(analysisData.activeIngredients)")
                    print("   - 整体评级: \(analysisData.overallRating)/5.0")
                    print("   - 痘痘风险: \(analysisData.acneRisk.level) (\(analysisData.acneRisk.percentage)%)")
                    print("   - 刺激风险: \(analysisData.irritationRisk.level) (\(analysisData.irritationRisk.percentage)%)")
                    print("   - 过敏风险: \(analysisData.allergyRisk.level) (\(analysisData.allergyRisk.percentage)%)")
                    
                    await MainActor.run {
                        self.analysis = analysisData
                        self.loading = false
                    }
                } catch {
                    // If analysis doesn't exist, check if we can analyze
                    print("⚠️ 成分分析不存在，检查是否可以分析")
                    print("   - 错误信息: \(error.localizedDescription)")
                    
                    // If product has ingredients, try to analyze
                    if !productData.ingredients.isEmpty {
                        print("📊 产品有成分列表，尝试进行分析...")
                        do {
                            let analysisData = try await IngredientAnalysisApiService.shared.analyzeIngredients(productId: productId)
                            
                            print("✅ 成分分析成功")
                            print("   - 安全性指数: \(analysisData.safetyIndex)")
                            print("   - 功效评分: \(analysisData.efficacyScore)")
                            print("   - 整体评级: \(analysisData.overallRating)/5.0")
                            
                            await MainActor.run {
                                self.analysis = analysisData
                                self.loading = false
                            }
                        } catch {
                            print("❌ 成分分析失败: \(error.localizedDescription)")
                            await MainActor.run {
                                self.errorMessage = "产品成分分析失败: \(error.localizedDescription)"
                                self.loading = false
                            }
                        }
                    } else {
                        print("⚠️ 产品没有成分列表，无法进行分析")
                        await MainActor.run {
                            self.errorMessage = "产品尚未提取成分，请先上传图片并提取成分"
                            self.loading = false
                        }
                    }
                }
                
            } catch {
                print("❌ 加载产品信息失败: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.errorMessage = "加载产品信息失败: \(error.localizedDescription)"
            self.loading = false
                }
            }
        }
    }
    
    private func deleteProduct() {
        print("\n===== 🗑️ 删除产品 ======")
        print("📊 产品ID: \(productId)")
        
        Task {
            do {
                try await ProductApiService.shared.deleteProduct(productId: productId)
                print("✅ 产品删除成功")
                
                await MainActor.run {
        dismiss()
                }
            } catch {
                print("❌ 删除产品失败: \(error.localizedDescription)")
                
                await MainActor.run {
                    errorMessage = "删除产品失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                Text("重试")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.972, green: 0.733, blue: 0.816),
                                Color(red: 0.882, green: 0.745, blue: 0.906)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
        }
        .padding(40)
    }
}


struct TagSelectorModal: View {
    let product: Product
    let onDismiss: () -> Void
    @State private var selectedTag: String = ""
    @State private var openingDate: Date
    @State private var isSaving = false
    
    // 获取可用的标签列表（排除"全部产品"）
    private let availableTags = ProductCategory.defaultCategories.filter { $0.id != "all" }
    
    init(product: Product, onDismiss: @escaping () -> Void) {
        self.product = product
        self.onDismiss = onDismiss
        _selectedTag = State(initialValue: product.label ?? "")
        _openingDate = State(initialValue: product.openingDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标签选择区域
                VStack(alignment: .leading, spacing: 16) {
                    Text("选择产品标签")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // 标签网格
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(availableTags, id: \.id) { category in
                                CategoryTagButton(
                                    category: category,
                                    isSelected: selectedTag == category.id,
                                    action: {
                                        selectedTag = category.id
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
                
                Divider()
                
                // 开封日期选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("开封日期")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    DatePicker("", selection: $openingDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                
                Spacer()
                
                // 底部按钮
                HStack(spacing: 12) {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("取消")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(red: 0.961, green: 0.961, blue: 0.969))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        saveProductTag()
                    }) {
                        Text("保存")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.298, green: 0.686, blue: 0.314),
                                        Color(red: 0.255, green: 0.588, blue: 0.271)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.7 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(Color.white)
            }
            .background(Color(red: 0.973, green: 0.973, blue: 0.980))
            .navigationTitle("保存分析结果")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveProductTag() {
        print("\n===== 💾 保存产品标签 ======")
        print("📊 产品ID: \(product.id)")
        print("   - 选择的标签: \(selectedTag)")
        print("   - 开封日期: \(openingDate)")
        
        isSaving = true
        
        Task {
            do {
                let updatedProduct = try await ProductApiService.shared.updateProduct(
                    productId: product.id,
                    name: nil,
                    description: nil,
                    label: selectedTag.isEmpty ? nil : selectedTag
                )
                
                print("✅ 产品标签保存成功")
                
                await MainActor.run {
                    isSaving = false
                    // 调用onDismiss回调，父视图会处理关闭逻辑
                    onDismiss()
                }
            } catch {
                print("❌ 保存产品标签失败: \(error.localizedDescription)")
                
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// 标签按钮组件（用于产品分类选择）
struct CategoryTagButton: View {
    let category: ProductCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : (category.color ?? Color(red: 0.459, green: 0.459, blue: 0.459)))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isSelected 
                        ? (category.color ?? Color(red: 0.298, green: 0.686, blue: 0.314))
                        : Color.white
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected 
                                ? (category.color ?? Color(red: 0.298, green: 0.686, blue: 0.314))
                                : Color(red: 0.898, green: 0.898, blue: 0.898),
                            lineWidth: isSelected ? 0 : 1
                        )
                )
                .cornerRadius(12)
                .shadow(
                    color: isSelected 
                        ? (category.color ?? Color(red: 0.298, green: 0.686, blue: 0.314)).opacity(0.3)
                        : Color.clear,
                    radius: isSelected ? 8 : 0,
                    x: 0,
                    y: isSelected ? 4 : 0
                )
        }
    }
}

