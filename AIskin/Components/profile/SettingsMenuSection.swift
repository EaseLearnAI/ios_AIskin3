//
//  SettingsMenuSection.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct SettingsMenuSection: View {
    let onUsernameEdit: () -> Void
    let onGenderEdit: () -> Void
    let onFeedback: () -> Void
    let onLogout: () -> Void
    let onDeleteAccount: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsMenuItem(
                icon: "person.fill",
                iconColor: Color(red: 0.259, green: 0.522, blue: 0.957),
                title: "编辑用户名",
                subtitle: "修改您的显示名称",
                action: onUsernameEdit
            )
            
            Divider()
                .padding(.leading, 60)
            
            SettingsMenuItem(
                icon: "person.2.fill",
                iconColor: Color(red: 0.600, green: 0.400, blue: 0.800),
                title: "编辑性别",
                subtitle: "设置您的性别信息",
                action: onGenderEdit
            )
            
            Divider()
                .padding(.leading, 60)
            
            SettingsMenuItem(
                icon: "questionmark.circle.fill",
                iconColor: Color(red: 0.227, green: 0.592, blue: 0.388),
                title: "帮助与反馈",
                subtitle: "提供使用建议和问题反馈",
                action: onFeedback
            )
            
            Divider()
                .padding(.leading, 60)
            
            SettingsMenuItem(
                icon: "arrow.right.square.fill",
                iconColor: Color(red: 0.957, green: 0.263, blue: 0.212),
                title: "退出登录",
                subtitle: "退出当前账号",
                action: onLogout,
                isDestructive: true
            )
            
            Divider()
                .padding(.leading, 60)
            
            SettingsMenuItem(
                icon: "trash.fill",
                iconColor: Color(red: 0.957, green: 0.263, blue: 0.212),
                title: "注销账户",
                subtitle: "永久删除账户及所有数据",
                action: onDeleteAccount,
                isDestructive: true
            )
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct SettingsMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    var isDestructive: Bool = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon Container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            iconColor.opacity(0.15)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(
                            isDestructive ?
                            Color(red: 0.957, green: 0.263, blue: 0.212) :
                            Color(red: 0.227, green: 0.227, blue: 0.235)
                        )
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                isPressed ?
                (isDestructive ?
                 Color(red: 0.957, green: 0.263, blue: 0.212).opacity(0.05) :
                 Color(red: 0.972, green: 0.733, blue: 0.816).opacity(0.1)) :
                Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

