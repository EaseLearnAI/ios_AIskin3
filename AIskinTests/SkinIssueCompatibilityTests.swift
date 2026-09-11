import XCTest
@testable import AIskin

@MainActor
final class SkinIssueCompatibilityTests: XCTestCase {
    private let actualIssues = #"{"redness":["鼻翼两侧轻微泛红"],"texture":["局部皮肤略显粗糙，尤其在T区"]}"#

    func testUploadSnapshotUsesPersistedTimestampsAndContext() throws {
        let payload = #"{"success":true,"data":{"analysisId":"persisted","createdAt":"2026-09-09T08:12:13.456Z","updatedAt":"2026-09-09T08:14:15.789Z","context":{"condition":"纯素颜","light":"自然光","feelings":["紧绷"]},"overallAssessment":{"summary":"服务端结果"}}}"#
        let data = try XCTUnwrap(JSONDecoder.apiDecoder.decode(AnalyzeSkinResponse.self, from: Data(payload.utf8)).data)
        let persisted = try XCTUnwrap(data.persistedAnalysis)
        XCTAssertEqual(persisted.id, "persisted")
        XCTAssertEqual(persisted.createdAt, data.createdAt)
        XCTAssertEqual(persisted.updatedAt, data.updatedAt)
        XCTAssertEqual(persisted.context, data.context)
        XCTAssertEqual(persisted.overallAssessment?.summary, "服务端结果")
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(persisted)
        XCTAssertEqual(report.createdAt, data.createdAt)
        XCTAssertEqual(report.context?.light, "自然光")
    }

    func testLegacyUploadWithoutPersistedTimeRequiresDetailReadback() throws {
        let payload = #"{"success":true,"data":{"analysisId":"legacy","blackheads":{"exists":true}}}"#
        let data = try XCTUnwrap(JSONDecoder.apiDecoder.decode(AnalyzeSkinResponse.self, from: Data(payload.utf8)).data)
        XCTAssertNil(data.persistedAnalysis, "The app must read persisted detail rather than inventing a timestamp")
    }

    func testActualSavedArrayShapeDecodesAndMapsWithoutInventingStructuredFindings() throws {
        let payload = "{\"_id\":\"6aa0759cfe5802b7789b09c0\",\"otherIssues\":\(actualIssues),\"overallAssessment\":{\"healthScore\":72,\"summary\":\"本次观察\"}}"
        let analysis = try JSONDecoder().decode(SkinAnalysis.self, from: Data(payload.utf8))
        XCTAssertNil(analysis.otherIssues?.redness)
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        XCTAssertNil(report.redness, "A text observation must not invent exists, severity or distribution")
        XCTAssertNil(report.skinToneEvenness)
        XCTAssertEqual(report.healthScore, 72)
        XCTAssertEqual(report.additionalIssueDescriptions, [
            SkinIssueDescription(field: "redness", texts: ["鼻翼两侧轻微泛红"]),
            SkinIssueDescription(field: "texture", texts: ["局部皮肤略显粗糙，尤其在T区"])
        ])
        XCTAssertEqual(report.additionalIssueDescriptions.last?.title, "肤质纹理观察")
        let list = "{\"success\":true,\"data\":{\"analyses\":[\(payload)]}}"
        let history = try JSONDecoder().decode(SkinAnalysisListResponse.self, from: Data(list.utf8))
        XCTAssertEqual(history.data?.analyses.first?.otherIssues?.additionalDescriptions, report.additionalIssueDescriptions)
    }

    func testUploadResponseAcceptsTextAndKeepsExistingObjectFields() throws {
        let payload = #"{"success":true,"data":{"analysisId":"report-id","otherIssues":{"redness":{"exists":true,"severity":"轻度","distribution":["鼻翼"],"description":"鼻翼观察"},"sensitivity":"本次拍摄可见局部泛红","texture":["T区纹理可见"]}}}"#
        let response = try JSONDecoder().decode(AnalyzeSkinResponse.self, from: Data(payload.utf8))
        let issues = try XCTUnwrap(response.data?.otherIssues)
        XCTAssertEqual(issues.redness?.exists, true)
        XCTAssertEqual(issues.redness?.severity, "轻度")
        XCTAssertEqual(issues.redness?.distribution, ["鼻翼"])
        XCTAssertEqual(issues.redness?.description, "鼻翼观察")
        XCTAssertNil(issues.sensitivity)
        let encodedIssues = try XCTUnwrap(String(data: JSONEncoder().encode(issues), encoding: .utf8))
        let savedPayload = "{\"_id\":\"report-id\",\"otherIssues\":\(encodedIssues)}"
        let saved = try JSONDecoder().decode(SkinAnalysis.self, from: Data(savedPayload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(saved)
        XCTAssertEqual(report.redness?.description, "鼻翼观察")
        XCTAssertEqual(report.redness?.severity, "轻度")
        XCTAssertNil(report.sensitivity)
        XCTAssertEqual(report.additionalIssueDescriptions, issues.additionalDescriptions)
        XCTAssertEqual(issues.additionalDescriptions, [
            SkinIssueDescription(field: "sensitivity", texts: ["本次拍摄可见局部泛红"]),
            SkinIssueDescription(field: "texture", texts: ["T区纹理可见"])
        ])
    }

    func testUnknownTextFieldsSurviveEncodingWithoutTurningNumbersIntoMedicalText() throws {
        let payload = #"{"redness":"鼻翼两侧轻微泛红","texture":["纹理观察"],"newObservation":{"description":"真实附加描述","confidence":0.7},"unavailable":null,"flag":true}"#
        let issues = try JSONDecoder().decode(OtherIssues.self, from: Data(payload.utf8))
        XCTAssertEqual(issues.additionalDescriptions.map(\.field), ["newObservation", "redness", "texture"])
        XCTAssertEqual(issues.additionalDescriptions.first?.texts, ["真实附加描述"])
        let encoded = try JSONEncoder().encode(issues)
        let source = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? NSDictionary)
        let restored = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
        XCTAssertEqual(restored, source, "Unknown JSON fields and original array/text shapes must remain intact")
    }
    func testStableObservationsKeepCategoriesSeparateFromDescriptionText() throws {
        let payload = #"{"_id":"normalized","otherIssues":{"observations":[{"category":"redness","details":["鼻翼两侧轻微泛红"]},{"category":"texture","details":["局部皮肤略显粗糙，尤其在T区"]},{"category":"texture","details":["第二条原始观察"]}],"sensitivity":"旧版文字仍兼容"}}"#
        let analysis = try JSONDecoder().decode(SkinAnalysis.self, from: Data(payload.utf8))
        XCTAssertEqual(analysis.otherIssues?.observations.first, SkinObservation(category: "redness", details: ["鼻翼两侧轻微泛红"]))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        XCTAssertEqual(report.additionalIssueDescriptions, [
            SkinIssueDescription(field: "redness", texts: ["鼻翼两侧轻微泛红"]),
            SkinIssueDescription(field: "texture", texts: ["局部皮肤略显粗糙，尤其在T区", "第二条原始观察"]),
            SkinIssueDescription(field: "sensitivity", texts: ["旧版文字仍兼容"])
        ])
        XCTAssertFalse(report.additionalIssueDescriptions.flatMap(\.texts).contains("texture"))
        let roundTrip = try JSONDecoder().decode(SkinAnalysis.self, from: JSONEncoder().encode(analysis))
        XCTAssertEqual(roundTrip.otherIssues?.observations, analysis.otherIssues?.observations)
        XCTAssertEqual(roundTrip.otherIssues?.additionalDescriptions, report.additionalIssueDescriptions)
    }

    func testMissingMeasurementsRemainMissingWithOrWithoutAssessment() throws {
        for payload in [
            #"{"_id":"missing"}"#,
            #"{"_id":"missing","skinType":{"type":"干性皮肤"},"overallAssessment":{"summary":"只返回了真实总结"}}"#
        ] {
            let analysis = try JSONDecoder().decode(SkinAnalysis.self, from: Data(payload.utf8))
            let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
            XCTAssertNil(report.healthScore)
            XCTAssertNil(report.oilLevel, "Skin type does not replace a missing oil measurement")
            XCTAssertNil(report.moistureLevel)
            XCTAssertEqual(report.skinType?.type, analysis.skinType?.type)
            XCTAssertEqual(report.summary, analysis.overallAssessment?.summary)
        }
    }

    func testExplicitZeroScoreAndMeasuredMoistureAreNotTreatedAsMissing() throws {
        let payload = #"{"_id":"measured","overallAssessment":{"healthScore":0},"moisture":70}"#
        let analysis = try JSONDecoder().decode(SkinAnalysis.self, from: Data(payload.utf8))
        let report = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        XCTAssertEqual(report.healthScore, 0)
        XCTAssertEqual(report.moistureLevel, "正常")
        XCTAssertNil(report.oilLevel)
    }

}
