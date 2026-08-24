import SwiftUI

enum AISkinAuthStyle {
    static let pink = Color(red: 0.973, green: 0.733, blue: 0.816)
    static let lavender = Color(red: 0.882, green: 0.745, blue: 0.906)
    static let pageTop = Color(red: 1.0, green: 0.976, blue: 0.984)

    static var gradient: LinearGradient {
        LinearGradient(
            colors: [pink, lavender],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var pageGradient: LinearGradient {
        LinearGradient(
            colors: [pageTop, .white],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// A scalable in-app rendering of the product icon: pink rounded square,
/// skincare droplet, and the connected skin-science nodes.
struct AISkinLogoMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(AISkinAuthStyle.gradient)

            DropletShape()
                .fill(Color.white.opacity(0.94))
                .frame(width: size * 0.48, height: size * 0.58)
                .overlay {
                    MoleculeMark()
                        .stroke(
                            AISkinAuthStyle.pink.opacity(0.72),
                            style: StrokeStyle(
                                lineWidth: max(1.5, size * 0.035),
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: size * 0.25, height: size * 0.24)
                        .offset(y: size * 0.06)
                }
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}

private struct DropletShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.height * 0.64),
            control1: CGPoint(x: rect.width * 0.64, y: rect.height * 0.18),
            control2: CGPoint(x: rect.maxX, y: rect.height * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.height * 0.88),
            control2: CGPoint(x: rect.width * 0.76, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.height * 0.64),
            control1: CGPoint(x: rect.width * 0.24, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.height * 0.88)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.height * 0.42),
            control2: CGPoint(x: rect.width * 0.36, y: rect.height * 0.18)
        )
        path.closeSubpath()
        return path
    }
}

private struct MoleculeMark: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let left = CGPoint(x: rect.minX + rect.width * 0.14, y: rect.midY - rect.height * 0.08)
        let topRight = CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.12)
        let bottomRight = CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.maxY - rect.height * 0.10)
        let nodeRadius = min(rect.width, rect.height) * 0.13

        var path = Path()
        path.move(to: left)
        path.addLine(to: center)
        path.addLine(to: topRight)
        path.move(to: center)
        path.addLine(to: bottomRight)

        for point in [left, center, topRight, bottomRight] {
            path.addEllipse(
                in: CGRect(
                    x: point.x - nodeRadius,
                    y: point.y - nodeRadius,
                    width: nodeRadius * 2,
                    height: nodeRadius * 2
                )
            )
        }
        return path
    }
}

#Preview("Product icon mark") {
    ZStack {
        AISkinAuthStyle.gradient.ignoresSafeArea()
        AISkinLogoMark(size: 72)
    }
}
