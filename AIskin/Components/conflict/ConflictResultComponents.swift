import SwiftUI

struct ConflictOverviewSection: View {
    let data: ConflictAnalysisData

    var body: some View {
        Group {
            if data.hasProductReport, let score = data.riskScore {
                AISkinReportScore(
                    label: "搭配风险评分", score: score, status: data.overallStatus,
                    hint: "0–5 分，越高越需谨慎 · 基于成分标签的模型估计",
                    summary: data.summary ?? ""
                )
            } else {
                AISkinCard {
                    AISkinReportTextItem(
                        title: data.hasProductReport ? "暂时无法完成风险评分" : "这份历史报告需要重新检测",
                        text: data.hasProductReport ? (data.summary ?? "产品信息不足，暂时无法判断。")
                            : "旧版报告未保存风险分数及产品之间的对应关系。重新检测后可查看产品结论和使用建议。"
                    )
                }
            }
        }
        .accessibilityIdentifier("conflict.summary")
    }
}

struct TestedProductsSection: View {
    let products: [ConflictProductInfo]
    @State private var expanded = false
    private var visible: [ConflictProductInfo] { products.count > 4 && !expanded ? Array(products.prefix(3)) : products }

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinReportTokens.headingGap) {
            AISkinReportHeading(number: "01", title: "本次检测产品", detail: "\(products.count) 件")
            AISkinCard {
                VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                    ForEach(Array(visible.enumerated()), id: \.offset) { index, product in
                        AISkinReportInsetCell {
                            HStack(spacing: AISkinSpacing.xSmall) {
                                Text("\(index + 1)").font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary)
                                Text(product.name ?? "产品名称未提供").font(AISkinReportTokens.itemTitle).foregroundStyle(AISkinColor.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    if products.count > 4 {
                        Button { expanded.toggle() } label: {
                            AISkinReportInsetCell {
                                Text(expanded ? "收起" : "更多 +\(products.count - 3)")
                                    .font(AISkinReportTokens.body).foregroundStyle(AISkinColor.accent)
                                    .frame(maxWidth: .infinity)
                            }
                        }.buttonStyle(AISkinPressableStyle()).accessibilityIdentifier("conflict.products.expand")
                    }
                }
            }
        }
    }
}

struct ConflictsDetailSection: View {
    let data: ConflictAnalysisData

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinReportTokens.headingGap) {
            AISkinReportHeading(number: "02", title: "产品搭配结论", detail: "\(data.productPairs?.count ?? 0) 组")
            ForEach(Array((data.productPairs ?? []).enumerated()), id: \.offset) { _, pair in
                AISkinCard {
                    VStack(alignment: .leading, spacing: AISkinReportTokens.rowGap) {
                        AISkinReportTextItem(title: pair.productIds.map { data.productName(for: $0) }.joined(separator: " + "), text: "")
                        AISkinReportTextItem(title: pair.status.title, text: pair.explanation)
                    }
                }
            }
        }
        .accessibilityIdentifier("conflict.product-pairs")
    }
}

struct RecommendationsDetailSection: View {
    let data: ConflictAnalysisData
    private var items: [ConflictAdvice] { data.recommendations?.advice ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinReportTokens.headingGap) {
            AISkinReportHeading(number: "03", title: "护肤建议")
            AISkinCard {
                VStack(alignment: .leading, spacing: AISkinReportTokens.rowGap) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        if index > 0 { AISkinDivider() }
                        AISkinReportTextItem(title: item.title, text: item.detail)
                        if (data.products?.count ?? 0) > 2 || item.productIds.count != data.products?.count {
                            AISkinReportTextItem(text: "适用：" + item.productIds.map { data.productName(for: $0) }.joined(separator: "、"))
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("conflict.advice")
    }
}

struct ConflictHistoryRecordCard: View {
    let record: ConflictRecord
    var body: some View {
        AISkinCard {
            VStack(alignment: .leading, spacing: AISkinSpacing.medium) {
                HStack {
                    Text(record.createdAt?.formatted(date: .numeric, time: .shortened) ?? "时间未记录")
                    Spacer()
                    Text("\(record.products?.count ?? 0) 件产品")
                }.font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.textSecondary)
                Text(record.products?.compactMap(\.name).joined(separator: " + ") ?? "产品信息未提供")
                    .font(AISkinReportTokens.conflictTitle).foregroundStyle(AISkinColor.textPrimary)
                    .multilineTextAlignment(.leading).lineSpacing(AISkinSpacing.xxSmall)
                HStack {
                    Label(record.reportData.overallStatus, systemImage: "square.3.layers.3d")
                    Spacer()
                    Image(systemName: "chevron.right")
                }.font(AISkinReportTokens.body).foregroundStyle(AISkinColor.accent)
            }
        }
    }
}
