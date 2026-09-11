import SwiftUI

/// Presents an auxiliary navigation stack from the left while retaining the
/// underlying tab and its state. Both screens share the app-level background.
struct AISkinLeadingNavigationContainer<Root: View, Destination: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool
    @ViewBuilder var root: () -> Root
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                root()
                    .offset(x: isPresented && !reduceMotion ? geometry.size.width : 0)
                    .opacity(isPresented && reduceMotion ? 0 : 1)
                    .allowsHitTesting(!isPresented)
                    .accessibilityHidden(isPresented)

                if isPresented {
                    NavigationStack {
                        destination()
                    }
                    .transition(reduceMotion ? .opacity : .offset(x: -geometry.size.width))
                    .zIndex(1)
                }
            }
            .animation(AISkinMotion.standard, value: isPresented)
        }
    }
}
