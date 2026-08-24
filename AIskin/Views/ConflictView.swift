//
//  ConflictView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ConflictView: View {
    let productIds: [String]?
    
    @State private var activeTab: ConflictTab = .overview
    @StateObject private var store = ConflictAnalysisStore()
    @Environment(\.dismiss) var dismiss
    
    init(productIds: [String]? = nil) {
        self.productIds = productIds
        print("\n============================================================")
        print("📱 ConflictView: init被调用")
        print("============================================================\n")
        print("📊 初始化参数:")
        print("   - productIds: \(productIds?.description ?? "nil")")
        print("   - productIds数量: \(productIds?.count ?? 0)")
        print("============================================================\n")
    }
    
    enum ConflictTab: String, CaseIterable {
        case overview = "概览"
        case conflicts = "冲突"
        case safe = "安全组合"
        case routine = "使用建议"
        
        var icon: String {
            switch self {
            case .overview: return "chart.pie.fill"
            case .conflicts: return "exclamationmark.triangle.fill"
            case .safe: return "shield.fill"
            case .routine: return "lightbulb.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.980, green: 0.980, blue: 0.980),
                    Color(red: 0.961, green: 0.961, blue: 0.961)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView(onDismiss: {
                    print("\n============================================================")
                    print("📱 ConflictView: 收到HeaderView的dismiss请求")
                    print("============================================================\n")
                    print("📱 执行ConflictView的dismiss()")
                    dismiss()
                })
                
                // Tab Navigation
                TabNavigationView(activeTab: $activeTab)
                
                // Content
                if case .loading = store.state {
                    LoadingView()
                } else if case let .failed(error) = store.state {
                    ErrorView(message: error)
                } else if case let .loaded(data) = store.state {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 20) {
                                // Overview Section
                                OverviewSection(conflicts: data.conflicts ?? [], safeCombo: data.safeCombo ?? [])
                                    .id("overview")
                                    .padding(.horizontal, 20)
                                
                                // Conflicts Section
                                ConflictsDetailSection(conflicts: data.conflicts ?? [])
                                    .id("conflicts")
                                    .padding(.horizontal, 20)
                                
                                // Safe Combinations Section
                                SafeCombinationsSection(safeCombo: data.safeCombo ?? [])
                                    .id("safe")
                                    .padding(.horizontal, 20)
                                
                                // Recommendations Section
                                RecommendationsDetailSection(recommendations: data.recommendations)
                                    .id("routine")
                                    .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 16)
                            .padding(.bottom, 100)
                        }
                        .onChange(of: activeTab) { newTab in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                switch newTab {
                                case .overview:
                                    proxy.scrollTo("overview", anchor: .top)
                                case .conflicts:
                                    proxy.scrollTo("conflicts", anchor: .top)
                                case .safe:
                                    proxy.scrollTo("safe", anchor: .top)
                                case .routine:
                                    proxy.scrollTo("routine", anchor: .top)
                                }
                            }
                        }
                    }
                } else {
                    Color.clear
                }
            }
        }
        .navigationBarHidden(true)
        .task(id: productIds ?? []) {
            await store.analyze(productIDs: productIds ?? [])
        }
    }
}

struct HeaderView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                print("\n============================================================")
                print("🔙 ConflictView.HeaderView: 用户点击返回按钮")
                print("============================================================\n")
                
                print("📱 步骤1: 按钮点击事件触发")
                print("   - 当前视图: ConflictView.HeaderView")
                print("   - 操作: 准备关闭ConflictView并返回到ProductView")
                
                print("\n📱 步骤2: 检查dismiss回调")
                print("   - onDismiss回调可用: 是")
                print("   - 回调类型: () -> Void")
                
                print("\n📱 步骤3: 执行dismiss操作")
                print("   - 调用onDismiss()回调")
                print("   - 这将触发ConflictView的dismiss()")
                print("   - 预期结果: 关闭sheet并返回到ProductView（产品分析页面）")
                print("   - ProductView应该在BottomNavigationView的tab 1（产品分析）")
                print("   - 用户应该能看到产品列表和底部导航栏")
                
                // 执行dismiss回调
                onDismiss()
                
                print("\n📱 步骤4: onDismiss()回调已调用")
                print("   - ConflictView的dismiss()应该已被执行")
                print("   - SwiftUI将处理视图关闭动画")
                print("   - sheet Binding setter将被调用（在ProductView中）")
                print("   - ProductView的onAppear可能会被调用（如果之前被隐藏）")
                
                print("\n============================================================")
                print("✅ ConflictView.HeaderView: 返回操作已执行")
                print("============================================================\n")
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("成分冲突检测")
                    .font(.system(size: 20, weight: .bold))
                Text("智能分析·安全护肤")
                    .font(.system(size: 12))
                    .opacity(0.9)
            }
            .foregroundColor(.white)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                }
                
                Button(action: {}) {
                    Image(systemName: "heart")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
    }
}

struct TabNavigationView: View {
    @Binding var activeTab: ConflictView.ConflictTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ConflictView.ConflictTab.allCases, id: \.self) { tab in
                    ConflictTabButton(
                        tab: tab,
                        isActive: activeTab == tab,
                        action: { activeTab = tab }
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .background(Color.white.opacity(0.9))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}

struct ConflictTabButton: View {
    let tab: ConflictView.ConflictTab
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12))
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isActive ? .semibold : .regular))
            }
            .foregroundColor(
                isActive ?
                Color(red: 0.055, green: 0.647, blue: 0.914) :
                Color(red: 0.557, green: 0.557, blue: 0.576)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .overlay(
                Group {
                    if isActive {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.055, green: 0.647, blue: 0.914),
                                        Color(red: 0.008, green: 0.529, blue: 0.780)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                            .offset(y: 18)
                    }
                },
                alignment: .bottom
            )
        }
    }
}

struct OverviewSection: View {
    let conflicts: [Conflict]
    let safeCombo: [SafeCombo]
    
    var minorConflicts: Int {
        conflicts.filter { $0.severity == "中" || $0.severity == "低" }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Analysis Summary Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 1.0, green: 0.584, blue: 0.0))
                        .frame(width: 40, height: 40)
                        .background(Color(red: 1.0, green: 0.584, blue: 0.0).opacity(0.1))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("分析结果")
                            .font(.system(size: 18, weight: .semibold))
                        Text("成分冲突检测报告")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text("警告")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.584, blue: 0.0))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 1.0, green: 0.584, blue: 0.0).opacity(0.1))
                    .cornerRadius(20)
                }
                
                Divider()
                
                HStack(spacing: 12) {
                    StatCard(
                        number: "\(conflicts.count)",
                        label: "严重冲突",
                        color: Color(red: 0.957, green: 0.263, blue: 0.212)
                    )
                    
                    StatCard(
                        number: "\(minorConflicts)",
                        label: "轻微冲突",
                        color: Color(red: 1.0, green: 0.584, blue: 0.0)
                    )
                    
                    StatCard(
                        number: "\(safeCombo.count)",
                        label: "安全组合",
                        color: Color(red: 0.204, green: 0.780, blue: 0.349)
                    )
                }
            }
            .padding(20)
            .background(
                Color.white
                    .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 10)
            )
            .cornerRadius(20)
        }
    }
}

struct StatCard: View {
    let number: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(number)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.1),
                    color.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}


struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundColor(color.opacity(0.8))
            .cornerRadius(20)
    }
}

struct ProductRecommendationsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("推荐平替产品")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("检测到您的产品存在成分冲突，为您推荐以下经过验证的平替产品")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.204, green: 0.780, blue: 0.349).opacity(0.1),
                    Color(red: 0.545, green: 0.765, blue: 0.290).opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // 外圈旋转动画
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.972, green: 0.733, blue: 0.816),
                                Color(red: 0.882, green: 0.745, blue: 0.906)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                // 内圈脉冲动画
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.972, green: 0.733, blue: 0.816).opacity(0.3),
                                Color(red: 0.882, green: 0.745, blue: 0.906).opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0.5 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // 中心图标
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 30))
                    .foregroundColor(Color(red: 0.972, green: 0.733, blue: 0.816))
            }
            
            Text("分析产品冲突中...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Conflicts Detail Section
struct ConflictsDetailSection: View {
    let conflicts: [Conflict]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("冲突检测")
                        .font(.system(size: 18, weight: .semibold))
                    Text("发现的成分冲突和注意事项")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            if conflicts.isEmpty {
                NoConflictsBanner()
            } else {
                ForEach(Array(conflicts.enumerated()), id: \.offset) { index, conflict in
                    ConflictCard(conflict: conflict)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 10)
    }
}

// MARK: - Safe Combinations Section
struct SafeCombinationsSection: View {
    let safeCombo: [SafeCombo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.298, green: 0.686, blue: 0.314))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("安全组合推荐")
                        .font(.system(size: 18, weight: .semibold))
                    Text("经过验证的安全成分搭配")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            if safeCombo.isEmpty {
                Text("暂无安全组合数据")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(Array(safeCombo.enumerated()), id: \.offset) { index, combo in
                    SafeComboCard(combo: combo)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 10)
    }
}

// MARK: - Recommendations Detail Section
struct RecommendationsDetailSection: View {
    let recommendations: ConflictRecommendations?
    
    var body: some View {
        Group {
            if let recommendations = recommendations, hasRecommendations(recommendations) {
                RecommendationsSection(recommendations: recommendations)
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 10)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("使用建议")
                                .font(.system(size: 18, weight: .semibold))
                            Text("产品搭配和护肤步骤建议")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("暂无使用建议数据")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 10)
            }
        }
    }
    
    private func hasRecommendations(_ recommendations: ConflictRecommendations) -> Bool {
        return (recommendations.productPairings?.cannotUseTogether?.isEmpty == false) ||
               (recommendations.productPairings?.canUseTogether?.isEmpty == false) ||
               (recommendations.routines?.morning?.isEmpty == false) ||
               (recommendations.routines?.evening?.isEmpty == false)
    }
}
