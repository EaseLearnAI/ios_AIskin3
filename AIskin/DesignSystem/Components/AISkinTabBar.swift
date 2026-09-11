import SwiftUI

/// The single tab container. iOS owns its material, selection transition,
/// accessibility and safe-area layout, including Liquid Glass on iOS 26.
struct AISkinTabBar<Content: View>: View {
    @Binding private var selection: AppTab
    private let content: Content

    init(selection: Binding<AppTab>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
    }

    var body: some View {
        TabView(selection: $selection) { content }
            .tint(AISkinColor.accent)
    }
}
