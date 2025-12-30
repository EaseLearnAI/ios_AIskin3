//
//  UserProfileCard.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct UserProfileCard: View {
    let user: User?
    @State private var level: Int = 25
    @State private var experience: Int = 1875
    @State private var nextLevelExp: Int = 2500
    @State private var usedProducts: Int = 28
    @State private var skincareDays: Int = 15
    @State private var achievements: Int = 8
    
    private var progressPercentage: Double {
        guard nextLevelExp > 0 else { return 0 }
        return Double(experience) / Double(nextLevelExp)
    }
    
    private var avatarUrl: URL? {
        if let avatar = user?.avatar, let url = URL(string: avatar) {
            return url
        }
        // 使用 OSS 上的默认头像
        // 已上传的图片: 下载.jpeg
        return URL(string: "https://abc1567849.oss-cn-beijing.aliyuncs.com/avatars/1763021106334-avatar.jpeg")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Profile Section - Horizontal Layout
            HStack(alignment: .top, spacing: 16) {
                // Avatar with Level Badge - Left Side
                ZStack(alignment: .bottomTrailing) {
                    // Avatar
                    AsyncImage(url: avatarUrl) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.972, green: 0.733, blue: 0.816),
                                                Color(red: 0.882, green: 0.745, blue: 0.906)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                ProgressView()
                                    .tint(.white)
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.972, green: 0.733, blue: 0.816),
                                                Color(red: 0.882, green: 0.745, blue: 0.906)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    // Level Badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.972, green: 0.733, blue: 0.816),
                                        Color(red: 0.882, green: 0.745, blue: 0.906)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Text("\(level)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: 4)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                
                // User Info - Right Side
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(user?.name ?? "喵喵主人")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                        
                        // Title Badge
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                            Text("护肤达人")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.757, blue: 0.027),
                                    Color(red: 1.0, green: 0.584, blue: 0.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(red: 1.0, green: 0.757, blue: 0.027).opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    
                    // Level Progress
                    VStack(spacing: 6) {
                        ProgressView(value: progressPercentage)
                            .progressViewStyle(CustomProgressViewStyle())
                            .frame(height: 8)
                        
                        HStack {
                            Text("Lv.\(level) 护肤专家")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("距离下一级还需 \(nextLevelExp - experience) 经验")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.972, green: 0.733, blue: 0.816))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Stats Section
            HStack(spacing: 0) {
                StatItemView(
                    value: "\(usedProducts)",
                    label: "已用产品",
                    gradient: [Color(red: 0.972, green: 0.733, blue: 0.816), Color(red: 0.882, green: 0.745, blue: 0.906)]
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItemView(
                    value: "\(skincareDays)",
                    label: "护肤天数",
                    gradient: [Color(red: 0.227, green: 0.592, blue: 0.388), Color(red: 0.200, green: 0.780, blue: 0.459)]
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItemView(
                    value: "\(achievements)",
                    label: "成就徽章",
                    gradient: [Color(red: 1.0, green: 0.757, blue: 0.027), Color(red: 1.0, green: 0.584, blue: 0.0)]
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.961, green: 0.969, blue: 0.980).opacity(0.5),
                        Color.white.opacity(0.5)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

struct StatItemView: View {
    let value: String
    let label: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: gradient),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.972, green: 0.733, blue: 0.816),
                                Color(red: 0.882, green: 0.745, blue: 0.906)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0))
                    .animation(.easeOut(duration: 1.5), value: configuration.fractionCompleted)
            }
        }
        .frame(height: 8)
    }
}

