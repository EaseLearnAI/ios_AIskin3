//
//  SkinStatusOverview.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct SkinStatusOverview: View {
    let blackheads: BlackheadsData?
    let acne: AcneData?
    let pores: PoresData?
    let skinToneEvenness: SkinToneEvennessData?
    let redness: RednessData?
    let hyperpigmentation: HyperpigmentationData?
    let fineLines: FineLinesData?
    let sensitivity: SensitivityData?
    
    var body: some View {
        VStack(spacing: 20) {
            // Card Header
            HStack {
                HStack(spacing: 8) {
                    Text("📊")
                        .font(.system(size: 20))
                    Text("皮肤状态总览")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.122, green: 0.161, blue: 0.227))
                }
                
                Spacer()
            }
            
            // Overall Assessment
            HStack(alignment: .top, spacing: 12) {
                Text("✨")
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 4) {
                    Text("综合评估：")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.972, green: 0.733, blue: 0.816))
                    Text(getOverallAssessment())
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.235))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(red: 0.980, green: 0.980, blue: 0.984))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.953, green: 0.957, blue: 0.969), lineWidth: 1)
            )
            
            // Issues List
            VStack(spacing: 0) {
                if let blackheads = blackheads, blackheads.exists {
                    IssueItem(
                        icon: "circle.fill",
                        iconColor: Color(red: 0.227, green: 0.227, blue: 0.235),
                        title: "黑头情况",
                        description: getBlackheadsDescription(blackheads),
                        status: blackheads.severity ?? "正常",
                        statusClass: getStatusClass(blackheads.severity ?? "正常")
                    )
                }
                
                if let acne = acne, acne.exists {
                    IssueItem(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: Color(red: 0.957, green: 0.263, blue: 0.212),
                        title: "痘痘情况",
                        description: getAcneDescription(acne),
                        status: acne.count ?? "正常",
                        statusClass: getStatusClass(acne.count ?? "正常")
                    )
                }
                
                if let pores = pores, pores.enlarged {
                    IssueItem(
                        icon: "circle.grid.2x2.fill",
                        iconColor: Color(red: 0.400, green: 0.498, blue: 0.918),
                        title: "毛孔状态",
                        description: getPoresDescription(pores),
                        status: pores.severity ?? "正常",
                        statusClass: getStatusClass(pores.severity ?? "正常")
                    )
                }
                
                if let skinToneEvenness = skinToneEvenness {
                    IssueItem(
                        icon: "paintpalette.fill",
                        iconColor: Color(red: 1.0, green: 0.584, blue: 0.0),
                        title: "肤色均匀度",
                        description: skinToneEvenness.description ?? "肤色均匀",
                        status: getSkinToneStatus(skinToneEvenness),
                        statusClass: getSkinToneStatusClass(skinToneEvenness)
                    )
                }
                
                if let redness = redness, redness.exists {
                    IssueItem(
                        icon: "heart.fill",
                        iconColor: Color(red: 0.957, green: 0.263, blue: 0.212),
                        title: "泛红情况",
                        description: getRednessDescription(redness),
                        status: redness.severity ?? "正常",
                        statusClass: getStatusClass(redness.severity ?? "正常")
                    )
                }
                
                IssueItem(
                    icon: "circle.fill",
                    iconColor: Color(red: 0.545, green: 0.298, blue: 0.965),
                    title: "色素沉着",
                    description: getHyperpigmentationDescription(),
                    status: getHyperpigmentationStatus(),
                    statusClass: getStatusClass(getHyperpigmentationStatus())
                )
                
                IssueItem(
                    icon: "waveform.path",
                    iconColor: Color(red: 0.400, green: 0.498, blue: 0.918),
                    title: "细纹状况",
                    description: getFineLinesDescription(),
                    status: getFineLinesStatus(),
                    statusClass: getStatusClass(getFineLinesStatus())
                )
                
                IssueItem(
                    icon: "shield.fill",
                    iconColor: Color(red: 0.294, green: 0.686, blue: 0.314),
                    title: "敏感程度",
                    description: getSensitivityDescription(),
                    status: getSensitivityStatus(),
                    statusClass: getStatusClass(getSensitivityStatus()),
                    isLast: true
                )
            }
        }
        .padding(32)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 24, x: 0, y: 8)
        .padding(.horizontal, 8)
    }
    
    private func getOverallAssessment() -> String {
        var issues: [String] = []
        if let blackheads = blackheads, blackheads.exists {
            issues.append("黑头情况：\(getBlackheadsDescription(blackheads))")
        }
        if let acne = acne, acne.exists {
            issues.append("痘痘情况：\(getAcneDescription(acne))")
        }
        if let pores = pores, pores.enlarged {
            issues.append("毛孔状态：\(getPoresDescription(pores))")
        }
        if issues.isEmpty {
            return "皮肤状态良好，无明显问题。"
        }
        return "皮肤状态总体良好，但有\(issues.count)个问题需要轻度关注：\(issues.joined(separator: "、"))"
    }
    
    private func getBlackheadsDescription(_ data: BlackheadsData) -> String {
        if !data.exists { return "无黑头" }
        if let distribution = data.distribution, !distribution.isEmpty {
            return distribution.joined(separator: "、")
        }
        return data.severity ?? "少量"
    }
    
    private func getAcneDescription(_ data: AcneData) -> String {
        if !data.exists { return "无痘痘" }
        if let distribution = data.distribution, !distribution.isEmpty {
            return distribution.joined(separator: "、")
        }
        return data.count ?? "少量"
    }
    
    private func getPoresDescription(_ data: PoresData) -> String {
        if !data.enlarged { return "毛孔正常" }
        if let distribution = data.distribution, !distribution.isEmpty {
            return distribution.joined(separator: "、")
        }
        return data.severity ?? "中度"
    }
    
    private func getRednessDescription(_ data: RednessData) -> String {
        if !data.exists { return "无泛红" }
        if let distribution = data.distribution, !distribution.isEmpty {
            return distribution.joined(separator: "、")
        }
        return data.severity ?? "轻度"
    }
    
    private func getHyperpigmentationDescription() -> String {
        guard let data = hyperpigmentation, data.exists else {
            return "无明显色素沉着"
        }
        if let description = data.description, !description.isEmpty {
            return description
        }
        let types = data.types ?? []
        let distribution = data.distribution ?? []
        if !types.isEmpty {
            let typeText = types.joined(separator: "、")
            let distText = distribution.isEmpty ? "" : distribution.joined(separator: "、")
            return distText.isEmpty ? typeText : "\(distText)\(typeText)"
        }
        return "轻微色素沉着"
    }
    
    private func getHyperpigmentationStatus() -> String {
        guard let data = hyperpigmentation, data.exists else {
            return "无"
        }
        return data.severity ?? "轻度"
    }
    
    private func getFineLinesDescription() -> String {
        guard let data = fineLines, data.exists else {
            return "无明显细纹"
        }
        if let description = data.description, !description.isEmpty {
            return description
        }
        let distribution = data.distribution ?? []
        if !distribution.isEmpty {
            return "\(distribution.joined(separator: "、"))轻微细纹"
        }
        return "轻微细纹"
    }
    
    private func getFineLinesStatus() -> String {
        guard let data = fineLines, data.exists else {
            return "无"
        }
        return data.severity ?? "轻度"
    }
    
    private func getSensitivityDescription() -> String {
        guard let data = sensitivity, data.exists else {
            return "肌肤不敏感"
        }
        if let description = data.description, !description.isEmpty {
            return description
        }
        let signs = data.signs ?? []
        if !signs.isEmpty {
            return "出现\(signs.joined(separator: "、"))等敏感症状"
        }
        return "轻度敏感肌"
    }
    
    private func getSensitivityStatus() -> String {
        guard let data = sensitivity, data.exists else {
            return "无"
        }
        return data.severity ?? "轻度"
    }
    
    private func getSkinToneStatus(_ data: SkinToneEvennessData) -> String {
        let score = data.score ?? 0
        if score >= 8 { return "优秀" }
        if score >= 6 { return "良好" }
        if score >= 4 { return "一般" }
        return "需改善"
    }
    
    private func getSkinToneStatusClass(_ data: SkinToneEvennessData) -> StatusClass {
        let score = data.score ?? 0
        if score >= 6 { return .good }
        if score >= 4 { return .mild }
        return .moderate
    }
    
    private func getStatusClass(_ severity: String) -> StatusClass {
        switch severity {
        case "无", "正常", "良好":
            return .good
        case "轻度", "少量":
            return .mild
        case "中度":
            return .moderate
        case "大量", "严重":
            return .severe
        default:
            return .good
        }
    }
}

struct IssueItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let status: String
    let statusClass: StatusClass
    var isLast: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.953, green: 0.957, blue: 0.969))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.122, green: 0.161, blue: 0.227))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.420, green: 0.451, blue: 0.502))
            }
            
            Spacer()
            
            // Status Badge
            StatusBadge(status: status, statusClass: statusClass)
        }
        .padding(.vertical, 16)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(red: 0.953, green: 0.957, blue: 0.969))
                .offset(y: -0.5),
            alignment: .top
        )
        .background(
            isLast ? Color.clear : Color.clear
        )
    }
}

struct StatusBadge: View {
    let status: String
    let statusClass: StatusClass
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusClass.dotColor)
                .frame(width: 8, height: 8)
            
            Text(status)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusClass.textColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusClass.backgroundColor)
        .cornerRadius(20)
    }
}

enum StatusClass {
    case good, mild, moderate, severe
    
    var backgroundColor: Color {
        switch self {
        case .good: return Color(red: 0.925, green: 0.992, blue: 0.961)
        case .mild: return Color(red: 1.0, green: 0.984, blue: 0.922)
        case .moderate: return Color(red: 0.996, green: 0.922, blue: 0.933)
        case .severe: return Color(red: 0.996, green: 0.922, blue: 0.933)
        }
    }
    
    var textColor: Color {
        switch self {
        case .good: return Color(red: 0.024, green: 0.373, blue: 0.275)
        case .mild: return Color(red: 0.573, green: 0.251, blue: 0.055)
        case .moderate: return Color(red: 0.600, green: 0.106, blue: 0.106)
        case .severe: return Color(red: 0.498, green: 0.114, blue: 0.114)
        }
    }
    
    var dotColor: Color {
        switch self {
        case .good: return Color(red: 0.063, green: 0.722, blue: 0.506)
        case .mild: return Color(red: 0.961, green: 0.620, blue: 0.043)
        case .moderate: return Color(red: 0.933, green: 0.267, blue: 0.267)
        case .severe: return Color(red: 0.863, green: 0.149, blue: 0.149)
        }
    }
}

// Supporting Data Models
struct BlackheadsData {
    var exists: Bool
    var severity: String?
    var distribution: [String]?
}

struct AcneData {
    var exists: Bool
    var count: String?
    var types: [String]?
    var distribution: [String]?
}

struct PoresData {
    var enlarged: Bool
    var severity: String?
    var distribution: [String]?
}

struct SkinToneEvennessData {
    var score: Int?
    var description: String?
}

struct RednessData {
    var exists: Bool
    var severity: String?
    var description: String?
    var distribution: [String]?
}

struct HyperpigmentationData {
    var exists: Bool
    var severity: String?
    var description: String?
    var types: [String]?
    var distribution: [String]?
}

struct FineLinesData {
    var exists: Bool
    var severity: String?
    var description: String?
    var distribution: [String]?
}

struct SensitivityData {
    var exists: Bool
    var severity: String?
    var description: String?
    var signs: [String]?
}

