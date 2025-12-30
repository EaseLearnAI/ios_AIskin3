//
//  SkinStatusView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI
import PhotosUI

struct SkinStatusView: View {
    @Binding var selectedTab: Int
    
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var showResults = false
    @State private var showHistoryModal = false
    @State private var progress: Double = 0
    @State private var analysisStatus = "正在上传图片到云端..."
    @State private var errorMessage: String?
    
    init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }
    
    // Analysis result
    @State private var analysisResult: AnalysisResult?
    
    // History data
    @State private var hasHistoryResults = false
    @State private var lastAnalysisDate: Date?
    @State private var lastAnalysisResult: AnalysisResult?
    @State private var historyList: [AnalysisResult] = []
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .sheet(isPresented: $showPhotoPicker) {
            SkinAnalysisImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            SkinAnalysisImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .overlay(analyzingOverlay)
        .overlay(historyModalOverlay)
        .overlay(errorToastOverlay)
        .onAppear {
            loadHistoryData()
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let newImage = newValue {
                print("📷 图片已选择，尺寸: \(newImage.size.width)x\(newImage.size.height)")
                processImageFile(newImage)
            }
        }
    }
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.996, green: 0.969, blue: 0.941),
                Color(red: 0.941, green: 0.973, blue: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                mainContentView
            }
        }
    }
    
    private var headerView: some View {
        SkinAnalysisHeader(
            onShowHistory: {
                showHistoryModal = true
            },
            onBack: {
                // Return to welcome view (reset to initial state)
                resetAnalysis()
            }
        )
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        VStack(spacing: 16) {
            if !showResults {
                welcomeContentView
            } else if let result = analysisResult {
                resultsContentView(result: result)
            } else {
                // 如果showResults为true但没有结果，显示错误提示
                VStack {
                    Text("分析结果加载中...")
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
        .padding(.horizontal, 8)
        .onChange(of: showResults) { oldValue, newValue in
            print("🔄 showResults 状态变化: \(oldValue) -> \(newValue)")
            if newValue {
                print("📊 当前 analysisResult: \(analysisResult != nil ? "有数据" : "无数据")")
                if let result = analysisResult {
                    print("   - 健康评分: \(result.healthScore)")
                    print("   - 皮肤类型: \(result.skinType?.type ?? "未知")")
                }
            }
        }
        .onChange(of: analysisResult) { oldValue, newValue in
            let oldStatus = oldValue != nil ? "有数据" : "无数据"
            let newStatus = newValue != nil ? "有数据" : "无数据"
            if oldStatus != newStatus {
                print("🔄 analysisResult 状态变化: \(oldStatus) -> \(newStatus)")
            }
        }
    }
    
    @ViewBuilder
    private var welcomeContentView: some View {
        SkinDetectionWelcome(
            onTakePhoto: { showCamera = true },
            onSelectPhoto: { showPhotoPicker = true }
        )
        .padding(.horizontal, 8)
        .padding(.top, 16)
        
        if hasHistoryResults {
            HistorySection(
                lastAnalysisResult: lastAnalysisResult,
                lastAnalysisDate: lastAnalysisDate,
                onShowHistory: {
                    if let result = lastAnalysisResult {
                        analysisResult = result
                        showResults = true
                    }
                },
                onStartNewAnalysis: { resetAnalysis() }
            )
            .padding(.horizontal, 8)
        }
    }
    
    private func resultsContentView(result: AnalysisResult) -> some View {
        VStack(spacing: 16) {
            HealthScoreCard(score: result.healthScore)
                .padding(.horizontal, 8)
                .padding(.top, 16)
            
            WeatherCard()
                .padding(.horizontal, 8)
            
            SkinTypeAnalysis(
                skinType: result.skinType ?? SkinTypeData(type: "混合偏油性皮肤", subtype: "混油性"),
                oilLevel: result.oilLevel ?? "偏高",
                moistureLevel: result.moistureLevel ?? "正常",
                poreLevel: result.poreLevel ?? "中等"
            )
            .padding(.horizontal, 8)
            
            SkinStatusOverview(
                blackheads: result.blackheads,
                acne: result.acne,
                pores: result.pores,
                skinToneEvenness: result.skinToneEvenness,
                redness: result.redness,
                hyperpigmentation: result.hyperpigmentation,
                fineLines: result.fineLines,
                sensitivity: result.sensitivity
            )
            .padding(.horizontal, 8)
            
            AIRecommendations(recommendations: result.recommendations ?? [])
                .padding(.horizontal, 8)
            
            actionButtonsView
            planButtonView
        }
        .padding(.bottom, 80)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button(action: restartAnalysis) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("重新检测")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.388, green: 0.388, blue: 0.976),
                            Color(red: 0.545, green: 0.298, blue: 0.965)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color(red: 0.388, green: 0.388, blue: 0.976).opacity(0.3), radius: 10, x: 0, y: 4)
            }
            
            Button(action: shareReport) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享报告")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.063, green: 0.722, blue: 0.506),
                            Color(red: 0.035, green: 0.604, blue: 0.424)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color(red: 0.063, green: 0.722, blue: 0.506).opacity(0.3), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var planButtonView: some View {
        NavigationLink(destination: Text("21天计划")) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                Text("查看21天护肤计划")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.388, green: 0.388, blue: 0.976),
                        Color(red: 0.545, green: 0.298, blue: 0.965)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color(red: 0.388, green: 0.388, blue: 0.976).opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var analyzingOverlay: some View {
        if isAnalyzing {
            AnalyzingModal(progress: progress, status: analysisStatus)
        }
    }
    
    @ViewBuilder
    private var historyModalOverlay: some View {
        if showHistoryModal {
            HistoryModal(
                isPresented: $showHistoryModal,
                historyList: historyList,
                onSelectHistory: { history in
                    analysisResult = history
                    showResults = true
                }
            )
        }
    }
    
    @ViewBuilder
    private var errorToastOverlay: some View {
        if let error = errorMessage {
            ErrorToast(message: error) {
                errorMessage = nil
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadHistoryData() {
        Task {
            do {
                print("📋 开始加载历史数据...")
                let (analyses, _) = try await SkinAnalysisApiService.shared.getAnalysisHistory(page: 1, limit: 10)
                
                if !analyses.isEmpty {
                    // 转换并设置最新分析
                    let latestAnalysis = analyses.first!
                    let latestResult = SkinAnalysisApiService.shared.convertToAnalysisResult(latestAnalysis)
                    
                    // 转换所有历史记录
                    let historyResults = analyses.map { analysis in
                        SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
                    }
                    
                    await MainActor.run {
                        self.historyList = historyResults
                        self.lastAnalysisResult = latestResult
                        self.lastAnalysisDate = latestResult.createdAt
                        self.hasHistoryResults = true
                        print("✅ 历史数据加载完成，共\(historyResults.count)条记录")
                    }
                } else {
                    await MainActor.run {
                        self.hasHistoryResults = false
                        print("ℹ️ 暂无历史记录")
                    }
                }
            } catch {
                print("❌ 加载历史数据失败: \(error.localizedDescription)")
                await MainActor.run {
                    self.hasHistoryResults = false
                }
            }
        }
    }
    
    private func processImageFile(_ image: UIImage) {
        print("🔄 开始处理图片文件...")
        // Validate image
        guard validateImageFile(image) else {
            print("❌ 图片验证失败")
            return
        }
        
        print("✅ 图片验证通过，开始分析")
        // Start analysis
        startAnalysis()
    }
    
    private func validateImageFile(_ image: UIImage) -> Bool {
        // Check image size (max 10MB)
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            let maxSize = 10 * 1024 * 1024
            if imageData.count > maxSize {
                showError("图片文件过大，请选择小于10MB的图片")
                return false
            }
        }
        return true
    }
    
    private func startAnalysis() {
        guard let image = selectedImage else {
            showError("未选择图片")
            return
        }
        
        isAnalyzing = true
        showResults = false
        progress = 0
        analysisStatus = "正在上传图片到云端..."
        
        // 模拟上传进度
        let uploadTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if progress < 30 {
                progress += 2
            } else {
                timer.invalidate()
            }
        }
        
        Task {
            do {
                // 调用真实API进行分析
                analysisStatus = "正在分析肌肤状况..."
                uploadTimer.invalidate()
                
                // 模拟分析进度
                let analysisTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
                    if progress < 90 {
                        progress += 5
                    } else {
                        timer.invalidate()
                    }
                }
                
                let analysis = try await SkinAnalysisApiService.shared.analyzeSkin(image: image)
                analysisTimer.invalidate()
                
                print("📊 收到分析结果，开始转换...")
                print("   - 分析ID: \(analysis.id)")
                print("   - 健康评分: \(analysis.overallAssessment?.healthScore ?? 0)")
                print("   - 皮肤类型: \(analysis.skinType?.type ?? "未知")")
                
                // 转换为UI需要的格式
                let result = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
                
                print("✅ 数据转换完成")
                print("   - 转换后健康评分: \(result.healthScore)")
                print("   - 转换后皮肤类型: \(result.skinType?.type ?? "未知")")
                print("   - 转换后建议数量: \(result.recommendations?.count ?? 0)")
                
                await MainActor.run {
                    progress = 100
                    analysisStatus = "分析完成！"
                    
                    print("🎨 准备更新UI...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("🎨 更新UI状态")
                        self.isAnalyzing = false
                        self.analysisResult = result
                        self.showResults = true
                        print("✅ UI已更新 - showResults: \(self.showResults), analysisResult: \(self.analysisResult != nil ? "有数据" : "无数据")")
                        self.loadHistoryData() // 重新加载历史
                    }
                }
            } catch {
                uploadTimer.invalidate()
                await MainActor.run {
                    self.isAnalyzing = false
                    self.showError("分析失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func resetAnalysis() {
        isAnalyzing = false
        showResults = false
        progress = 0
        selectedImage = nil
        analysisResult = nil
        errorMessage = nil
    }
    
    private func restartAnalysis() {
        resetAnalysis()
        showCamera = true
    }
    
    private func shareReport() {
        // Share functionality
        if let result = analysisResult {
            let text = "我的AI肌肤检测结果：健康评分\(result.healthScore)分！"
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            errorMessage = nil
        }
    }
}

struct ErrorToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: onDismiss) {
                HStack {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.863, green: 0.149, blue: 0.149))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(red: 1.0, green: 0.922, blue: 0.933))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 100)
    }
}

// Enhanced ImagePicker with source type support
struct SkinAnalysisImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.mediaTypes = ["public.image"]
        
        // 检查源类型是否可用
        if !UIImagePickerController.isSourceTypeAvailable(sourceType) {
            print("⚠️ 源类型不可用: \(sourceType == .camera ? "相机" : "相册")")
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SkinAnalysisImagePicker
        
        init(_ parent: SkinAnalysisImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            print("📷 图片选择器完成选择")
            if let uiImage = info[.originalImage] as? UIImage {
                print("✅ 成功获取图片，尺寸: \(uiImage.size.width)x\(uiImage.size.height)")
                self.parent.image = uiImage
            } else {
                print("❌ 无法从选择器获取图片")
            }
            picker.dismiss(animated: true) { [weak self] in
                self?.parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("❌ 用户取消了图片选择")
            picker.dismiss(animated: true) { [weak self] in
                self?.parent.dismiss()
            }
        }
    }
}
