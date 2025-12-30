//
//  SkincareSquareView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct SkincareSquareView: View {
    @State private var selectedTag: String = "全部"
    @State private var showMyPlans = false
    @State private var plans: [SkinPlan] = []
    
    let tags = ["全部", "补水", "美白", "抗老", "控油", "修护", "祛痘"]
    
    var filteredPlans: [SkinPlan] {
        if selectedTag == "全部" {
            return plans
        }
        return plans.filter { $0.tags.contains(selectedTag) }
    }
    
    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.976, blue: 0.984)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("护肤广场")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Tag Bar
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(tags, id: \.self) { tag in
                                    TagButton(
                                        text: tag,
                                        isSelected: selectedTag == tag,
                                        action: { selectedTag = tag }
                                    )
                                }
                                
                                Button(action: { showMyPlans = true }) {
                                    Text("我的方案")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.984, green: 0.749, blue: 0.141),
                                                    Color(red: 0.945, green: 0.541, blue: 0.541)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        
                        // Plan List
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPlans) { plan in
                                PlanCard(plan: plan)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
        }
        .sheet(isPresented: $showMyPlans) {
            MyPlansModal()
        }
    }
}

struct TagButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(
                    isSelected ?
                    .white :
                    Color(red: 0.906, green: 0.325, blue: 0.502)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.984, green: 0.749, blue: 0.141),
                            Color(red: 0.945, green: 0.541, blue: 0.541)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.894, blue: 0.925),
                            Color.white
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
        }
    }
}

struct PlanCard: View {
    let plan: SkinPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(plan.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.906, green: 0.325, blue: 0.502))
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(plan.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.906, green: 0.325, blue: 0.502))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 1.0, green: 0.894, blue: 0.925))
                            .cornerRadius(12)
                    }
                }
            }
            
            if let note = plan.creatorNote, !note.isEmpty {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("拉入我的方案")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.984, green: 0.749, blue: 0.141),
                            Color(red: 0.945, green: 0.541, blue: 0.541)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct MyPlansModal: View {
    @Environment(\.dismiss) var dismiss
    @State private var myPlans: [SkinPlan] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                if myPlans.isEmpty {
                    Text("暂无方案")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(myPlans) { plan in
                            MyPlanItem(plan: plan)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("我的方案（\(myPlans.count)）")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MyPlanItem: View {
    let plan: SkinPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(plan.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.906, green: 0.325, blue: 0.502))
            
            HStack(spacing: 8) {
                ForEach(plan.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.906, green: 0.325, blue: 0.502))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 1.0, green: 0.894, blue: 0.925))
                        .cornerRadius(12)
                }
            }
            
            if let note = plan.creatorNote, !note.isEmpty {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("设为当前计划")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.984, green: 0.749, blue: 0.141),
                                    Color(red: 0.945, green: 0.541, blue: 0.541)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Text("删除")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color(red: 0.906, green: 0.325, blue: 0.502))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(red: 1.0, green: 0.976, blue: 0.984))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

