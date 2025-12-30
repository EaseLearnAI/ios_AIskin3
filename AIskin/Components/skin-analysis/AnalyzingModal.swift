//
//  AnalyzingModal.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct AnalyzingModal: View {
    let progress: Double
    let status: String
    
    var body: some View {
        ZStack {
            // Overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .blur(radius: 8)
            
            // Modal Card
            VStack(spacing: 24) {
                // Spinner
                ZStack {
                    Circle()
                        .stroke(Color(red: 0.972, green: 0.733, blue: 0.816).opacity(0.2), lineWidth: 4)
                        .frame(width: 64, height: 64)
                    
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color(red: 0.972, green: 0.733, blue: 0.816), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
                }
                
                // Title
                Text("AI正在分析中...")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                
                // Subtitle
                Text(status)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                
                // Progress Bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 8)
                            
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
                                .frame(width: geometry.size.width * (progress / 100), height: 8)
                                .animation(.easeOut(duration: 0.3), value: progress)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(Int(progress))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                }
                
                // Tip
                Text("请稍候，通常需要10-30秒完成分析")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(Color(red: 0.612, green: 0.612, blue: 0.624))
            }
            .padding(40)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.98),
                        Color.white.opacity(0.95)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 40, x: 0, y: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
    }
}

