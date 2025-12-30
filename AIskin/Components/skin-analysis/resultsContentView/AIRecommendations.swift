//
//  AIRecommendations.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct AIRecommendations: View {
    let recommendations: [String]
    
    var recommendationCards: [RecommendationCardData] {
        if !recommendations.isEmpty {
            return recommendations.enumerated().map { index, rec in
                RecommendationCardData(
                    title: "建议 \(index + 1)",
                    description: rec,
                    tags: ["AI建议"],
                    info: "基于您的肌肤状况",
                    icon: "lightbulb.fill",
                    iconBgClass: .blue,
                    bgClass: .blue,
                    decorationClass: .blue,
                    tagClass: .blue,
                    infoClass: .blue,
                    infoIcon: "sparkles"
                )
            }
        }
        
        // Default recommendations
        return [
            RecommendationCardData(
                title: "清洁护理方案",
                description: "建议使用温和的氨基酸洁面乳，早晚各一次，避免过度清洁导致水油失衡。",
                tags: ["氨基酸洁面", "温和清洁", "pH平衡"],
                info: "建议使用频率：早晚各1次",
                icon: "drop.fill",
                iconBgClass: .blue,
                bgClass: .blue,
                decorationClass: .blue,
                tagClass: .blue,
                infoClass: .blue,
                infoIcon: "clock.fill"
            ),
            RecommendationCardData(
                title: "保湿护理方案",
                description: "选择适合您肤质的保湿产品，保持肌肤水润平衡。",
                tags: ["保湿", "补水", "锁水"],
                info: "建议使用频率：每日2次",
                icon: "leaf.fill",
                iconBgClass: .emerald,
                bgClass: .emerald,
                decorationClass: .emerald,
                tagClass: .emerald,
                infoClass: .emerald,
                infoIcon: "map.fill"
            ),
            RecommendationCardData(
                title: "防晒护理方案",
                description: "每日使用SPF30+广谱防晒霜，保护肌肤免受紫外线伤害。",
                tags: ["防晒", "紫外线防护", "SPF30+"],
                info: "建议使用频率：每日1次",
                icon: "sun.max.fill",
                iconBgClass: .amber,
                bgClass: .amber,
                decorationClass: .amber,
                tagClass: .amber,
                infoClass: .amber,
                infoIcon: "shield.fill"
            )
        ]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Card Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.231, green: 0.510, blue: 0.965))
                    Text("AI智能护肤建议")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                }
                
                Spacer()
                
                Text("个性化定制")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.400, green: 0.494, blue: 0.918))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.855, green: 0.918, blue: 0.996),
                                Color(red: 0.929, green: 0.914, blue: 0.996)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
            
            // Recommendations List
            VStack(spacing: 20) {
                ForEach(Array(recommendationCards.enumerated()), id: \.offset) { index, card in
                    RecommendationCard(data: card)
                }
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
}

struct RecommendationCard: View {
    let data: RecommendationCardData
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Decoration Circle
            Circle()
                .fill(data.decorationClass.color.opacity(0.2))
                .frame(width: 80, height: 80)
                .offset(x: 40, y: -40)
            
            VStack(alignment: .leading, spacing: 16) {
                // Title with Icon
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(data.iconBgClass.color)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: data.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    
                    Text(data.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                }
                
                // Description
                Text(data.description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                    .lineSpacing(4)
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(data.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(data.tagClass.textColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(data.tagClass.getBackgroundGradient())
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(data.tagClass.borderColor, lineWidth: 1)
                                )
                        }
                    }
                }
                
                // Info
                HStack(spacing: 8) {
                    Image(systemName: data.infoIcon)
                        .font(.system(size: 12))
                    Text(data.info)
                        .font(.system(size: 12))
                }
                .foregroundColor(data.infoClass.textColor)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(data.bgClass.getBackgroundGradient())
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(data.bgClass.borderColor, lineWidth: 1)
        )
    }
}

struct RecommendationCardData {
    let title: String
    let description: String
    let tags: [String]
    let info: String
    let icon: String
    let iconBgClass: ColorClass
    let bgClass: ColorClass
    let decorationClass: ColorClass
    let tagClass: ColorClass
    let infoClass: ColorClass
    let infoIcon: String
}

enum ColorClass {
    case blue, emerald, amber, purple
    
    var color: Color {
        switch self {
        case .blue: return Color(red: 0.231, green: 0.510, blue: 0.965)
        case .emerald: return Color(red: 0.063, green: 0.722, blue: 0.506)
        case .amber: return Color(red: 0.961, green: 0.620, blue: 0.043)
        case .purple: return Color(red: 0.545, green: 0.298, blue: 0.965)
        }
    }
    
    
    var borderColor: Color {
        switch self {
        case .blue: return Color(red: 0.749, green: 0.875, blue: 0.996)
        case .emerald: return Color(red: 0.655, green: 0.953, blue: 0.816)
        case .amber: return Color(red: 0.992, green: 0.906, blue: 0.541)
        case .purple: return Color(red: 0.882, green: 0.725, blue: 0.992)
        }
    }
    
    var textColor: Color {
        switch self {
        case .blue: return Color(red: 0.114, green: 0.306, blue: 0.847)
        case .emerald: return Color(red: 0.018, green: 0.471, blue: 0.329)
        case .amber: return Color(red: 0.573, green: 0.251, blue: 0.055)
        case .purple: return Color(red: 0.486, green: 0.188, blue: 0.925)
        }
    }
}

extension ColorClass {
    func getBackgroundGradient() -> LinearGradient {
        switch self {
        case .blue:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.937, green: 0.961, blue: 1.0),
                    Color(red: 0.941, green: 0.973, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .emerald:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.925, green: 0.992, blue: 0.961),
                    Color(red: 0.941, green: 0.992, blue: 0.961)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .amber:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.984, blue: 0.922),
                    Color(red: 0.996, green: 0.953, blue: 0.780)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .purple:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.953, green: 0.914, blue: 0.996),
                    Color(red: 0.980, green: 0.961, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

