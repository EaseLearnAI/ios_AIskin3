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
    @StateObject private var store = SkinAnalysisStore()
    
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    
    init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .sheet(isPresented: $showPhotoPicker) {
            SkinAnalysisImagePicker(image: $store.selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            SkinAnalysisImagePicker(image: $store.selectedImage, sourceType: .camera)
        }
        .overlay(analyzingOverlay)
        .overlay(historyModalOverlay)
        .overlay(errorToastOverlay)
        .task {
            await store.loadHistory()
        }
        .onChange(of: store.selectedImage) { oldValue, newValue in
            if let newImage = newValue {
                print("📷 图片已选择，尺寸: \(newImage.size.width)x\(newImage.size.height)")
                store.processSelectedImage()
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
                mainContentView
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        VStack(spacing: 16) {
            skinActionsView

            switch store.flow {
            case .welcome, .analyzing, .failed:
                welcomeContentView
            case let .result(result):
                resultsContentView(result: result)
            }
        }
        .padding(.horizontal, 8)
    }

    private var skinActionsView: some View {
        HStack(spacing: 12) {
            if case .result = store.flow {
                Button(action: store.reset) {
                    Label("重新检测", systemImage: "arrow.counterclockwise")
                }
            }

            Spacer()

            Button {
                store.isHistoryPresented = true
            } label: {
                Label("历史记录", systemImage: "clock")
            }
        }
        .font(AISkinTypography.callout)
        .foregroundStyle(AISkinColor.brand)
        .frame(minHeight: 44)
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private var welcomeContentView: some View {
        SkinDetectionWelcome(
            onTakePhoto: { showCamera = true },
            onSelectPhoto: { showPhotoPicker = true }
        )
        .padding(.horizontal, 8)
        .padding(.top, 16)
        
        if store.hasHistory {
            HistorySection(
                lastAnalysisResult: store.lastResult,
                lastAnalysisDate: store.lastResult?.createdAt,
                onShowHistory: {
                    if let result = store.lastResult {
                        store.selectHistory(result)
                    }
                },
                onStartNewAnalysis: { store.reset() }
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
        if case let .analyzing(progress, status) = store.flow {
            AnalyzingModal(progress: progress, status: status)
        }
    }
    
    @ViewBuilder
    private var historyModalOverlay: some View {
        if store.isHistoryPresented {
            HistoryModal(
                isPresented: $store.isHistoryPresented,
                historyList: store.history,
                onSelectHistory: { history in
                    store.selectHistory(history)
                }
            )
        }
    }
    
    @ViewBuilder
    private var errorToastOverlay: some View {
        if case let .failed(error) = store.flow {
            ErrorToast(message: error) {
                store.dismissError()
            }
        }
    }
    
    // MARK: - Methods
    
    private func restartAnalysis() {
        store.reset()
        showCamera = true
    }
    
    private func shareReport() {
        // Share functionality
        if let result = store.result {
            let text = "我的AI肌肤检测结果：健康评分\(result.healthScore)分！"
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
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
