//
//  HistoryModal.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct HistoryModal: View {
    @Binding var isPresented: Bool
    let historyList: [AnalysisResult]
    let onSelectHistory: (AnalysisResult) -> Void
    
    var body: some View {
        ZStack {
            // Overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal Card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("检测历史")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                            .frame(width: 36, height: 36)
                            .background(Color(red: 0.961, green: 0.961, blue: 0.961))
                            .cornerRadius(18)
                    }
                }
                .padding(20)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(red: 0.914, green: 0.918, blue: 0.933))
                        .offset(y: 20),
                    alignment: .bottom
                )
                
                // Content
                if historyList.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                        
                        Text("暂无检测历史")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(historyList.enumerated()), id: \.offset) { index, history in
                                HistoryItem(
                                    history: history,
                                    onTap: {
                                        onSelectHistory(history)
                                        isPresented = false
                                    }
                                )
                                
                                if index < historyList.count - 1 {
                                    Divider()
                                        .background(Color(red: 0.953, green: 0.957, blue: 0.969))
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 400)
            .frame(maxHeight: 600)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 40, x: 0, y: 20)
            .padding(.horizontal, 40)
        }
    }
}

struct HistoryItem: View {
    let history: AnalysisResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Score
                Text("\(history.healthScore)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.388, green: 0.388, blue: 0.976))
                    .frame(width: 50, alignment: .leading)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    if let date = history.createdAt {
                        Text(formatDate(date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                    }
                    
                    Text(history.summary ?? "无摘要")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.612, green: 0.612, blue: 0.624))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days <= 7 {
                return "\(days)天前"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.locale = Locale(identifier: "zh_CN")
                return formatter.string(from: date)
            }
        }
    }
}


