import SwiftUI

/// The four stable, top-level destinations in AIskin.
enum AppTab: Int, CaseIterable, Hashable, Identifiable {
    case home
    case products
    case skinAnalysis
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "首页"
        case .products: "产品分析"
        case .skinAnalysis: "肌肤检测"
        case .profile: "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .products: "shippingbox"
        case .skinAnalysis: "sparkles"
        case .profile: "person"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .home: "house.fill"
        case .products: "shippingbox.fill"
        case .skinAnalysis: "sparkles"
        case .profile: "person.fill"
        }
    }

    @ViewBuilder
    var label: some View {
        Label(title, systemImage: selectedSystemImage)
    }

    init?(legacyIndex: Int) {
        self.init(rawValue: legacyIndex)
    }

    var legacyIndex: Int { rawValue }
}
