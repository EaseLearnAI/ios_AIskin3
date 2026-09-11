import Foundation

struct AnalysisResult: Equatable {
    var healthScore: Int?
    var isSimulated = false
    var summary: String?
    var skinCondition: String?
    var skinType: SkinTypeData?
    var blackheads: BlackheadsData?
    var acne: AcneData?
    var pores: PoresData?
    var skinToneEvenness: SkinToneEvennessData?
    var redness: RednessData?
    var hyperpigmentation: HyperpigmentationData?
    var fineLines: FineLinesData?
    var sensitivity: SensitivityData?
    var oilLevel: String?
    var moistureLevel: String?
    var poreLevel: String?
    var recommendations: [String]?
    var createdAt: Date?
    var sourceID: String? = nil
    var context: SkinAnalysisContext? = nil
    var additionalIssueDescriptions: [SkinIssueDescription] = []
    var imageURL: URL? = nil
    var assessmentDetails: [SkinIssueDescription] = []
    
    // 简化的 Equatable 实现，只比较关键字段用于 onChange 检测
    static func == (lhs: AnalysisResult, rhs: AnalysisResult) -> Bool {
        return lhs.imageURL == rhs.imageURL &&
               lhs.assessmentDetails == rhs.assessmentDetails &&
               lhs.additionalIssueDescriptions == rhs.additionalIssueDescriptions &&
               lhs.sourceID == rhs.sourceID &&
               lhs.context?.condition == rhs.context?.condition &&
               lhs.context?.light == rhs.context?.light &&
               lhs.context?.feelings == rhs.context?.feelings &&
               lhs.healthScore == rhs.healthScore &&
               lhs.isSimulated == rhs.isSimulated &&
               lhs.summary == rhs.summary &&
               lhs.skinCondition == rhs.skinCondition &&
               lhs.oilLevel == rhs.oilLevel &&
               lhs.moistureLevel == rhs.moistureLevel &&
               lhs.poreLevel == rhs.poreLevel &&
               lhs.createdAt == rhs.createdAt
    }
}
