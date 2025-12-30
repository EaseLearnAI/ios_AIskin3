//
//  PersonalizedRoutinePreviewView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct PersonalizedRoutinePreviewView: View {
    let plan: SkinPlan
    let onSave: () -> Void
    let onCustomize: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Preview Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.612, green: 0.153, blue: 0.690))
                        Text(plan.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                    }
                    
                    Text(plan.creatorNote ?? "日常基础护肤")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.1))
                        .offset(y: 20),
                    alignment: .bottom
                )
                
                // Morning Routine
                if !plan.morning.isEmpty {
                    RoutinePreviewSection(
                        title: "早间护理",
                        icon: "sun.max.fill",
                        items: plan.morning
                    )
                }
                
                // Evening Routine
                if !plan.evening.isEmpty {
                    RoutinePreviewSection(
                        title: "晚间护理",
                        icon: "moon.fill",
                        items: plan.evening
                    )
                }
                
                // Recommendations
                if !plan.recommendations.isEmpty {
                    RecommendationsPreviewSection(recommendations: plan.recommendations)
                }
                
                // Actions
                HStack(spacing: 16) {
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text("保存到我的方案")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.671, green: 0.278, blue: 0.737),
                                    Color(red: 0.482, green: 0.122, blue: 0.635)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color(red: 0.482, green: 0.122, blue: 0.635).opacity(0.25), radius: 6, x: 0, y: 2)
                    }
                    
                    Button(action: onCustomize) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("重新定制")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 0.961, green: 0.961, blue: 0.961))
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 24)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.1))
                        .offset(y: -24),
                    alignment: .top
                )
            }
            .padding(24)
        }
    }
}

struct RoutinePreviewSection: View {
    let title: String
    let icon: String
    let items: [RoutineItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(
                        icon == "sun.max.fill" ?
                        Color(red: 1.0, green: 0.584, blue: 0.0) :
                        Color(red: 0.369, green: 0.208, blue: 0.694)
                    )
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
            }
            
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    StepItemView(
                        number: index + 1,
                        product: item.product ?? "",
                        reason: item.reason
                    )
                }
            }
        }
    }
}

struct StepItemView: View {
    let number: Int
    let product: String
    let reason: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Step Number
            Text("\(number)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.612, green: 0.153, blue: 0.690),
                            Color(red: 0.482, green: 0.122, blue: 0.635)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            
            // Product Name
            Text(product)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
            
            Spacer()
        }
        .padding(12)
        .background(Color(red: 0.980, green: 0.980, blue: 0.984))
        .cornerRadius(12)
    }
}

struct RecommendationsPreviewSection: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.612, green: 0.153, blue: 0.690))
                Text("专业建议")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.267, green: 0.267, blue: 0.267))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.612, green: 0.153, blue: 0.690))
                            .padding(.top, 4)
                        
                        Text(tip)
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.333, green: 0.333, blue: 0.333))
                            .lineLimit(nil)
                    }
                }
            }
        }
    }
}


