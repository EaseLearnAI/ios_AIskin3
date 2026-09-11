import SwiftUI

struct PersonalAgeRow: View {
    let age: Int?
    var accessibilityID = "personal-information.age"
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            AISkinSettingsRow(title: "年龄", value: age.map { "\($0) 岁" } ?? "未填写")
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityIdentifier(accessibilityID)
    }
}
