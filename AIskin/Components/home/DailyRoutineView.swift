//
//  DailyRoutineView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct DailyRoutineView: View {
    var planId: String = ""
    @Binding var morningRoutine: [RoutineItem]
    @Binding var eveningRoutine: [RoutineItem]
    @Binding var recommendations: [String]
    var onSaveRoutine: (() -> Void)? = nil
    var onAutoCheckin: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.702, green: 0.616, blue: 0.859),
                                    Color(red: 0.584, green: 0.459, blue: 0.804)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text("我的护肤方案")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            
            // Routines Container
            VStack(spacing: 24) {
                // Morning Routine
                if !morningRoutine.isEmpty {
                    RoutineSectionView(
                        title: "早间护理",
                        icon: "sun.max.fill",
                        iconColor: Color(red: 0.702, green: 0.616, blue: 0.859),
                        items: morningRoutine,
                        onToggle: { index in
                            toggleTask(index: index, period: "morning")
                        }
                    )
                }
                
                // Evening Routine
                if !eveningRoutine.isEmpty {
                    RoutineSectionView(
                        title: "晚间护理",
                        icon: "moon.fill",
                        iconColor: Color(red: 0.702, green: 0.616, blue: 0.859),
                        items: eveningRoutine,
                        onToggle: { index in
                            toggleTask(index: index, period: "evening")
                        }
                    )
                }
                
                // Recommendations
                if !recommendations.isEmpty {
                    RecommendationsSectionView(recommendations: recommendations)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 8)
    }
    
    private func toggleTask(index: Int, period: String) {
        // 根据 period 选择对应的 routine
        let routine = period == "morning" ? morningRoutine : eveningRoutine
        
        guard index < routine.count else { return }
        guard !planId.isEmpty else {
            print("⚠️ 警告: planId 为空，无法更新步骤状态")
            return
        }
        
        // 获取当前步骤信息
        var item = routine[index]
        let stepNumber = item.step ?? (index + 1)  // 使用 step 字段，如果没有则使用索引+1
        let newCompletedStatus = !(item.completed ?? false)
        
        print("\n===== 🔄 更新步骤完成状态 ======")
        print("📊 更新信息:")
        print("   - 方案ID: \(planId)")
        print("   - 时间段: \(period)")
        print("   - 步骤编号: \(stepNumber)")
        print("   - 当前状态: \(item.completed ?? false ? "已完成" : "未完成")")
        print("   - 新状态: \(newCompletedStatus ? "已完成" : "未完成")")
        
        // 先更新本地状态（乐观更新）
        item.completed = newCompletedStatus
        if period == "morning" {
            morningRoutine[index] = item
        } else {
            eveningRoutine[index] = item
        }
        
        // 调用API更新后端状态
        Task {
            do {
                print("📡 发起API请求: PATCH /api/plans/\(planId)/step")
                print("📋 请求体: { period: \"\(period)\", step: \(stepNumber), completed: \(newCompletedStatus) }")
                
                let updatedPlan = try await PlanApiService.shared.updateStepCompleted(
                    planId: planId,
                    period: period,
                    step: stepNumber,
                    completed: newCompletedStatus
                )
                
                print("✅ API响应成功")
                print("📦 返回的方案数据:")
                print("   - 方案ID: \(updatedPlan.id)")
                print("   - 早晨步骤数: \(updatedPlan.morning.count)")
                print("   - 晚间步骤数: \(updatedPlan.evening.count)")
                
                // 使用后端返回的最新数据更新UI
                await MainActor.run {
                    self.morningRoutine = updatedPlan.morning
                    self.eveningRoutine = updatedPlan.evening
                    self.recommendations = updatedPlan.recommendations
                }
                
                print("✅ UI已更新为最新数据")
                print("===== ✅ 更新完成 =====\n")
                
                // 检查是否所有任务都完成
                let allMorningDone = updatedPlan.morning.allSatisfy { $0.completed == true }
                let allEveningDone = updatedPlan.evening.allSatisfy { $0.completed == true }
                
                if allMorningDone && allEveningDone {
                    print("🎉 所有任务已完成，触发自动打卡")
                    onAutoCheckin?()
                }
                
                onSaveRoutine?()
            } catch {
                print("❌ API更新失败: \(error.localizedDescription)")
                print("🔄 回滚本地状态")
                
                // 回滚本地状态
                await MainActor.run {
                    item.completed = !newCompletedStatus
                    if period == "morning" {
                        self.morningRoutine[index] = item
                    } else {
                        self.eveningRoutine[index] = item
                    }
                }
                
                print("===== ❌ 更新失败 =====\n")
            }
        }
    }
}

struct RoutineSectionView: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [RoutineItem]
    let onToggle: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    iconColor,
                                    iconColor.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
            }
            
            // Routine Items
            VStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    RoutineItemRowView(
                        item: item,
                        onTap: {
                            onToggle(index)
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.980, green: 0.980, blue: 0.984))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

struct RoutineItemRowView: View {
    let item: RoutineItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: item.completed == true ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(
                        item.completed == true ?
                        Color(red: 0.584, green: 0.459, blue: 0.804) :
                        Color(red: 0.612, green: 0.612, blue: 0.612)
                    )
                
                // Product Name
                Text(item.product ?? "")
                    .font(.system(size: 15))
                    .foregroundColor(
                        item.completed == true ?
                        Color(red: 0.267, green: 0.267, blue: 0.267).opacity(0.7) :
                        Color(red: 0.267, green: 0.267, blue: 0.267)
                    )
                
                Spacer()
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecommendationsSectionView: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.800, blue: 0.502),
                                    Color(red: 1.0, green: 0.596, blue: 0.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Text("专业建议")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
            }
            
            // Recommendations List
            VStack(spacing: 12) {
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, tip in
                    RecommendationItemView(tip: tip)
                }
            }
        }
        .padding(20)
        .background(Color(red: 1.0, green: 0.973, blue: 0.878))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

struct RecommendationItemView: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0))
                .padding(.top, 2)
            
            Text(tip)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.365, green: 0.251, blue: 0.216))
                .lineLimit(nil)
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.5))
        .cornerRadius(10)
    }
}

