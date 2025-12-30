//
//  HealthScoreCard.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct HealthScoreCard: View {
    let score: Int
    @State private var animatedScore: Int = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Score Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text("AI肌肤健康评分")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("基于深度学习智能分析")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .frame(width: 96, height: 96)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(animatedScore) / 100)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 2), value: animatedScore)
                    
                    VStack(spacing: 2) {
                        Text("\(animatedScore)")
                            .font(.system(size: 28, weight: .bold))
                        Text("分")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                }
            }
            
            // Score Details
            VStack(spacing: 16) {
                // Rating
                HStack {
                    Text("健康等级:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text(getRatingText())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(getRatingBackgroundColor())
                            .cornerRadius(12)
                        
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= getStarRating() ? "star.fill" : "star")
                                    .font(.system(size: 12))
                                    .foregroundColor(index <= getStarRating() ? Color(red: 0.988, green: 0.827, blue: 0.302) : Color.white.opacity(0.3))
                            }
                        }
                    }
                }
                
                // Achievement Badge
                HStack(spacing: 8) {
                    Image(systemName: "award.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.988, green: 0.827, blue: 0.302))
                    Text(getAchievementText())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(24)
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
        .cornerRadius(24)
        .shadow(color: Color(red: 0.400, green: 0.494, blue: 0.918).opacity(0.3), radius: 30, x: 0, y: 10)
        .padding(.horizontal, 8)
        .onAppear {
            animateScore()
        }
        .onChange(of: score) { oldValue, newValue in
            animateScore()
        }
    }
    
    private func animateScore() {
        let duration: TimeInterval = 2.0
        let steps = 60
        let stepDuration = duration / Double(steps)
        let increment = Double(score) / Double(steps)
        
        animatedScore = 0
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let newValue = min(Int(increment * Double(i)), score)
                withAnimation(.easeOut(duration: stepDuration)) {
                    self.animatedScore = newValue
                }
            }
        }
    }
    
    private func getRatingText() -> String {
        if animatedScore >= 90 { return "优秀" }
        if animatedScore >= 80 { return "良好" }
        if animatedScore >= 70 { return "一般" }
        if animatedScore >= 60 { return "需改善" }
        return "需关注"
    }
    
    private func getRatingBackgroundColor() -> Color {
        if animatedScore >= 90 { return Color(red: 0.133, green: 0.773, blue: 0.369).opacity(0.3) }
        if animatedScore >= 80 { return Color(red: 0.231, green: 0.510, blue: 0.965).opacity(0.3) }
        if animatedScore >= 70 { return Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.3) }
        if animatedScore >= 60 { return Color(red: 0.976, green: 0.451, blue: 0.133).opacity(0.3) }
        return Color(red: 0.933, green: 0.267, blue: 0.267).opacity(0.3)
    }
    
    private func getStarRating() -> Int {
        if animatedScore >= 90 { return 5 }
        if animatedScore >= 80 { return 4 }
        if animatedScore >= 70 { return 3 }
        if animatedScore >= 60 { return 2 }
        return 1
    }
    
    private func getAchievementText() -> String {
        if animatedScore >= 90 { return "肌肤状态极佳！" }
        if animatedScore >= 80 { return "肌肤状态良好" }
        if animatedScore >= 70 { return "肌肤状态一般" }
        if animatedScore >= 60 { return "需要加强护理" }
        return "建议咨询专业医生"
    }
}

