//
//  CoreFeaturesView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct CoreFeaturesView: View {
    @Binding var selectedTab: Int
    @Binding var shouldEnableConflictMode: Bool
    @State private var showPersonalizedRoutineModal = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("核心功能")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.122, green: 0.161, blue: 0.227))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            // Features Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Feature 01: Product Analysis
                Button(action: {
                    selectedTab = 1
                }) {
                    FeatureCardView(
                        number: "01",
                        title: "产品分析",
                        description: "AI智能解析成分",
                        numberColor: Color(red: 0.992, green: 0.949, blue: 0.973),
                        onTap: {}
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Feature 02: Conflict Detection
                Button(action: {
                    shouldEnableConflictMode = true
                    selectedTab = 1
                }) {
                    FeatureCardView(
                        number: "02",
                        title: "冲突检测",
                        description: "避免产品成分冲突",
                        numberColor: Color(red: 0.980, green: 0.961, blue: 1.0),
                        onTap: {}
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Feature 03: Skin Analysis
                Button(action: {
                    selectedTab = 2
                }) {
                    FeatureCardView(
                        number: "03",
                        title: "肌肤检测",
                        description: "AI智能皮肤分析",
                        numberColor: Color(red: 0.937, green: 0.961, blue: 1.0),
                        onTap: {}
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Feature 04: Personalized Plan
                Button(action: {
                    showPersonalizedRoutineModal = true
                }) {
                    FeatureCardView(
                        number: "04",
                        title: "个性化方案",
                        description: "AI定制护肤方案",
                        numberColor: Color(red: 0.941, green: 0.992, blue: 0.961),
                        onTap: {}
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 0.953, green: 0.957, blue: 0.969), lineWidth: 1)
        )
        .sheet(isPresented: $showPersonalizedRoutineModal) {
            PersonalizedRoutineModalView()
        }
    }
}

struct FeatureCardView: View {
    let number: String
    let title: String
    let description: String
    let numberColor: Color
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
                // Decorative Number
                Text(number)
                    .font(.system(size: 96, weight: .bold))
                    .foregroundColor(numberColor)
                    .offset(x: 8, y: 8)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.067, green: 0.094, blue: 0.153))
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color(red: 0.980, green: 0.980, blue: 0.984)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.953, green: 0.957, blue: 0.969), lineWidth: 1)
            )
    }
}

struct PersonalizedRoutineModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var loadingPlan = false
    @State private var planError: String?
    @State private var generatedPlan: SkinPlan?
    @State private var isLoadingAnalysis = false
    
    // Input states
    @State private var userAge: String = ""
    @State private var selectedConcerns: Set<String> = []
    @State private var customRequirements: String = ""
    @State private var isInCycle = false
    @State private var cycleDay: String = "1"
    @State private var showCycleDetails = false
    
    // Skin analysis state
    @State private var latestSkinAnalysis: SkinAnalysisData?
    
    let skinConcerns: [(label: String, value: String, icon: String)] = [
        ("补水", "hydration", "drop.fill"),
        ("美白", "brightening", "sun.max.fill"),
        ("抗老", "anti-aging", "clock.fill"),
        ("控油", "oil-control", "oilcan.fill"),
        ("修护", "repair", "bandage.fill"),
        ("祛痘", "acne", "virus.fill")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if loadingPlan {
                        LoadingStateView()
                    } else if let error = planError {
                        PersonalizedErrorStateView(message: error)
                    } else if let plan = generatedPlan {
                        PersonalizedRoutinePreviewView(
                            plan: plan,
                            onSave: {
                                savePlanToRoutine(plan)
                            },
                            onCustomize: {
                                resetPlan()
                            }
                        )
                    } else {
                        InputStateView(
                            userAge: $userAge,
                            selectedConcerns: $selectedConcerns,
                            customRequirements: $customRequirements,
                            isInCycle: $isInCycle,
                            cycleDay: $cycleDay,
                            showCycleDetails: $showCycleDetails,
                            latestSkinAnalysis: latestSkinAnalysis,
                            skinConcerns: skinConcerns,
                            onGenerate: generatePersonalizedPlan
                        )
                    }
                }
                .padding(24)
            }
            .navigationTitle("个性化护肤方案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadLatestSkinAnalysis()
            }
        }
    }
    
    /// 加载最新的皮肤分析
    private func loadLatestSkinAnalysis() async {
        isLoadingAnalysis = true
        do {
            if let analysis = try await SkinAnalysisApiService.shared.getLatestAnalysis() {
                // 转换为 SkinAnalysisData 格式
                let skinType = analysis.skinType?.type ?? "未知"
                let healthScore = Int(analysis.overallAssessment?.healthScore ?? 0)
                let skinCondition = analysis.overallAssessment?.skinCondition ?? "未知"
                let createdAt = analysis.createdAt ?? Date()
                
                await MainActor.run {
                    self.latestSkinAnalysis = SkinAnalysisData(
                        skinType: skinType,
                        healthScore: healthScore,
                        skinCondition: skinCondition,
                        createdAt: createdAt
                    )
                }
            }
        } catch {
            print("⚠️ 获取最新皮肤分析失败: \(error.localizedDescription)")
            // 不显示错误，允许用户继续使用
        }
        isLoadingAnalysis = false
    }
    
    /// 生成个性化护肤方案
    private func generatePersonalizedPlan() {
        guard !userAge.isEmpty, !selectedConcerns.isEmpty else {
            planError = "请填写年龄并选择至少一个护肤需求"
            return
        }
        
        guard let age = Int(userAge), age > 0, age < 150 else {
            planError = "请输入有效的年龄"
            return
        }
        
        loadingPlan = true
        planError = nil
        
        Task {
            do {
                // 构建需求描述
                let concernLabels = selectedConcerns.map { concern in
                    skinConcerns.first(where: { $0.value == concern })?.label ?? concern
                }
                let requirement = concernLabels.joined(separator: "、")
                
                // 调用API生成方案
                let plan = try await PlanApiService.shared.createPlan(
                    requirement: requirement,
                    userAge: age,
                    skinConcerns: Array(selectedConcerns),
                    customRequirements: customRequirements.isEmpty ? nil : customRequirements
                )
                
                await MainActor.run {
                    self.generatedPlan = plan
                    self.loadingPlan = false
                }
            } catch {
                await MainActor.run {
                    self.planError = error.localizedDescription
                    self.loadingPlan = false
                }
            }
        }
    }
    
    private func resetPlan() {
        generatedPlan = nil
        selectedConcerns.removeAll()
        customRequirements = ""
    }
    
    /// 保存方案到我的方案
    private func savePlanToRoutine(_ plan: SkinPlan) {
        print("\n===== 💾 保存方案到我的方案 ======")
        print("📋 方案信息:")
        print("   - 方案ID: \(plan.id)")
        print("   - 方案名称: \(plan.name)")
        print("   - 早晨步骤数: \(plan.morning.count)")
        print("   - 晚间步骤数: \(plan.evening.count)")
        
        // 方案已经通过API生成并保存到后端，这里只需要通知刷新
        // 发送通知让 HomeView 刷新数据
        NotificationCenter.default.post(
            name: NSNotification.Name("PlanSaved"),
            object: nil,
            userInfo: ["planId": plan.id]
        )
        
        print("✅ 方案保存成功，已通知刷新")
        print("===== ✅ 保存完成 =====\n")
        
        dismiss()
    }
}

struct InputStateView: View {
    @Binding var userAge: String
    @Binding var selectedConcerns: Set<String>
    @Binding var customRequirements: String
    @Binding var isInCycle: Bool
    @Binding var cycleDay: String
    @Binding var showCycleDetails: Bool
    let latestSkinAnalysis: SkinAnalysisData?
    let skinConcerns: [(label: String, value: String, icon: String)]
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("请告诉我您的护肤需求，AI将结合您的个人信息和最新肌肤状态为您定制个性化护肤方案。")
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                .lineLimit(nil)
            
            // Age Input
            VStack(alignment: .leading, spacing: 12) {
                Text("年龄")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                
                TextField("请输入您的年龄", text: $userAge)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Skin Status Card
            if let analysis = latestSkinAnalysis {
                SkinStatusCardView(analysis: analysis)
            } else {
                NoAnalysisTipView()
            }
            
            // Menstrual Cycle (simplified)
            VStack(alignment: .leading, spacing: 12) {
                Text("生理周期状态")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                
                Toggle("当前处于生理周期", isOn: $isInCycle)
                    .tint(Color(red: 0.808, green: 0.576, blue: 0.847))
                
                if isInCycle {
                    HStack {
                        Text("周期第几天：")
                            .font(.system(size: 14))
                        TextField("1-7", text: $cycleDay)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                        Text("天")
                            .font(.system(size: 14))
                    }
                    .padding(12)
                    .background(Color(red: 0.973, green: 0.973, blue: 0.980))
                    .cornerRadius(8)
                }
            }
            
            // Skin Concerns
            VStack(alignment: .leading, spacing: 12) {
                Text("护肤需求")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(skinConcerns, id: \.value) { concern in
                        ConcernButton(
                            label: concern.label,
                            icon: concern.icon,
                            isSelected: selectedConcerns.contains(concern.value),
                            action: {
                                if selectedConcerns.contains(concern.value) {
                                    selectedConcerns.remove(concern.value)
                                } else {
                                    if selectedConcerns.count < 3 {
                                        selectedConcerns.insert(concern.value)
                                    }
                                }
                            }
                        )
                    }
                }
            }
            
            // Custom Requirements
            VStack(alignment: .leading, spacing: 12) {
                Text("其他需求")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                
                TextEditor(text: $customRequirements)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Generate Button
            Button(action: onGenerate) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("开始生成")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.612, green: 0.153, blue: 0.690),
                            Color(red: 0.404, green: 0.227, blue: 0.718)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color(red: 0.612, green: 0.153, blue: 0.690).opacity(0.3), radius: 10, x: 0, y: 4)
            }
            .disabled(userAge.isEmpty || selectedConcerns.isEmpty)
        }
    }
}

struct ConcernButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(
                isSelected ?
                Color(red: 0.612, green: 0.153, blue: 0.690) :
                Color(red: 0.420, green: 0.451, blue: 0.502)
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                Color(red: 0.953, green: 0.898, blue: 0.961) :
                Color(red: 0.973, green: 0.973, blue: 0.980)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ?
                        Color(red: 0.808, green: 0.576, blue: 0.847) :
                        Color(red: 0.914, green: 0.918, blue: 0.933),
                        lineWidth: 1
                    )
            )
        }
    }
}

struct SkinStatusCardView: View {
    let analysis: SkinAnalysisData
    
    var healthScoreColor: Color {
        let score = analysis.healthScore
        if score < 30 {
            return Color(red: 0.827, green: 0.157, blue: 0.129)
        } else if score < 60 {
            return Color(red: 0.957, green: 0.478, blue: 0.0)
        } else {
            return Color(red: 0.224, green: 0.557, blue: 0.235)
        }
    }
    
    var healthScoreBg: Color {
        let score = analysis.healthScore
        if score < 30 {
            return Color(red: 1.0, green: 0.922, blue: 0.933)
        } else if score < 60 {
            return Color(red: 1.0, green: 0.953, blue: 0.878)
        } else {
            return Color(red: 0.910, green: 0.980, blue: 0.910)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最新肌肤状态")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
            
            VStack(spacing: 12) {
                HStack {
                    Text(analysis.skinType)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.294, green: 0.318, blue: 0.341))
                    
                    Spacer()
                    
                    Text("\(analysis.healthScore)/100")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(healthScoreColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(healthScoreBg)
                        .cornerRadius(12)
                }
                
                Text(analysis.skinCondition)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.424, green: 0.451, blue: 0.494))
                
                Text("分析时间：\(formatDate(analysis.createdAt))")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.678, green: 0.710, blue: 0.741))
            }
            .padding(16)
            .background(Color(red: 0.973, green: 0.973, blue: 0.980))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.914, green: 0.918, blue: 0.933), lineWidth: 1)
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

struct NoAnalysisTipView: View {
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color(red: 0.098, green: 0.463, blue: 0.824))
            Text("暂无肌肤分析数据，建议先进行肌肤检测获得更精准的护肤方案")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.098, green: 0.463, blue: 0.824))
            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.890, green: 0.949, blue: 0.992))
        .cornerRadius(10)
    }
}

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(red: 0.612, green: 0.153, blue: 0.690))
            
            Text("AI正在为您定制专属护肤方案...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

struct PersonalizedErrorStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(red: 0.827, green: 0.157, blue: 0.129))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.827, green: 0.157, blue: 0.129))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color(red: 1.0, green: 0.922, blue: 0.933))
        .cornerRadius(12)
    }
}

// Supporting Models
struct SkinAnalysisData {
    let skinType: String
    let healthScore: Int
    let skinCondition: String
    let createdAt: Date
}

// Extension to make SkinPlan work with our preview
extension SkinPlan {
    static var mock: SkinPlan {
        SkinPlan(
            id: UUID().uuidString,
            name: "个性化护肤方案",
            tags: ["补水", "美白"],
            creatorNote: "日常基础护肤",
            notes: nil,
            morning: [
                RoutineItem(step: 1, product: "温和洁面", reason: "清洁肌肤", done: nil, completed: nil),
                RoutineItem(step: 2, product: "精华液", reason: "补充营养", done: nil, completed: nil)
            ],
            evening: [
                RoutineItem(step: 1, product: "卸妆", reason: "彻底清洁", done: nil, completed: nil),
                RoutineItem(step: 2, product: "精华", reason: "夜间修护", done: nil, completed: nil)
            ],
            recommendations: ["建议每天早晚使用", "坚持使用21天可看到明显效果"],
            createdAt: Date(),
            createdByName: nil,
            origin: nil
        )
    }
}

