import Foundation

/// New reports use "short title：one sentence" in the existing string-array
/// contract. Keep legacy prose intact rather than inferring a medical conclusion.
struct IngredientReportItem: Equatable {
    let title: String
    let text: String

    init(_ source: String, fallbackTitle: String) {
        let clean = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if let separator = clean.firstIndex(where: { "：:".contains($0) }) {
            let heading = String(clean[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
            let body = String(clean[clean.index(after: separator)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !heading.isEmpty, heading.count <= 12, !heading.contains("\n"), !body.isEmpty {
                title = heading
                text = body
                return
            }
        }
        title = fallbackTitle
        text = clean
    }
}
