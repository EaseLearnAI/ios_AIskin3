//
//  AppHeader.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct AppHeader: View {
    var title: String
    var icon: String? = nil
    var rightIcon: String? = nil
    var rightAction: (() -> Void)? = nil
    var backAction: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Left and Right buttons
            HStack {
                if backAction != nil {
                    Button(action: backAction!) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                    }
                } else if rightIcon != nil {
                    // Empty space for alignment when no back button
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                
                Spacer()
                
                if let rightIcon = rightIcon, let rightAction = rightAction {
                    Button(action: rightAction) {
                        Image(systemName: rightIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                    }
                } else if backAction != nil {
                    // Empty space for alignment when no right icon
                    Color.clear
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 20)
            
            // Centered Title
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
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
        .lookinName("shared.header.\(title)")
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "搜索..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 12)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .frame(height: 36)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .lookinName("shared.search-bar")
    }
}
