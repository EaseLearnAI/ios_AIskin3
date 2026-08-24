import SwiftUI

struct AISkinIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var role: ButtonRole?
    var tint: Color = AISkinColor.textPrimary
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Icon button") {
    AISkinIconButton(
        systemName: "clock.arrow.circlepath",
        accessibilityLabel: "查看历史记录"
    ) {}
    .padding()
}
