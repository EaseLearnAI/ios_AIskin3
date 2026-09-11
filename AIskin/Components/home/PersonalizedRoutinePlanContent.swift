//
//  PersonalizedRoutinePlanContent.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct PersonalizedRoutinePlanContent: View {
    let plan: SkinPlan

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xLarge) {
            VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                Label(plan.name, systemImage: "sparkles")
                    .font(AISkinTypography.cardTitle)
                    .foregroundStyle(AISkinColor.textPrimary)

                Text(plan.creatorNote ?? "日常基础护肤")
                    .font(AISkinTypography.callout)
                    .foregroundStyle(AISkinColor.textSecondary)
            }

            Divider()
                .overlay(AISkinColor.divider)

            if !plan.morning.isEmpty {
                RoutinePreviewSection(
                    title: "早间护理",
                    icon: "sun.max.fill",
                    items: plan.morning
                )
            }

            if !plan.evening.isEmpty {
                RoutinePreviewSection(
                    title: "晚间护理",
                    icon: "moon.fill",
                    items: plan.evening
                )
            }

            if !plan.recommendations.isEmpty {
                RecommendationsPreviewSection(recommendations: plan.recommendations)
            }
        }
        .aiSkinGeneratedResult()
    }
}

struct RoutinePreviewSection: View {
    let title: String
    let icon: String
    let items: [RoutineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
            Label(title, systemImage: icon)
                .font(AISkinTypography.bodyEmphasized)
                .foregroundStyle(AISkinColor.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    AISkinPlanRoutineRow(
                        number: item.step ?? index + 1,
                        title: item.product ?? "步骤名称未提供",
                        detail: item.reason
                    )

                    if index < items.count - 1 {
                        AISkinDivider()
                    }
                }
            }
        }
    }
}

struct RecommendationsPreviewSection: View {
    let recommendations: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
            Label("专业建议", systemImage: "lightbulb")
                .font(AISkinTypography.bodyEmphasized)
                .foregroundStyle(AISkinColor.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, tip in
                    AISkinListRow {
                        HStack(alignment: .top, spacing: AISkinSpacing.small) {
                            Image(systemName: "checkmark.circle")
                                .font(AISkinTypography.iconSmall)
                                .foregroundStyle(AISkinColor.textSecondary)
                                .padding(.top, AISkinSpacing.xxxSmall)

                            Text(tip)
                                .font(AISkinTypography.body)
                                .foregroundStyle(AISkinColor.textSecondary)

                            Spacer()
                        }
                    }

                    if index < recommendations.count - 1 {
                        Divider()
                            .overlay(AISkinColor.divider)
                    }
                }
            }
        }
    }
}
