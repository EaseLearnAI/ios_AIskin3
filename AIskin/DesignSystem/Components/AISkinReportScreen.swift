import SwiftUI

/// The fixed regions of every independent report share one layout. Content
/// owns its ScrollView/ScrollViewReader and anchor coordinate space; this
/// container never introduces another scroll view or navigation stack.
struct AISkinReportScreen<Header: View, Content: View, Footer: View>: View {
    @ViewBuilder let header: Header
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            header.fixedSize(horizontal: false, vertical: true)
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            footer.fixedSize(horizontal: false, vertical: true)
        }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension AISkinReportScreen where Footer == EmptyView {
    init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.init(header: header, content: content, footer: { EmptyView() })
    }
}
