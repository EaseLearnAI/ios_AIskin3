//
//  SkinAnalysisHeader.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct SkinAnalysisHeader: View {
    var onShowHistory: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Left and Right buttons
            HStack {
                // Always show back button if provided
                if onBack != nil {
                    Button(action: onBack!) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(18)
                    }
                } else {
                    // Empty space for alignment when no back button
                    Color.clear
                        .frame(width: 36, height: 36)
                }
                
                Spacer()
                
                // History button (optional)
                if let onShowHistory = onShowHistory {
                    Button(action: onShowHistory) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(18)
                    }
                } else {
                    // Empty space for alignment when no history button
                    Color.clear
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)
            
            // Centered Title
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 18))
                Text("皮肤状态检测")
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundColor(.white)
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
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 2)
    }
}


