//
//  AuthHeader.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

// 底部圆角形状
struct BottomRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )
        path.closeSubpath()
        
        return path
    }
}

struct AuthHeader: View {
    let title: String
    let subtitle: String
    let showBackButton: Bool
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 返回按钮
                if showBackButton {
                    HStack {
                        Button(action: {
                            onBack?()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 12)
                        Spacer()
                    }
                }
                
                VStack(spacing: 8) {
                    AISkinLogoMark(size: 60)
                    .padding(.top, showBackButton ? 4 : 16)
                    
                    // App名称
                    Text("析肤护肤助手")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    // 标题
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 1)
                    
                    // 副标题
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.9))
                            .padding(.top, 1)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: showBackButton ? 180 : 200)
        // The background is one continuous shape that extends behind the
        // status bar. Keeping the clipping on the background (instead of the
        // whole header) removes the visible safe-area color seam.
        .background(alignment: .bottom) {
            BottomRoundedRectangle(cornerRadius: 30)
                .fill(AISkinAuthStyle.gradient)
                .frame(maxWidth: .infinity)
                .frame(height: (showBackButton ? 180 : 200) + 100)
                .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        AuthHeader(
            title: "欢迎回来",
            subtitle: "开始你的护肤之旅喵～",
            showBackButton: false
        )
        Spacer()
    }
}
