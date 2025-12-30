//
//  AnalysisSummary.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct AnalysisSummary: View {
    let analysis: IngredientAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.612, green: 0.153, blue: 0.690))
                    Text("AI智能解析")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                    Text("刚刚更新")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
            }
            
            VStack(spacing: 12) {
                // Efficacy Analysis Card
                if !analysis.efficacyAnalysis.isEmpty {
                    AnalysisCard(
                        icon: "sparkles",
                        title: "功效分析",
                        items: analysis.efficacyAnalysis,
                        backgroundColor: Color(red: 0.953, green: 0.898, blue: 0.961),
                        iconColor: Color(red: 0.416, green: 0.106, blue: 0.604),
                        iconBackgroundColor: Color(red: 0.882, green: 0.745, blue: 0.906),
                        itemIcon: "checkmark.circle.fill",
                        itemColor: Color(red: 0.298, green: 0.686, blue: 0.314)
                    )
                }
                
                // Potential Risks Card
                if !analysis.potentialRisks.isEmpty {
                    AnalysisCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "潜在风险",
                        items: analysis.potentialRisks,
                        backgroundColor: Color(red: 1.0, green: 0.973, blue: 0.882),
                        iconColor: Color(red: 1.0, green: 0.561, blue: 0.0),
                        iconBackgroundColor: Color(red: 1.0, green: 0.878, blue: 0.510),
                        itemIcon: "exclamationmark.circle.fill",
                        itemColor: Color(red: 1.0, green: 0.596, blue: 0.0)
                    )
                }
                
                // Recommendations Card
                if !analysis.recommendations.isEmpty {
                    AnalysisCard(
                        icon: "lightbulb.fill",
                        title: "使用建议",
                        items: analysis.recommendations,
                        backgroundColor: Color(red: 0.890, green: 0.949, blue: 0.992),
                        iconColor: Color(red: 0.098, green: 0.463, blue: 0.824),
                        iconBackgroundColor: Color(red: 0.737, green: 0.871, blue: 0.980),
                        itemIcon: "info.circle.fill",
                        itemColor: Color(red: 0.118, green: 0.533, blue: 0.898)
                    )
                }
                
                // Overall Rating Card
                RatingCard(
                    rating: analysis.overallRating,
                    summary: analysis.summary
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(red: 1.0, green: 0.714, blue: 0.757).opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

struct AnalysisCard: View {
    let icon: String
    let title: String
    let items: [String]
    let backgroundColor: Color
    let iconColor: Color
    let iconBackgroundColor: Color
    let itemIcon: String
    let itemColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon Container
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBackgroundColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
                
                Spacer()
            }
            
            // Items List
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: itemIcon)
                            .font(.system(size: 12))
                            .foregroundColor(itemColor)
                            .padding(.top, 2)
                        
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct RatingCard: View {
    let rating: Double
    let summary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.984, green: 0.753, blue: 0.176))
                    Text("AI综合评分")
                        .font(.system(size: 14, weight: .medium))
                }
                
                Spacer()
                
                Text(String(format: "%.1f/5.0", rating))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.416, green: 0.106, blue: 0.604))
            }
            
            Text(summary)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.953, green: 0.898, blue: 0.961),
                    Color(red: 1.0, green: 0.878, blue: 0.941)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}




