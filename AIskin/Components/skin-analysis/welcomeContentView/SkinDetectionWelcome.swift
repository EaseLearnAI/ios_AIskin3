//
//  SkinDetectionWelcome.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct SkinDetectionWelcome: View {
    let onTakePhoto: () -> Void
    let onSelectPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Decorative background elements
            ZStack {
                // Decoration circles
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.925, blue: 0.949).opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 128, height: 128)
                    .offset(x: 64, y: -64)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.910, green: 0.980, blue: 0.910).opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .offset(x: -48, y: 48)
                
                // Welcome message
                VStack(spacing: 12) {
                    Text("让我来看看你的肌肤状态吧")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.882, green: 0.745, blue: 0.906))
                    
                    Text("AI智能分析，专业护肤建议")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                }
                .padding(.top, -8)
                .padding(.bottom, -24)
                .padding(.bottom, 0)
            }
            
            // Detection options
            HStack(spacing: 16) {
                // Camera button
                Button(action: onTakePhoto) {
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .frame(width: 48, height: 48)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.972, green: 0.733, blue: 0.816))
                        }
                        
                        Text("拍照检测")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                        
                        Text("实时拍摄分析")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.976, blue: 0.984),
                                Color(red: 1.0, green: 0.925, blue: 0.949)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 1.0, green: 0.925, blue: 0.949).opacity(0.5), lineWidth: 1)
                    )
                }
                
                // Gallery button
                Button(action: onSelectPhoto) {
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .frame(width: 48, height: 48)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.294, green: 0.686, blue: 0.314))
                        }
                        
                        Text("从相册选择")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                        
                        Text("选择已有照片")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.910, green: 0.980, blue: 0.910),
                                Color(red: 0.820, green: 0.961, blue: 0.820)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.820, green: 0.961, blue: 0.820).opacity(0.5), lineWidth: 1)
                    )
                }
            }
            
            // Feature highlights
            HStack(spacing: 24) {
                FeatureHighlight(dotColor: Color(red: 0.294, green: 0.686, blue: 0.314), text: "AI智能识别")
                FeatureHighlight(dotColor: Color(red: 0.227, green: 0.737, blue: 0.973), text: "专业分析")
                FeatureHighlight(dotColor: Color(red: 0.659, green: 0.337, blue: 0.965), text: "个性建议")
            }
            .padding(.top, 24)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(red: 0.953, green: 0.957, blue: 0.969))
                    .offset(y: -12),
                alignment: .top
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, -8)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.95),
                    Color(red: 0.996, green: 0.969, blue: 0.941),
                    Color(red: 0.941, green: 0.992, blue: 0.961)
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

struct FeatureHighlight: View {
    let dotColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
        }
    }
}


