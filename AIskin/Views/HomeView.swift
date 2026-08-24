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
    @ObservedObject var planStore: PlanStore
    @State private var morningRoutine: [RoutineItem] = []
    @State private var eveningRoutine: [RoutineItem] = []
    @State private var recommendations: [String] = []
    @State private var loading = true
    @State private var hasPlan = false
    @State private var planId = ""

    init(selectedTab: Binding<Int>, shouldEnableConflictMode: Binding<Bool>, planStore: PlanStore) {
        self._selectedTab = selectedTab
        self._shouldEnableConflictMode = shouldEnableConflictMode
        self.planStore = planStore
    }
    
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
                            CoreFeaturesView(
                                selectedTab: $selectedTab,
                                shouldEnableConflictMode: $shouldEnableConflictMode,
                                planStore: planStore
                            )
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
                                    planStore: planStore,
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
        .task {
            await fetchRoutine()
        }
        .onReceive(planStore.$currentPlan) { plan in
            guard let plan else {
                hasPlan = false
                return
            }
            planId = plan.id
            morningRoutine = plan.morning
            eveningRoutine = plan.evening
            recommendations = plan.recommendations
            hasPlan = true
            loading = false
        }
    }
    
    /// 从API获取最新的护肤方案
    private func fetchRoutine() async {
        loading = true
        await planStore.load()
        if let plan = planStore.currentPlan {
            planId = plan.id
            morningRoutine = plan.morning
            eveningRoutine = plan.evening
            recommendations = plan.recommendations
            hasPlan = true
        } else {
            hasPlan = false
        }
        loading = false
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
