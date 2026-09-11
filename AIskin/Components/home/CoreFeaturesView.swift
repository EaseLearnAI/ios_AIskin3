//
//  CoreFeaturesView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct CoreFeaturesView: View {
    @Environment(AppRouter.self) private var router

    private let columns = [
        GridItem(.flexible(), spacing: AISkinSpacing.small),
        GridItem(.flexible(), spacing: AISkinSpacing.small)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AISkinSpacing.small) {
            AISkinActionTile(title: "护肤柜", subtitle: "收纳产品 · 查看成分", systemImage: "shippingbox") {
                router.showProducts()
            }
            .accessibilityIdentifier("home.feature.products")
            AISkinActionTile(title: "冲突检测", subtitle: "检查多件产品搭配", systemImage: "checkmark.shield") {
                router.showConflictSelection()
            }
            .accessibilityIdentifier("home.feature.conflicts")
            AISkinActionTile(title: "肌肤检测", subtitle: "分析当前面部肤况", systemImage: "faceid") {
                router.showSkinAnalysis()
            }
            .accessibilityIdentifier("home.feature.skin")
            AISkinActionTile(title: "个性化方案", subtitle: "用护肤柜里的产品\n安排早晚护肤", systemImage: "sparkles") {
                router.showPersonalizedPlan()
            }
            .accessibilityIdentifier("home.feature.plan")
        }
    }
}
