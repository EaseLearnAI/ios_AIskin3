import XCTest
@testable import AIskin

final class IngredientReportPresentationTests: XCTestCase {
    func testStructuredCopySeparatesTitleWithoutRemovingQualification() {
        let item = IngredientReportItem("清洁油脂：可能帮助清洁；敏感肌需留意耐受。", fallbackTitle: "功效 1")
        XCTAssertEqual(item.title, "清洁油脂")
        XCTAssertEqual(item.text, "可能帮助清洁；敏感肌需留意耐受。")
    }

    func testLegacyParagraphAndItsRiskConditionsArePreserved() {
        let original = "对部分肤质可能存在刺激，不能仅凭成分表确定个人风险。"
        let item = IngredientReportItem(original, fallbackTitle: "风险 1")
        XCTAssertEqual(item.title, "风险 1")
        XCTAssertEqual(item.text, original)
    }

    func testLongPrefixOrMissingBodyDoesNotBecomeATitle() {
        for source in ["这是超过十二个字的旧版报告引导文字：具体风险尚不能确定。", "注意："] {
            let item = IngredientReportItem(source, fallbackTitle: "建议 1")
            XCTAssertEqual(item.title, "建议 1")
            XCTAssertEqual(item.text, source)
        }
    }

    func testEnglishColonAndAdditionalColonsKeepBodyIntact() {
        let item = IngredientReportItem("使用频率: 遵循说明；注意：不适时暂停。", fallbackTitle: "建议 1")
        XCTAssertEqual(item.title, "使用频率")
        XCTAssertEqual(item.text, "遵循说明；注意：不适时暂停。")
    }
}
