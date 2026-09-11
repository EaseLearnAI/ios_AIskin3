import Foundation

extension AnalysisResult {
    /// Summaries use recorded findings only. Free-form observations and scores
    /// do not establish a concern without a structured positive finding.
    var reportObservations: [AISkinSkinReportObservation] {
        var rows: [AISkinSkinReportObservation] = []
        let missingDetailText = "本次仅记录了上述结果，未提供具体部位或详细说明。"
        func recorded(_ value: String?) -> String? {
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
            return value
        }
        func presence(_ exists: Bool?) -> String? { exists.map { $0 ? "有" : "未见" } }
        func firstSentence(_ text: String) -> String {
            guard let boundary = text.firstIndex(where: { "。！？!?\n".contains($0) }) else { return "\(text)。" }
            if text[boundary] != "\n" { return String(text[...boundary]) }
            return "\(text[..<boundary])。"
        }
        func isRecordedConcern(_ status: String?) -> Bool {
            guard let status = recorded(status) else { return false }
            if let number = Double(status) { return number > 0 }
            return ["轻微", "轻度", "少量", "少许", "中度", "较明显", "明显", "重度", "严重", "较多", "大量"].contains(status)
        }
        func add(_ id: String, _ name: String, _ rawStatus: String?, _ distribution: [String]?, _ description: String?, exists: Bool? = nil, extraDetails: [String?] = []) {
            let location = (distribution ?? []).compactMap { recorded($0) }.joined(separator: "、")
            let suppliedStatus = recorded(rawStatus)
            let status = exists == false ? "未见" : suppliedStatus ?? presence(exists)
            let isConcern = exists == false ? false : exists == true || isRecordedConcern(suppliedStatus)
            let originalDescription = recorded(description)
            var detailLines = ([originalDescription] + extraDetails + [location.isEmpty ? nil : "记录部位：\(location)"]).compactMap { recorded($0) }
            // Keep conflicting source values visible without presenting a known
            // negative finding as a positive concern in the summary or badge.
            if exists == false, let suppliedStatus, suppliedStatus != "未见" {
                detailLines.append("原始程度记录：\(suppliedStatus)")
            }
            guard status != nil || !detailLines.isEmpty else { return }
            if detailLines.isEmpty {
                detailLines.append(missingDetailText)
            }

            let subject = id == "pores" ? "毛孔粗大" : id == "sensitivity" ? "敏感表现" : name
            let summary: String
            if exists == false {
                summary = "本次记录未见\(subject)。"
            } else if let originalDescription {
                summary = firstSentence(originalDescription)
            } else if isConcern {
                let locationPrefix = location.isEmpty ? "本次" : location
                if let status, isRecordedConcern(status), Double(status) == nil {
                    summary = "\(locationPrefix)记录有\(status)\(subject)。"
                } else {
                    summary = "\(locationPrefix)记录有\(subject)。"
                }
            } else if let status {
                summary = "本次\(name)记录为\(status)。"
            } else if !location.isEmpty {
                summary = "本次\(name)观察记录在\(location)。"
            } else {
                summary = "\(name)已有观察记录，尚未明确程度。"
            }
            rows.append(AISkinSkinReportObservation(id: id, title: name, status: status, details: detailLines.joined(separator: "\n"), summary: summary, isConcern: isConcern))
        }
        if let value = redness { add("redness", "泛红", value.severity, value.distribution, value.description, exists: value.exists) }
        if let value = pores { add("pores", "毛孔", value.severity, value.distribution, value.description, exists: value.enlarged) }
        if let value = acne {
            add("acne", "痘痘", recorded(value.severity) ?? recorded(value.count), value.distribution, value.description, exists: value.exists,
                extraDetails: [value.count.map { "数量：\($0)" }, value.types?.joined(separator: "、"), value.activity.map { "活动情况：\($0)" }])
        }
        if let value = blackheads { add("blackheads", "黑头", value.severity, value.distribution, value.description, exists: value.exists) }
        if let value = hyperpigmentation {
            add("hyperpigmentation", "色素沉着", value.severity, value.distribution, value.description, exists: value.exists,
                extraDetails: [value.types?.joined(separator: "、")])
        }
        if let value = fineLines { add("fineLines", "细纹", value.severity, value.distribution, value.description, exists: value.exists) }
        if let value = sensitivity {
            add("sensitivity", "敏感观察", value.severity, nil, value.description, exists: value.exists,
                extraDetails: [value.signs?.joined(separator: "、")])
        }
        if let value = skinToneEvenness {
            add("skinToneEvenness", "肤色均匀度", value.score.map { "\($0) 分" }, nil, value.description)
        }
        for observation in additionalIssueDescriptions {
            if let index = rows.firstIndex(where: { $0.id == observation.field }) {
                let original = rows[index]
                let texts = observation.texts.compactMap { recorded($0) }
                let originalDetails = original.details == missingDetailText && !texts.isEmpty ? [] : [original.details]
                rows[index] = AISkinSkinReportObservation(id: original.id, title: original.title, status: original.status, details: (originalDetails + texts).joined(separator: "\n"), summary: original.summary, isConcern: original.isConcern)
            } else {
                let texts = observation.texts.compactMap { recorded($0) }
                guard let first = texts.first else { continue }
                rows.append(AISkinSkinReportObservation(id: observation.field, title: observation.title, status: nil, details: texts.joined(separator: "\n"), summary: firstSentence(first), isConcern: false))
            }
        }
        return rows
    }

    /// Assessment context remains available alongside findings, but never
    /// contributes to the count or styling of recorded concerns.
    var reportAssessmentObservations: [AISkinSkinReportObservation] {
        assessmentDetails.compactMap { assessment in
            let texts = assessment.texts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            guard let summary = texts.first else { return nil }
            return AISkinSkinReportObservation(
                id: "assessment.\(assessment.field)",
                title: assessment.title,
                status: nil,
                details: texts.joined(separator: "\n"),
                summary: summary,
                isConcern: false
            )
        }
    }

    var reportMetrics: [AISkinSummaryMetric] {
        reportObservations.prefix(3).map { observation in
            AISkinSummaryMetric(title: observation.title, value: observation.status ?? "已记录观察", level: Self.reportLevel(observation.status))
        }
    }

    private static func reportLevel(_ status: String?) -> Int {
        switch status {
        case "轻微": 1
        case "轻度", "少量": 2
        case "中度", "较明显": 3
        case "明显": 4
        case "重度", "严重": 5
        default: 0
        }
    }
}

/// Presentation separates a recognized capture state from legacy free-form
/// condition text. The original context remains untouched and visible in detail.
extension SkinAnalysisContext {
    var reportCaptureState: String? {
        guard let value = condition?.trimmingCharacters(in: .whitespacesAndNewlines),
              ["纯素颜", "护肤后", "上妆后", "特殊时期"].contains(value) else { return nil }
        return value
    }

    var reportConditionNote: String? {
        guard reportCaptureState == nil, let condition,
              !condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return condition
    }

    var reportStatus: String {
        reportCaptureState ?? (reportConditionNote == nil ? "未记录状态" : "已记录")
    }

    var reportDetailText: String {
        var lines = ["拍摄状态：\(reportCaptureState ?? "未记录")"]
        if let note = reportConditionNote { lines.append("记录备注：\(note)") }
        let recordedLight = light?.trimmingCharacters(in: .whitespacesAndNewlines)
        lines.append("拍摄光线：\(recordedLight.flatMap { $0.isEmpty ? nil : $0 } ?? "未记录")")
        let recordedFeelings = (feelings ?? []).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        lines.append("实际肤感：\(recordedFeelings.isEmpty ? "未补充" : recordedFeelings.joined(separator: "、"))")
        return lines.joined(separator: "\n")
    }
}
