//
//  AuthTextFieldStyle.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

// 认证表单文本输入框样式
struct AuthTextFieldStyle: TextFieldStyle {
    var isError: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isError ?
                        Color(red: 0.957, green: 0.263, blue: 0.212) :
                        Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
    }
}

// 为了向后兼容，创建别名
typealias LoginTextFieldStyle = AuthTextFieldStyle


