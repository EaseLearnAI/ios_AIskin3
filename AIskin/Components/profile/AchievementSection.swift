//
//  AchievementSection.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct AchievementSection: View {
    @State private var achievements: [Achievement] = [
        Achievement(
            id: "1",
            icon: "star.fill",
            title: "护肤达人",
            description: "连续使用15天护肤品",
            isUnlocked: true,
            progress: 1.0,
            totalProgress: 1.0,
            reward: "+500经验",
            gradient: [Color(red: 0.972, green: 0.733, blue: 0.816), Color(red: 0.882, green: 0.745, blue: 0.906)]
        ),
        Achievement(
            id: "2",
            icon: "drop.fill",
            title: "水分满满",
            description: "肌肤水分值达到90%",
            isUnlocked: true,
            progress: 1.0,
            totalProgress: 1.0,
            reward: nil,
            gradient: [Color(red: 0.259, green: 0.522, blue: 0.957), Color(red: 0.200, green: 0.478, blue: 0.918)]
        ),
        Achievement(
            id: "3",
            icon: "calendar",
            title: "打卡达人",
            description: "连续打卡30天",
            isUnlocked: false,
            progress: 15,
            totalProgress: 30,
            reward: nil,
            gradient: [Color.gray.opacity(0.4), Color.gray.opacity(0.6)]
        ),
        Achievement(
            id: "4",
            icon: "flask.fill",
            title: "产品收藏家",
            description: "收集50件护肤品",
            isUnlocked: false,
            progress: 28,
            totalProgress: 50,
            reward: nil,
            gradient: [Color(red: 1.0, green: 0.757, blue: 0.027).opacity(0.4), Color(red: 1.0, green: 0.584, blue: 0.0).opacity(0.6)]
        )
    ]
    
    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 1.0, green: 0.757, blue: 0.027))
                    
                    Text("我的成就")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                }
                
                Spacer()
                
                Text("\(unlockedCount)/\(achievements.count) 已解锁")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Achievement Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct Achievement: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool
    let progress: Double
    let totalProgress: Double
    let reward: String?
    let gradient: [Color]
}

struct AchievementCard: View {
    let achievement: Achievement
    @State private var isPressed = false
    
    private var progressPercentage: Double {
        guard achievement.totalProgress > 0 else { return 0 }
        return achievement.progress / achievement.totalProgress
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: achievement.gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Title
            Text(achievement.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
            
            // Description
            Text(achievement.description)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            Spacer()
            
            // Status
            if achievement.isUnlocked {
                HStack {
                    Text("已获得")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.972, green: 0.733, blue: 0.816))
                    
                    Spacer()
                    
                    if let reward = achievement.reward {
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 8))
                            Text(reward)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(Color(red: 1.0, green: 0.757, blue: 0.027))
                    }
                }
            } else {
                Text("进度: \(Int(achievement.progress))/\(Int(achievement.totalProgress))")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            Group {
                if achievement.isUnlocked {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.972, green: 0.733, blue: 0.816).opacity(0.1),
                            Color.white
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.05),
                            Color.white
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked ?
                    Color(red: 0.972, green: 0.733, blue: 0.816).opacity(0.3) :
                    Color.gray.opacity(0.1),
                    lineWidth: 1
                )
        )
        .cornerRadius(16)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

