//
//  SkinTypeAnalysis.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct SkinTypeAnalysis: View {
    let skinType: SkinTypeData
    let oilLevel: String
    let moistureLevel: String
    let poreLevel: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Card Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "microscope.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.972, green: 0.733, blue: 0.816))
                    Text("皮肤类型分析")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                }
                
                Spacer()
                
                Text("AI识别")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.882, green: 0.745, blue: 0.906))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Skin Type Summary
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(skinType.type)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                    
                    Text(skinType.subtype ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.972, green: 0.733, blue: 0.816))
                            .frame(width: 8, height: 8)
                        Text("基于面部油脂分布分析")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                    }
                }
                
                Spacer()
                
                Text(getSkinTypeEmoji())
                    .font(.system(size: 40))
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.996, green: 0.969, blue: 0.941),
                        Color(red: 0.941, green: 0.992, blue: 0.961)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 1.0, green: 0.976, blue: 0.984), lineWidth: 1)
            )
            
            // Analysis Metrics
            VStack(spacing: 16) {
                MetricItem(
                    icon: "oilcan.fill",
                    iconColor: Color(red: 0.961, green: 0.620, blue: 0.043),
                    label: "T区油脂分泌",
                    status: oilLevel,
                    statusColor: Color(red: 0.961, green: 0.620, blue: 0.043),
                    percentage: getOilPercentage(),
                    suggestion: getOilSuggestion()
                )
                
                MetricItem(
                    icon: "drop.fill",
                    iconColor: Color(red: 0.231, green: 0.510, blue: 0.965),
                    label: "U区水分含量",
                    status: moistureLevel,
                    statusColor: Color(red: 0.231, green: 0.510, blue: 0.965),
                    percentage: getMoisturePercentage(),
                    suggestion: getMoistureSuggestion()
                )
                
                MetricItem(
                    icon: "circle.fill",
                    iconColor: Color(red: 0.545, green: 0.298, blue: 0.965),
                    label: "毛孔粗细度",
                    status: poreLevel,
                    statusColor: Color(red: 0.545, green: 0.298, blue: 0.965),
                    percentage: getPorePercentage(),
                    suggestion: getPoreSuggestion()
                )
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.95),
                    Color.white
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
    
    private func getOilPercentage() -> CGFloat {
        let levels: [String: CGFloat] = ["低": 30, "正常": 50, "偏高": 75, "高": 90]
        return levels[oilLevel] ?? 60
    }
    
    private func getMoisturePercentage() -> CGFloat {
        let levels: [String: CGFloat] = ["低": 30, "正常": 60, "偏高": 80, "高": 95]
        return levels[moistureLevel] ?? 60
    }
    
    private func getPorePercentage() -> CGFloat {
        let levels: [String: CGFloat] = ["细": 25, "正常": 45, "中等": 55, "粗大": 75]
        return levels[poreLevel] ?? 55
    }
    
    private func getSkinTypeEmoji() -> String {
        let emojis: [String: String] = [
            "混合偏油性皮肤": "🧴",
            "混合偏干性皮肤": "💧",
            "油性皮肤": "🔥",
            "干性皮肤": "🌟",
            "中性皮肤": "🌈",
            "敏感性皮肤": "🤧",
            "混合性皮肤": "🌐"
        ]
        return emojis[skinType.type] ?? "👁️"
    }
    
    private func getOilSuggestion() -> String {
        return oilLevel == "偏高" ? "建议使用控油洁面产品" : "建议使用温和洁面产品"
    }
    
    private func getMoistureSuggestion() -> String {
        return moistureLevel == "偏高" ? "建议使用轻薄保湿产品" : "建议使用滋润保湿产品"
    }
    
    private func getPoreSuggestion() -> String {
        return poreLevel == "粗大" ? "建议使用收缩毛孔产品" : "建议使用保湿产品"
    }
}

struct MetricItem: View {
    let icon: String
    let iconColor: Color
    let label: String
    let status: String
    let statusColor: Color
    let percentage: CGFloat
    let suggestion: String
    @State private var animatedPercentage: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                }
                
                Spacer()
                
                Text(status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    iconColor,
                                    iconColor.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (animatedPercentage / 100), height: 8)
                        .animation(.easeOut(duration: 1.5), value: animatedPercentage)
                }
            }
            .frame(height: 8)
            
            Text(suggestion)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
        }
        .padding(16)
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.953, green: 0.957, blue: 0.969), lineWidth: 1)
        )
        .onAppear {
            animatedPercentage = percentage
        }
    }
}

struct SkinTypeData {
    var type: String
    var subtype: String?
    var basis: String?
}


