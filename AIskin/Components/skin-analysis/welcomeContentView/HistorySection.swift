//
//  HistorySection.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct HistorySection: View {
    let lastAnalysisResult: AnalysisResult?
    let lastAnalysisDate: Date?
    let onShowHistory: () -> Void
    let onStartNewAnalysis: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // History Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.388, green: 0.388, blue: 0.976))
                    Text("上次检测结果")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                }
                
                Spacer()
                
                if let date = lastAnalysisDate {
                    Text(formatDate(date))
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.953, green: 0.957, blue: 0.969))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 16) {
                // Mini Score Card
                Button(action: onShowHistory) {
                    VStack(spacing: 8) {
                        if let result = lastAnalysisResult {
                            Text("\(result.healthScore)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("健康分")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            Text("--")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("健康分")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .frame(width: 80)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.400, green: 0.494, blue: 0.918),
                                Color(red: 0.463, green: 0.298, blue: 0.635)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
                
                // History Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(getHistorySummary())
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Button(action: onShowHistory) {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 12))
                                Text("查看详情")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.953, green: 0.957, blue: 0.969))
                            .cornerRadius(8)
                        }
                        
                        Button(action: onStartNewAnalysis) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12))
                                Text("新检测")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.388, green: 0.388, blue: 0.976))
                            .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.95),
                    Color.white.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 32, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days <= 7 {
                return "\(days)天前"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.locale = Locale(identifier: "zh_CN")
                return formatter.string(from: date)
            }
        }
    }
    
    private func getScoreIndicatorColor(_ score: Int) -> Color {
        if score >= 80 { return Color(red: 0.063, green: 0.722, blue: 0.506) }
        if score >= 60 { return Color(red: 0.961, green: 0.620, blue: 0.043) }
        return Color(red: 0.933, green: 0.267, blue: 0.267)
    }
    
    private func getHistorySummary() -> String {
        guard let result = lastAnalysisResult else {
            return "暂无历史记录"
        }
        
        if let summary = result.summary, !summary.isEmpty {
            return summary
        }
        
        let skinType = result.skinType?.type ?? "未知"
        let condition = result.skinCondition ?? "正常"
        return "\(skinType)，肌肤状态\(condition)"
    }
}

struct AnalysisResult: Equatable {
    var healthScore: Int
    var summary: String?
    var skinCondition: String?
    var skinType: SkinTypeData?
    var blackheads: BlackheadsData?
    var acne: AcneData?
    var pores: PoresData?
    var skinToneEvenness: SkinToneEvennessData?
    var redness: RednessData?
    var hyperpigmentation: HyperpigmentationData?
    var fineLines: FineLinesData?
    var sensitivity: SensitivityData?
    var oilLevel: String?
    var moistureLevel: String?
    var poreLevel: String?
    var recommendations: [String]?
    var createdAt: Date?
    
    // 简化的 Equatable 实现，只比较关键字段用于 onChange 检测
    static func == (lhs: AnalysisResult, rhs: AnalysisResult) -> Bool {
        return lhs.healthScore == rhs.healthScore &&
               lhs.summary == rhs.summary &&
               lhs.skinCondition == rhs.skinCondition &&
               lhs.oilLevel == rhs.oilLevel &&
               lhs.moistureLevel == rhs.moistureLevel &&
               lhs.poreLevel == rhs.poreLevel &&
               lhs.createdAt == rhs.createdAt
    }
}


