//
//  HomeView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @Binding var shouldEnableConflictMode: Bool
    @State private var morningRoutine: [RoutineItem] = []
    @State private var eveningRoutine: [RoutineItem] = []
    @State private var recommendations: [String] = []
    @State private var loading = true
    @State private var hasPlan = false
    @State private var planId = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1.0, green: 0.976, blue: 0.984)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        AppHeader(
                            title: "析肤护肤助手",
                            icon: "pawprint.fill",
                            rightIcon: "bell.fill"
                        )
                        
                        // Main Content
                        VStack(spacing: 16) {
                            // Core Features
                            CoreFeaturesView(selectedTab: $selectedTab, shouldEnableConflictMode: $shouldEnableConflictMode)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            
                            // 21 Day Plan Card
                            NavigationLink(destination: Text("21天计划页面")) {
                                TwentyOneDayPlanCardView()
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 16)
                            
                            // Daily Routine
                            if loading {
                                ProgressView()
                                    .padding(.top, 40)
                            } else if hasPlan {
                                DailyRoutineView(
                                    planId: planId,
                                    morningRoutine: $morningRoutine,
                                    eveningRoutine: $eveningRoutine,
                                    recommendations: $recommendations,
                                    onSaveRoutine: {
                                        saveRoutineToStorage()
                                    },
                                    onAutoCheckin: {
                                        handleAutoCheckin()
                                    }
                                )
                                .padding(.horizontal, 16)
                            } else {
                                Text("暂无护肤计划")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            fetchRoutine()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PlanSaved"))) { notification in
            // 当方案保存后，刷新数据
            print("\n📢 收到方案保存通知，刷新数据...")
            fetchRoutine()
        }
    }
    
    /// 从API获取最新的护肤方案
    private func fetchRoutine() {
        print("\n===== 📥 获取用户护肤方案 ======")
        loading = true
        
        Task {
            do {
                print("📡 发起API请求: GET /api/plans")
                
                // 获取用户的所有方案列表
                let plans = try await PlanApiService.shared.getUserPlans()
                
                print("✅ API响应成功")
                print("📦 返回数据:")
                print("   - 方案总数: \(plans.count)")
                
                if let latestPlan = plans.first {
                    print("   - 最新方案ID: \(latestPlan.id)")
                    print("   - 最新方案名称: \(latestPlan.name)")
                    print("   - 早晨步骤数: \(latestPlan.morning.count)")
                    print("   - 晚间步骤数: \(latestPlan.evening.count)")
                    
                    // 获取方案详情（包含完整的步骤信息）
                    print("\n📡 获取方案详情: GET /api/plans/\(latestPlan.id)")
                    let planDetail = try await PlanApiService.shared.getPlan(planId: latestPlan.id)
                    
                    print("✅ 方案详情获取成功")
                    print("📦 方案详情:")
                    print("   - 方案ID: \(planDetail.id)")
                    print("   - 方案名称: \(planDetail.name)")
                    print("   - 早晨步骤:")
                    for (index, step) in planDetail.morning.enumerated() {
                        print("     \(index + 1). \(step.product ?? "未知产品") - \(step.completed == true ? "✅" : "⭕")")
                    }
                    print("   - 晚间步骤:")
                    for (index, step) in planDetail.evening.enumerated() {
                        print("     \(index + 1). \(step.product ?? "未知产品") - \(step.completed == true ? "✅" : "⭕")")
                    }
                    print("   - 推荐建议数: \(planDetail.recommendations.count)")
                    
                    await MainActor.run {
                        self.planId = planDetail.id
                        self.morningRoutine = planDetail.morning
                        self.eveningRoutine = planDetail.evening
                        self.recommendations = planDetail.recommendations
                        self.hasPlan = true
                        self.loading = false
                    }
                    
                    print("✅ UI已更新")
                } else {
                    print("⚠️ 用户暂无护肤方案")
                    await MainActor.run {
                        self.hasPlan = false
                        self.loading = false
                    }
                }
                
                print("===== ✅ 获取完成 =====\n")
            } catch {
                print("❌ 获取方案失败: \(error.localizedDescription)")
                print("===== ❌ 获取失败 =====\n")
                
                await MainActor.run {
                    self.hasPlan = false
                    self.loading = false
                }
            }
        }
    }
    
    private func handleAutoCheckin() {
        // Handle auto checkin logic
        print("Auto checkin triggered")
    }
    
    /// 保存方案到本地存储（可选，主要用于日志）
    private func saveRoutineToStorage() {
        print("\n💾 保存方案到本地存储")
        print("📋 当前方案状态:")
        print("   - 方案ID: \(planId)")
        print("   - 早晨步骤数: \(morningRoutine.count)")
        print("   - 晚间步骤数: \(eveningRoutine.count)")
        print("   - 已完成早晨步骤: \(morningRoutine.filter { $0.completed == true }.count)/\(morningRoutine.count)")
        print("   - 已完成晚间步骤: \(eveningRoutine.filter { $0.completed == true }.count)/\(eveningRoutine.count)")
        print("✅ 方案状态已记录\n")
    }
}
