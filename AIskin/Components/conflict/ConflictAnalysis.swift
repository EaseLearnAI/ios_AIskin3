//
//  ConflictAnalysis.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ConflictAnalysis: View {
    let conflicts: [Conflict]
    let safeCombo: [SafeCombo]
    let recommendations: ConflictRecommendations?
    
    var hasConflicts: Bool {
        !conflicts.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.298, green: 0.686, blue: 0.314))
                    Text("检测结果")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("刚刚更新")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
            }
            
            // No Conflicts Banner
            if !hasConflicts && safeCombo.isEmpty {
                NoConflictsBanner()
            }
            
            // Conflicts Section
            if hasConflicts {
                ConflictSection(conflicts: conflicts)
            }
            
            // Safe Combinations Section
            if !safeCombo.isEmpty {
                SafeComboSection(safeCombo: safeCombo)
            }
            
            // Recommendations Section
            if let recommendations = recommendations, hasRecommendations(recommendations) {
                RecommendationsSection(recommendations: recommendations)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 30, x: 0, y: 10)
    }
    
    private func hasRecommendations(_ recommendations: ConflictRecommendations) -> Bool {
        return (recommendations.productPairings?.cannotUseTogether?.isEmpty == false) ||
               (recommendations.productPairings?.canUseTogether?.isEmpty == false) ||
               (recommendations.routines?.morning?.isEmpty == false) ||
               (recommendations.routines?.evening?.isEmpty == false)
    }
}

struct NoConflictsBanner: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "face.smiling.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(red: 0.298, green: 0.686, blue: 0.314))
            
            Text("太棒了！这些产品没有发现成分冲突，可以安心使用喵~")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0.224, green: 0.557, blue: 0.235))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.945, green: 0.973, blue: 0.914),
                    Color(red: 0.910, green: 0.961, blue: 0.914)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 0.298, green: 0.686, blue: 0.314).opacity(0.2), lineWidth: 1)
        )
    }
}

struct ConflictSection: View {
    let conflicts: [Conflict]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(red: 0.957, green: 0.263, blue: 0.212))
                    .frame(width: 10, height: 10)
                
                Text("这些成分会打架哦！")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.827, green: 0.157, blue: 0.129))
            }
            
            ForEach(Array(conflicts.enumerated()), id: \.offset) { index, conflict in
                ConflictCard(conflict: conflict)
            }
        }
    }
}

struct ConflictCard: View {
    let conflict: Conflict
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color(red: 0.957, green: 0.263, blue: 0.212).opacity(0.15), radius: 10, x: 0, y: 4)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text(formatComponents(conflict.components))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                
                Text(conflict.description)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.400, green: 0.400, blue: 0.400))
                    .lineSpacing(4)
                
                // Severity Badge
                HStack(spacing: 8) {
                    Text("\(conflict.severity)度风险")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(severityColor(conflict.severity))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(severityColor(conflict.severity).opacity(0.1))
                        .cornerRadius(20)
                    
                    if let effects = conflict.effects, !effects.isEmpty {
                        Text(effects[0])
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.957, green: 0.478, blue: 0.0))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 1.0, green: 0.596, blue: 0.0).opacity(0.1))
                            .cornerRadius(20)
                    }
                }
                
                // Effects List
                if let effects = conflict.effects, effects.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(effects.enumerated()), id: \.offset) { index, effect in
                            if index > 0 {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                                    
                                    Text(effect)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.333, green: 0.333, blue: 0.333))
                                }
                                .padding(.vertical, 4)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 0.5)
                                        .foregroundColor(Color(red: 0.961, green: 0.961, blue: 0.969)),
                                    alignment: .bottom
                                )
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.922, blue: 0.933),
                    Color(red: 1.0, green: 0.953, blue: 0.878)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.957, green: 0.263, blue: 0.212).opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatComponents(_ components: [String]) -> String {
        components.isEmpty ? "未检测到成分" : components.joined(separator: " + ")
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "高":
            return Color(red: 0.827, green: 0.157, blue: 0.129)
        case "中":
            return Color(red: 0.957, green: 0.478, blue: 0.0)
        default:
            return Color(red: 0.224, green: 0.557, blue: 0.235)
        }
    }
}

struct SafeComboSection: View {
    let safeCombo: [SafeCombo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(Color(red: 0.298, green: 0.686, blue: 0.314))
                    .frame(width: 10, height: 10)
                
                Text("这些组合很和谐喵～")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.224, green: 0.557, blue: 0.235))
            }
            
            ForEach(Array(safeCombo.enumerated()), id: \.offset) { index, combo in
                SafeComboCard(combo: combo)
            }
        }
    }
}

struct SafeComboCard: View {
    let combo: SafeCombo
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color(red: 0.298, green: 0.686, blue: 0.314).opacity(0.15), radius: 10, x: 0, y: 4)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.298, green: 0.686, blue: 0.314))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(formatComponents(combo.components))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                
                Text(combo.description)
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.400, green: 0.400, blue: 0.400))
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.910, green: 0.961, blue: 0.914),
                    Color(red: 0.855, green: 0.965, blue: 0.855)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.298, green: 0.686, blue: 0.314).opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatComponents(_ components: [String]) -> String {
        components.isEmpty ? "未检测到成分" : components.joined(separator: " + ")
    }
}

struct RecommendationsSection: View {
    let recommendations: ConflictRecommendations
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 1.0, green: 0.596, blue: 0.0))
                Text("猫咪护肤建议")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
            }
            
            // Product Pairings
            if let pairings = recommendations.productPairings {
                VStack(alignment: .leading, spacing: 16) {
                    Text("产品搭配:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                    
                    // Cannot Use Together
                    if let cannotUse = pairings.cannotUseTogether, !cannotUse.isEmpty {
                        RecommendationList(
                            title: "不能一起使用:",
                            icon: "ban.fill",
                            pairings: cannotUse,
                            isWarning: true
                        )
                    }
                    
                    // Can Use Together
                    if let canUse = pairings.canUseTogether, !canUse.isEmpty {
                        RecommendationList(
                            title: "可以一起使用:",
                            icon: "checkmark.circle.fill",
                            pairings: canUse,
                            isWarning: false
                        )
                    }
                }
                .padding(20)
                .background(Color(red: 0.980, green: 0.980, blue: 0.984))
                .cornerRadius(16)
            }
            
            // Routines
            if let routines = recommendations.routines {
                VStack(alignment: .leading, spacing: 16) {
                    Text("护肤步骤:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                    
                    // Morning Routine
                    if let morning = routines.morning, !morning.isEmpty {
                        RoutineCardView(title: "早晨", icon: "sun.max.fill", steps: morning)
                    }
                    
                    // Evening Routine
                    if let evening = routines.evening, !evening.isEmpty {
                        RoutineCardView(title: "晚上", icon: "moon.fill", steps: evening)
                    }
                }
                .padding(20)
                .background(Color(red: 0.980, green: 0.980, blue: 0.984))
                .cornerRadius(16)
            }
        }
    }
}

struct RecommendationList: View {
    let title: String
    let icon: String
    let pairings: [Pairing]
    let isWarning: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isWarning ? Color(red: 0.827, green: 0.157, blue: 0.129) : Color(red: 0.224, green: 0.557, blue: 0.235))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isWarning ? Color(red: 0.827, green: 0.157, blue: 0.129) : Color(red: 0.224, green: 0.557, blue: 0.235))
            }
            
            ForEach(Array(pairings.enumerated()), id: \.offset) { index, pairing in
                RecommendationItem(pairing: pairing)
            }
        }
    }
}

struct RecommendationItem: View {
    let pairing: Pairing
    
    private func formatProductPair(_ products: [String]) -> String {
        products.isEmpty ? "未指定产品" : products.joined(separator: " + ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formatProductPair(pairing.products))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
            
            Text(pairing.reason)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.400, green: 0.400, blue: 0.400))
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct RoutineCardView: View {
    let title: String
    let icon: String
    let steps: [String]
    
    var iconColor: Color {
        icon == "sun.max.fill" ? Color(red: 1.0, green: 0.596, blue: 0.0) : Color(red: 0.369, green: 0.208, blue: 0.694)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(step)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color(red: 0.961, green: 0.961, blue: 0.969))
                            .offset(y: 8),
                        alignment: .bottom
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(iconColor, lineWidth: 3),
            alignment: .leading
        )
    }
}




