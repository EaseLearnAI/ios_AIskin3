//
//  BottomNavigationView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct BottomNavigationView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabButton(
                icon: "house.fill",
                label: "首页",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                icon: "flask.fill",
                label: "产品分析",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            TabButton(
                icon: "camera.fill",
                label: "肌肤检测",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            TabButton(
                icon: "person.fill",
                label: "我的",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
        }
        .frame(height: 60)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -2)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .top
        )
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? Color(red: 0.905, green: 0.298, blue: 0.235) : Color(red: 0.557, green: 0.557, blue: 0.576))
            .frame(maxWidth: .infinity)
        }
    }
}

