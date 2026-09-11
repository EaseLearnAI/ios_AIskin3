import SwiftUI

/// The stable, top-level destinations in AIskin.
enum AppTab: Int, CaseIterable, Hashable, Identifiable {
    case home
    case products
    case skinAnalysis

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "首页"
        case .products: "护肤柜"
        case .skinAnalysis: "肌肤检测"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .products: "shippingbox"
        case .skinAnalysis: "sparkles"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .home: "house.fill"
        case .products: "shippingbox.fill"
        case .skinAnalysis: "sparkles"
        }
    }

    @ViewBuilder
    var label: some View {
        Label(title, systemImage: selectedSystemImage)
    }

}
