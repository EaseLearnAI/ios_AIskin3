import Foundation

/// Display-only offer proposal, independent of the signed-in user's access.
enum MembershipOffer {
    static let lead = "核心权益 · 叠加风险检查"
    static let title = "怕叠加「烂脸」？\n用前先查风险"
    static let summary = "担心两瓶叠着用后泛红、刺痛，甚至「烂脸」？先把产品放在一起检查，让潜在冲突和刺激风险在使用前更清楚。"

    enum Period: String, CaseIterable, Identifiable {
        case month, year
        var id: String { rawValue }
        var title: String { self == .month ? "月度会员" : "年度会员" }
        var productID: String { self == .month ? "member_month" : "member_year" }
        var price: String { self == .month ? "¥12" : "¥88" }
        var unit: String { self == .month ? "/ 月" : "/ 年" }
        var note: String { "单次付款，到期不自动续费" }
    }

    struct Benefit: Identifiable {
        let id: String
        let systemImage: String
        let title: String
        let quota: String
        let detail: Detail
    }
    static let benefits: [Benefit] = [
        .init(id: "plan", systemImage: "sun.max", title: "理清早晚护理步骤", quota: "每月 20 份 · 早晚护理方案", detail: .plan),
        .init(id: "product", systemImage: "flask", title: "买来这一瓶，先看成分", quota: "每月 100 次 · 单品成分分析", detail: .product),
        .init(id: "skin", systemImage: "faceid", title: "记录每次肤况变化", quota: "每月 30 次 · 肌肤分析", detail: .skin)
    ]

    struct Section {
        let title: String
        let body: String
    }
    enum Detail: String, Identifiable {
        case conflict, plan, product, skin, rules, terms
        var id: String { rawValue }
        var title: String {
            switch self {
            case .conflict: "护肤品冲突检测"
            case .plan: "早晚护理方案"
            case .product: "单品成分分析"
            case .skin: "肌肤分析与记录"
            case .rules: "会员权益说明"
            case .terms: "订阅说明"
            }
        }
        var sections: [Section] {
            switch self {
            case .conflict:
                [.init(title: "一起用之前，先查一遍", body: "想把两款护肤品一起用时，先查看潜在成分冲突和叠加刺激风险，了解使用中需要留意的地方。检查提供的是用前参考，不能预测你的实际反应，也不能保证不会过敏。帮你把担心的问题先看明白，再决定如何搭配。")]
            case .plan:
                [.init(title: "理清早晚护理步骤", body: "根据提供的肤况与产品信息，整理早晚护理顺序，方便按步骤查看和安排日常护理。")]
            case .product:
                [.init(title: "看懂这一瓶的成分", body: "查看产品成分信息、特点及需要留意的风险，为选择和使用护肤品提供参考。")]
            case .skin:
                [.init(title: "记录肤况，回看变化", body: "结合上传的照片了解肤况，并保留分析记录，方便日后回看。照片分析用于日常护肤参考。")]
            case .rules:
                [
                    .init(title: "会员权益预览", body: "会员订阅暂未开放。以下是计划上线的每月次数，当前不会据此限制你的使用。最终价格、权益和规则以上线时为准。"),
                    .init(title: "冲突检测", body: "免费版每月 5 份 · 会员每月 60 份"),
                    .init(title: "早晚护理方案", body: "免费版每月 2 份 · 会员每月 20 份"),
                    .init(title: "单品成分分析", body: "免费版每月 10 次 · 会员每月 100 次"),
                    .init(title: "肌肤分析", body: "免费版每月 4 次 · 会员每月 30 次"),
                    .init(title: "完整结果与历史回看", body: "计划中免费版也可查看完整报告与建议、回看历史记录和进行护理打卡；重新查看已有结果不占新生成次数。")
                ]
            case .terms:
                [
                    .init(title: "单次购买，不自动续费", body: "月度会员和年度会员分别购买 1 个月或 12 个月的会员期限。到期不会自动扣款；购买前请核对当前展示的价格与期限。"),
                    .init(title: "支付与到账", body: "完成支付宝付款后，应用会向服务端核对支付结果。若到账暂有延迟，可选择“查询支付结果”，请勿重复付款。会员状态以服务端核验结果为准。"),
                    .init(title: "退款", body: "退款需联系服务方处理；全额退款后将撤销该笔订单对应的会员期限。")
                ]
            }
        }
    }
}
