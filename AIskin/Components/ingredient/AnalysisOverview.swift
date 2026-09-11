import SwiftUI

struct AnalysisOverview: View {
    let analysis: IngredientAnalysis

    var body: some View {
        AISkinReportScore(label: "AI 综合评分", score: analysis.overallRating,
                          title: "产品总结", summary: analysis.summary, layout: .summaryFirst)
    }
}

extension IngredientAnalysis {
    var scoreDetails: String {
        "安全性指数：\(safetyIndex.formatted()) / 100\n\(efficacyScoreDetail)\n活性成分：\(activeIngredients) 项"
    }

    private var efficacyScoreDetail: String {
        if (0...5).contains(efficacyScore) {
            return "功效评分：\(efficacyScore.formatted()) / 5"
        }
        return "功效评分原值：\(efficacyScore.formatted())（历史量表未知）"
    }

    var riskDetails: String {
        [("致痘", acneRisk), ("刺激", irritationRisk), ("过敏", allergyRisk)]
            .map { "\($0.0)：\($0.1.level)（模型风险指数 \($0.1.percentage.formatted()) / 100）" }
            .joined(separator: "\n")
    }
}
