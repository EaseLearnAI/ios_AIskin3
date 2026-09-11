import SwiftUI
import UIKit

struct AISkinScreenBackground<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AISkinBackgroundLayer()
            content
        }
    }
}

extension View {
    @ViewBuilder
    func aiSkinTransparentNavigationContainer() -> some View {
        if #available(iOS 18.0, *) {
            self
                .scrollContentBackground(.hidden)
                .containerBackground(Color.clear, for: .navigation)
                .background {
                    AISkinNativeContainerClearer()
                }
        } else {
            self
                .scrollContentBackground(.hidden)
                .background {
                    AISkinNativeContainerClearer()
                }
        }
    }
}

/// SwiftUI's navigation container background does not clear every UIKit host
/// inserted by TabView and NavigationStack. Keep their shared ancestors
/// transparent so the single app-level background remains visible.
private struct AISkinNativeContainerClearer: UIViewRepresentable {
    func makeUIView(context: Context) -> AISkinClearAncestorView {
        let view = AISkinClearAncestorView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: AISkinClearAncestorView, context: Context) {
        uiView.clearAncestorBackgrounds()
    }
}

private final class AISkinClearAncestorView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        clearAncestorBackgrounds()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        clearAncestorBackgrounds()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        clearAncestorBackgrounds()
    }

    func clearAncestorBackgrounds() {
        var candidate = superview

        while let view = candidate, !(view is UIWindow) {
            view.backgroundColor = .clear
            view.isOpaque = false
            view.layer.backgroundColor = UIColor.clear.cgColor
            view.layer.isOpaque = false
            candidate = view.superview
        }
    }
}

private struct AISkinBackgroundLayer: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: AISkinColor.screenBaseTop, location: 0),
                        .init(color: AISkinColor.screenBaseMiddle, location: 0.58),
                        .init(color: AISkinColor.screenBaseBottom, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                glow(color: AISkinColor.screenGlowMiddleLower, center: UnitPoint(x: 0.65, y: 0.54), fade: 0.42, size: size)
                glow(color: AISkinColor.screenGlowTopTrailing, center: UnitPoint(x: 0.91, y: 0.13), fade: 0.34, size: size)
                glow(color: AISkinColor.screenGlowTopLeading, center: UnitPoint(x: 0.14, y: 0.09), fade: 0.32, size: size)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func glow(color: Color, center: UnitPoint, fade: CGFloat, size: CGSize) -> some View {
        RadialGradient(
            colors: [color, .clear],
            center: center,
            startRadius: 0,
            endRadius: farthestCornerRadius(center: center, size: size) * fade
        )
    }

    private func farthestCornerRadius(center: UnitPoint, size: CGSize) -> CGFloat {
        let point = CGPoint(x: size.width * center.x, y: size.height * center.y)
        let corners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height)
        ]

        return corners
            .map { hypot($0.x - point.x, $0.y - point.y) }
            .max() ?? max(size.width, size.height)
    }
}

#Preview("Screen background") {
    AISkinScreenBackground {
        Text("析肤 AI")
            .font(AISkinTypography.screenTitle)
            .foregroundStyle(AISkinColor.textPrimary)
    }
}
