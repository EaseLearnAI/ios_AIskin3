import SwiftUI

struct AISkinShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card = AISkinShadowStyle(
        color: .black.opacity(0.08),
        radius: 12,
        x: 0,
        y: 4
    )

    static let floating = AISkinShadowStyle(
        color: .black.opacity(0.14),
        radius: 18,
        x: 0,
        y: 8
    )
}

extension View {
    func aiSkinShadow(_ style: AISkinShadowStyle = .card) -> some View {
        shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}
