//
//  TwentyOneDayPlanCardView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct TwentyOneDayPlanCardView: View {
    var body: some View {
        NavigationLink(destination: Text("21天计划页面")) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("21天护肤计划")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.906, green: 0.325, blue: 0.502))
                    
                    Text("点击开启你的21天护肤挑战！")
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.722, green: 0.361, blue: 0.557))
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color(red: 1.0, green: 0.894, blue: 0.925))
            .cornerRadius(12)
            .shadow(color: Color(red: 1.0, green: 0.682, blue: 0.788).opacity(0.15), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


