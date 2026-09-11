import SwiftUI

struct AISkinShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card = AISkinShadowStyle(
        color: AISkinColor.accent.opacity(0.10),
        radius: 16,
        x: 0,
        y: 6
    )

    static let floating = AISkinShadowStyle(
        color: AISkinColor.primaryAction.opacity(0.15),
        radius: 22,
        x: 0,
        y: 10
    )
}

extension View {
    func aiSkinShadow(_ style: AISkinShadowStyle = .card) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
