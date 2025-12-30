//
//  AddProduct.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct AddProduct: View {
    @Binding var showUploadModal: Bool
    let onEnableConflictMode: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.973, green: 0.741, blue: 0.816))
                
                Text("添加新产品到猫窝")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Add Product Button
                Button(action: { showUploadModal = true }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.604, blue: 0.620),
                                            Color(red: 0.996, green: 0.812, blue: 0.937)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Text("添加产品")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                        
                        Text("猫眼扫描成分")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.980, green: 0.953, blue: 0.984))
                    .cornerRadius(12)
                }
                
                // Conflict Detection Button
                Button(action: onEnableConflictMode) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.604, blue: 0.620),
                                            Color(red: 0.996, green: 0.812, blue: 0.937)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Text("产品冲突成分检测")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                        
                        Text("检测产品成分间潜在冲突")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.980, green: 0.953, blue: 0.984))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(red: 1.0, green: 0.714, blue: 0.757).opacity(0.15), radius: 20, x: 0, y: 8)
    }
}




