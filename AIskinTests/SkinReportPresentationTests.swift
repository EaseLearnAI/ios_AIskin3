import XCTest
@testable import AIskin

@MainActor
final class SkinReportPresentationTests: XCTestCase {
    func testReportPreservesEveryRecordedIssueDetail() throws {
        let payload = #"""
        {"_id":"complete-report",
         "blackheads":{"exists":true,"severity":"轻度","description":"黑头原始描述","distribution":["鼻部"]},
         "pores":{"enlarged":true,"description":"毛孔原始描述"},
         "acne":{"exists":true,"severity":"中度","count":"少量","types":["丘疹"],"activity":"中度活跃","description":"痘痘原始描述","distribution":["额头"]},
         "otherIssues":{"hyperpigmentation":{"types":["痘印"],"description":"色素原始描述"},
                        "sensitivity":{"signs":["脱屑"],"description":"敏感原始描述"},
                        "skinToneEvenness":{"score":76}}}
        """#
        let analysis = try JSONDecoder.apiDecoder.decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        let observations = Dictionary(uniqueKeysWithValues: report.reportObservations.map { ($0.id, $0) })
        XCTAssertTrue(try XCTUnwrap(observations["blackheads"]).details.contains("黑头原始描述"))
        XCTAssertTrue(try XCTUnwrap(observations["pores"]).details.contains("毛孔原始描述"))
        let acne = try XCTUnwrap(observations["acne"])
        XCTAssertEqual(acne.status, "中度")
        for text in ["少量", "丘疹", "中度活跃", "痘痘原始描述", "额头"] { XCTAssertTrue(acne.details.contains(text)) }
        for text in ["痘印", "色素原始描述"] { XCTAssertTrue(try XCTUnwrap(observations["hyperpigmentation"]).details.contains(text)) }
        for text in ["脱屑", "敏感原始描述"] { XCTAssertTrue(try XCTUnwrap(observations["sensitivity"]).details.contains(text)) }
        XCTAssertEqual(observations["skinToneEvenness"]?.status, "76 分")
    }

    func testMissingFindingDoesNotBecomeNegativeAndExplicitNegativeRemainsVisible() throws {
        let payload = #"{"_id":"presence","blackheads":{"description":"仅有描述"},"pores":{"enlarged":false},"acne":{"exists":false}}"#
        let analysis = try JSONDecoder.apiDecoder.decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        XCTAssertNil(report.blackheads?.exists)
        XCTAssertNil(report.reportObservations.first(where: { $0.id == "blackheads" })?.status)
        XCTAssertEqual(report.reportObservations.first(where: { $0.id == "pores" })?.status, "未见")
        XCTAssertEqual(report.reportObservations.first(where: { $0.id == "acne" })?.status, "未见")
        XCTAssertTrue(report.reportObservations.allSatisfy { !$0.isConcern })
        XCTAssertTrue(report.reportObservations.allSatisfy { !$0.summary.isEmpty && !$0.details.isEmpty })
    }

    func testCompleteIssueListHasSummariesAndPreservesAdditionalObservations() throws {
        let payload = #"""
        {"_id":"all-issues",
         "blackheads":{"exists":true,"severity":"少量","distribution":["鼻翼"]},
         "pores":{"enlarged":true,"severity":"轻度"},
         "acne":{"exists":true,"count":"少量","types":["炎性丘疹","粉刺"],"activity":"轻度活跃","description":"右脸颊可见少量丘疹。需结合后续观察。","distribution":["右脸颊"]},
         "otherIssues":{"redness":{"severity":"轻度","description":"局部淡红，光照可能影响判断。未见明显毛细血管扩张。"},
                        "hyperpigmentation":{"exists":true,"types":["炎症后色素沉着"]},
                        "fineLines":{"exists":false},
                        "sensitivity":{"severity":"轻微","signs":["轻微脱屑"]},
                        "skinToneEvenness":{"score":35},
                        "texture":["面部整体肤质较平整。","未见明显粗糙或脱屑。"],
                        "observations":[{"category":"redness","details":["右侧鼻翼旁可见局部红斑。"]}]}}
        """#
        let analysis = try JSONDecoder.apiDecoder.decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        let rows = report.reportObservations
        XCTAssertEqual(rows.count, 9, "The full detail projection must not inherit the three-label limit")
        XCTAssertTrue(rows.allSatisfy { !$0.summary.isEmpty && !$0.details.isEmpty })
        let redness = try XCTUnwrap(rows.first { $0.id == "redness" })
        XCTAssertEqual(redness.summary, "局部淡红，光照可能影响判断。")
        XCTAssertTrue(redness.details.contains("未见明显毛细血管扩张。"))
        XCTAssertTrue(redness.details.contains("右侧鼻翼旁可见局部红斑。"))
        XCTAssertTrue(redness.isConcern)
        let blackheads = try XCTUnwrap(rows.first { $0.id == "blackheads" })
        XCTAssertEqual(blackheads.summary, "鼻翼记录有少量黑头。")
        XCTAssertTrue(blackheads.isConcern)
        let acne = try XCTUnwrap(rows.first { $0.id == "acne" })
        XCTAssertEqual(acne.summary, "右脸颊可见少量丘疹。")
        for text in ["需结合后续观察。", "数量：少量", "炎性丘疹、粉刺", "活动情况：轻度活跃", "记录部位：右脸颊"] {
            XCTAssertTrue(acne.details.contains(text))
        }
        let texture = try XCTUnwrap(rows.first { $0.id == "texture" })
        XCTAssertEqual(texture.summary, "面部整体肤质较平整。")
        XCTAssertTrue(texture.details.contains("未见明显粗糙或脱屑。"))
        XCTAssertFalse(texture.isConcern)
        XCTAssertEqual(report.reportMetrics.count, 3)
    }

    func testExplicitNegativeOverridesConcernStylingWithoutDroppingConflictingSource() throws {
        let payload = #"{"_id":"negative","blackheads":{"exists":false,"severity":"轻度","description":"照片未能确认黑头。"},"pores":{"enlarged":false,"severity":"明显"},"acne":{"exists":false,"count":"少量"}}"#
        let analysis = try JSONDecoder.apiDecoder.decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        XCTAssertEqual(report.reportObservations.count, 3)
        for observation in report.reportObservations {
            XCTAssertFalse(observation.isConcern)
            XCTAssertEqual(observation.status, "未见")
            XCTAssertTrue(observation.summary.hasPrefix("本次记录未见"))
        }
        let blackheads = try XCTUnwrap(report.reportObservations.first { $0.id == "blackheads" })
        XCTAssertTrue(blackheads.details.contains("照片未能确认黑头。"))
        XCTAssertTrue(blackheads.details.contains("原始程度记录：轻度"))
        let acne = try XCTUnwrap(report.reportObservations.first { $0.id == "acne" })
        XCTAssertTrue(acne.details.contains("数量：少量"))
    }

    func testOnlyStructuredPositiveFindingsBecomeConcerns() throws {
        let payload = #"""
        {"_id":"concern-boundaries",
         "blackheads":{"severity":"0"},"pores":{"enlarged":true},"acne":{"count":"3"},
         "otherIssues":{"redness":{"severity":"轻度"},"fineLines":{"severity":"未见明显"},
                        "sensitivity":{"description":"可能有敏感表现，但无法从照片确认。"},
                        "skinToneEvenness":{"score":10},"texture":"可见纹理变化，原因尚不明确。"}}
        """#
        let analysis = try JSONDecoder.apiDecoder.decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        let concerned = Set(report.reportObservations.filter(\.isConcern).map(\.id))
        XCTAssertEqual(concerned, ["pores", "acne", "redness"])
        let sensitivity = try XCTUnwrap(report.reportObservations.first { $0.id == "sensitivity" })
        XCTAssertNil(sensitivity.status)
        XCTAssertEqual(sensitivity.summary, "可能有敏感表现，但无法从照片确认。")
        XCTAssertEqual(sensitivity.details, "可能有敏感表现，但无法从照片确认。")
        let tone = try XCTUnwrap(report.reportObservations.first { $0.id == "skinToneEvenness" })
        XCTAssertEqual(tone.summary, "本次肤色均匀度记录为10 分。")
        XCTAssertFalse(tone.isConcern)
    }

    func testDetailsDoNotAppendDuplicateSeverityAndStatusOnlyRowsStayVisible() throws {
        let payload = #"{"_id":"status-only","blackheads":{"severity":"少量","distribution":["鼻翼"]},"pores":{"severity":"轻度"},"otherIssues":{"redness":{"severity":"轻微","description":"局部淡红。"},"fineLines":{"exists":false},"observations":[{"category":"pores","details":["仅鼻翼有记录。"]}]}}"#
        let analysis = try JSONDecoder.apiDecoder.decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        let rows = Dictionary(uniqueKeysWithValues: report.reportObservations.map { ($0.id, $0) })
        XCTAssertEqual(rows["blackheads"]?.details, "记录部位：鼻翼")
        XCTAssertEqual(rows["redness"]?.details, "局部淡红。")
        XCTAssertEqual(rows["pores"]?.details, "仅鼻翼有记录。", "A later source detail must replace the missing-detail fallback")
        let fineLines = try XCTUnwrap(rows["fineLines"])
        XCTAssertEqual(fineLines.status, "未见")
        XCTAssertEqual(fineLines.summary, "本次记录未见细纹。")
        XCTAssertTrue(fineLines.details.contains("未提供具体部位或详细说明"))
        XCTAssertFalse(fineLines.isConcern)
    }

    func testAssessmentRowsPreserveAllContextWithoutBecomingConcerns() {
        var report = AnalysisResult()
        report.assessmentDetails = [
            SkinIssueDescription(field: "肤质判断依据", texts: ["混油性", "T 区可见油光，但光照可能影响判断。", "无法确认实际皮脂分泌水平。"]),
            SkinIssueDescription(field: "评分", texts: ["72.5"]),
            SkinIssueDescription(field: "空记录", texts: [" \n "])
        ]
        let rows = report.reportAssessmentObservations
        XCTAssertEqual(rows.map(\.id), ["assessment.肤质判断依据", "assessment.评分"])
        XCTAssertEqual(rows.first?.title, "肤质判断依据")
        XCTAssertEqual(rows.first?.summary, "混油性")
        XCTAssertEqual(rows.first?.details, "混油性\nT 区可见油光，但光照可能影响判断。\n无法确认实际皮脂分泌水平。")
        XCTAssertTrue(rows.allSatisfy { !$0.isConcern && $0.status == nil })
        XCTAssertTrue(report.reportObservations.isEmpty)
    }

    func testDetailBodyRemovesRepeatedOpeningWhilePreservingLocationsAndUncertainty() {
        let remaining = "可能受光照影响，尚不能确认原因。\n记录部位：右侧鼻翼旁"
        for opening in ["局部淡红色区域。\n", "局部淡红色区域\n"] {
            let original = opening + remaining
            let observation = AISkinSkinReportObservation(
                id: "redness", title: "泛红", status: "轻度", details: original,
                summary: "局部淡红色区域。", isConcern: true
            )
            XCTAssertEqual(observation.detailBody, remaining)
            XCTAssertEqual(observation.details, original, "Deduplicating display text must not rewrite the source detail")
        }
    }

    func testDetailBodyLeavesDistinctDetailsAndPartialSentenceMatchesUntouched() {
        for original in [
            "记录部位：右侧鼻翼旁\n具体原因尚不能确认。",
            "局部淡红色区域，可能受光照影响，尚不能确认原因。"
        ] {
            let observation = AISkinSkinReportObservation(
                id: "redness", title: "泛红", status: nil, details: original,
                summary: "局部淡红色区域。"
            )
            XCTAssertEqual(observation.detailBody, original, "A shared word prefix is not a duplicate first sentence")
            XCTAssertEqual(observation.details, original)
        }
    }

    func testDetailBodyIsEmptyWhenTheOnlyDetailIsAlreadyTheSummary() {
        for original in ["局部淡红色区域", "局部淡红色区域。", "局部淡红色区域。\n"] {
            let observation = AISkinSkinReportObservation(
                id: "redness", title: "泛红", status: nil, details: original,
                summary: "局部淡红色区域。"
            )
            XCTAssertEqual(observation.detailBody, "")
            XCTAssertEqual(observation.details, original)
        }
    }

    func testAssessmentDetailsPreserveBasisAndValuesWithoutInventingMissingMetrics() throws {
        let payload = #"{"_id":"basis","skinType":{"type":"混合","subtype":"偏油","basis":"T区可见油光"},"overallAssessment":{"healthScore":72.5,"skinCondition":"局部干燥"},"moisture":0,"glossiness":65.5}"#
        let analysis = try JSONDecoder.apiDecoder.decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        let details = report.assessmentDetails.flatMap(\.texts).joined(separator: "\n")
        for text in ["偏油", "T区可见油光", "局部干燥", "72.5", "0.0", "65.5"] { XCTAssertTrue(details.contains(text)) }
        XCTAssertFalse(report.assessmentDetails.contains { $0.field == "弹性" })
    }

    func testIngredientDetailsIncludeAllReturnedScoresAndRisks() throws {
        let payload = #"{"safetyIndex":91,"efficacyScore":4.3,"activeIngredients":5,"acneRisk":{"level":"低","percentage":10},"irritationRisk":{"level":"中","percentage":30},"allergyRisk":{"level":"低","percentage":15},"efficacyAnalysis":[],"potentialRisks":[],"recommendations":[],"overallRating":4.2,"summary":"记录"}"#
        var report = try JSONDecoder.apiDecoder.decode(IngredientAnalysis.self, from: Data(payload.utf8))
        XCTAssertEqual(report.scoreDetails, "安全性指数：91 / 100\n功效评分：4.3 / 5\n活性成分：5 项")
        for text in ["致痘：低（模型风险指数 10 / 100）", "刺激：中（模型风险指数 30 / 100）", "过敏：低（模型风险指数 15 / 100）"] { XCTAssertTrue(report.riskDetails.contains(text)) }
        XCTAssertFalse(report.riskDetails.contains("%"))
        report.efficacyScore = 83
        XCTAssertEqual(report.scoreDetails, "安全性指数：91 / 100\n功效评分原值：83（历史量表未知）\n活性成分：5 项")
        XCTAssertEqual(report.efficacyScore, 83, "A legacy value must not be rescaled or rewritten")
    }

    func testLegacyConditionNoteIsKeptInDetailsWithoutBecomingCaptureState() {
        let note = "用户指定test文件夹原图，未替换示例脸"
        let context = SkinAnalysisContext(condition: note, light: nil, feelings: [])
        XCTAssertEqual(context.reportStatus, "已记录")
        XCTAssertNil(context.reportCaptureState)
        XCTAssertEqual(context.reportConditionNote, note)
        XCTAssertTrue(context.reportDetailText.contains("拍摄状态：未记录"))
        XCTAssertTrue(context.reportDetailText.contains("记录备注：\(note)"))
        XCTAssertTrue(context.reportDetailText.contains("实际肤感：未补充"))
        XCTAssertEqual(context.condition, note, "Presentation must not rewrite saved context")
    }

    func testKnownAndMissingCaptureStatesHaveShortAccurateLabels() {
        for state in ["纯素颜", "护肤后", "上妆后", "特殊时期"] {
            let context = SkinAnalysisContext(condition: state)
            XCTAssertEqual(context.reportStatus, state)
            XCTAssertNil(context.reportConditionNote)
        }
        XCTAssertEqual(SkinAnalysisContext().reportStatus, "未记录状态")
        XCTAssertEqual(SkinAnalysisContext(condition: " \n ").reportStatus, "未记录状态")
    }

    func testLongRecordedLocationsStayInDetailsButDoNotExpandSummaryLabels() throws {
        let payload = #"{"_id":"record","otherIssues":{"redness":{"severity":"轻度","distribution":["双颊下部","鼻翼周围"],"description":"局部淡红色区域"}}}"#
        let analysis = try JSONDecoder().decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        let observation = try XCTUnwrap(report.reportObservations.first)
        XCTAssertEqual(observation.title, "泛红")
        XCTAssertTrue(observation.details.contains("双颊下部、鼻翼周围"))
        XCTAssertTrue(observation.details.contains("局部淡红色区域"))
        XCTAssertEqual(report.reportMetrics.first?.title, "泛红")
        XCTAssertEqual(report.reportMetrics.first?.value, "轻度")
    }

    func testSlightSeverityUsesLowestNonzeroSegmentWithoutChangingOriginalText() throws {
        let payload = #"{"_id":"slight","otherIssues":{"redness":{"severity":"轻微","description":"局部淡红色区域"}}}"#
        let analysis = try JSONDecoder().decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        XCTAssertEqual(report.reportMetrics.first?.level, 1)
        XCTAssertEqual(report.reportMetrics.first?.value, "轻微")
        XCTAssertEqual(report.reportObservations.first?.status, "轻微")
        XCTAssertTrue(report.reportObservations.first?.details.contains("局部淡红色区域") == true)
    }

}
