//
//  AnalysisOverview.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct AnalysisOverview: View {
    let analysis: IngredientAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("安全性分析")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
            
            // Score Cards
            HStack(spacing: 12) {
                ScoreCard(
                    score: Int(analysis.safetyIndex),
                    label: "安全指数",
                    backgroundColor: Color(red: 0.910, green: 0.961, blue: 0.914),
                    textColor: Color(red: 0.224, green: 0.557, blue: 0.235)
                )
                
                ScoreCard(
                    score: Int(analysis.efficacyScore * 20), // Convert 0-5 scale to 0-100 for display
                    label: "功效评分",
                    backgroundColor: Color(red: 0.890, green: 0.949, blue: 0.992),
                    textColor: Color(red: 0.098, green: 0.463, blue: 0.824),
                    showDecimal: true,
                    decimalValue: analysis.efficacyScore
                )
                
                ScoreCard(
                    score: analysis.activeIngredients,
                    label: "活性成分",
                    backgroundColor: Color(red: 0.953, green: 0.898, blue: 0.961),
                    textColor: Color(red: 0.416, green: 0.106, blue: 0.604)
                )
            }
            
            // Risk Indicators
            VStack(spacing: 12) {
                RiskIndicator(
                    label: "致痘风险",
                    level: analysis.acneRisk.level,
                    percentage: analysis.acneRisk.percentage
                )
                
                RiskIndicator(
                    label: "刺激风险",
                    level: analysis.irritationRisk.level,
                    percentage: analysis.irritationRisk.percentage
                )
                
                RiskIndicator(
                    label: "过敏风险",
                    level: analysis.allergyRisk.level,
                    percentage: analysis.allergyRisk.percentage
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(red: 1.0, green: 0.714, blue: 0.757).opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

struct ScoreCard: View {
    let score: Int
    let label: String
    let backgroundColor: Color
    let textColor: Color
    var showDecimal: Bool = false
    var decimalValue: Double? = nil
    
    var body: some View {
        VStack(spacing: 4) {
            if showDecimal, let decimal = decimalValue {
                Text(String(format: "%.1f", decimal))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(textColor)
            } else {
                Text("\(score)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(textColor)
            }
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct RiskIndicator: View {
    let label: String
    let level: String
    let percentage: Double
    
    var riskColor: Color {
        switch level {
        case "高":
            return Color(red: 0.957, green: 0.263, blue: 0.212)
        case "中":
            return Color(red: 1.0, green: 0.596, blue: 0.0)
        default:
            return Color(red: 0.298, green: 0.686, blue: 0.314)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.333, green: 0.333, blue: 0.333))
            
            Spacer()
            
            HStack(spacing: 8) {
                // Risk Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.941, green: 0.941, blue: 0.941))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(riskColor)
                            .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                    }
                }
                .frame(width: 96, height: 8)
                
                // Risk Level Text
                Text(level)
                    .font(.system(size: 12))
                    .foregroundColor(riskColor)
            }
        }
    }
}




