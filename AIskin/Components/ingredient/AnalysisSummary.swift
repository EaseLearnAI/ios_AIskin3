import SwiftUI

enum IngredientReportSection: String, CaseIterable, Hashable {
    case effects = "功效"
    case risks = "风险"
    case advice = "建议"
    case ingredients = "成分"

    var itemLabel: String { rawValue }
}

struct IngredientTextSection: View {
    let section: IngredientReportSection
    let number: String
    let title: String
    let systemImage: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinReportTokens.headingGap) {
            AISkinReportHeading(number: number, title: title, systemImage: systemImage, style: .reading)
                .aiSkinReportScrollTarget(section)
            AISkinCard {
                VStack(alignment: .leading, spacing: AISkinReportTokens.readingRowGap) {
                    if items.isEmpty { AISkinReportTextItem(text: "本次分析未提供此项内容。", style: .reading) }
                    ForEach(Array(items.enumerated()), id: \.offset) { index, text in
                        if index > 0 { AISkinDivider() }
                        let item = IngredientReportItem(text, fallbackTitle: "\(section.itemLabel) \(index + 1)")
                        AISkinReportTextItem(title: item.title, text: item.text, style: .reading)
                    }
                }
            }
        }
    }
}

struct IngredientListSection: View {
    let ingredients: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: AISkinReportTokens.headingGap) {
            AISkinReportHeading(number: "04", title: "主要成分", detail: "\(ingredients.count) 项")
                .aiSkinReportScrollTarget(IngredientReportSection.ingredients)
                .accessibilityIdentifier("ingredient.heading.ingredients")
            Text("以下为图片识别结果，可能存在错字或遗漏，请与包装核对。").font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary)
            AISkinReportScrollCard {
                VStack(spacing: 0) {
                    if ingredients.isEmpty { AISkinReportTextItem(text: "本次未返回成分明细。") }
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { index, name in
                        if index > 0 { AISkinDivider() }
                        AISkinReportDisclosureRow(
                            number: String(format: "%02d", index + 1),
                            title: name,
                            subtitle: "单项资料未提供",
                            detail: "本次报告未提供该成分的单项作用与浓度，不代表完整 INCI 顺序。"
                        )
                    }
                }
            }
            .accessibilityIdentifier("ingredient.list.scroll")
        }
    }
}
