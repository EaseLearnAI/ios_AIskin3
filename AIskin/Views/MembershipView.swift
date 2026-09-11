import SwiftUI

/// Membership presentation reads prices, orders and entitlement from the server.
struct MembershipView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var purchaseStore: MembershipPurchaseStore
    let ownerID: String?
    @State private var period: MembershipOffer.Period = .month
    @State private var detail: MembershipOffer.Detail?
    @State private var purchaseConfirmation: PaymentProduct?
    @State private var legalDocument: LegalDocument?

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(
                title: "析肤会员",
                rightIcon: "info.circle",
                rightAction: { detail = .rules },
                rightAccessibilityLabel: "权益说明",
                backAction: { dismiss() }
            )

            ScrollView {
                VStack(spacing: AISkinSpacing.sectionGap) {
                    AISkinMembershipPass(
                        lead: MembershipOffer.lead,
                        title: MembershipOffer.title,
                        summary: MembershipOffer.summary,
                        quota: "冲突检测 · 每月 60 份",
                        onDetails: { detail = .conflict }
                    )

                    VStack(spacing: 0) {
                        ForEach(MembershipOffer.benefits) { benefit in
                            AISkinMembershipBenefitRow(
                                systemImage: benefit.systemImage,
                                title: benefit.title,
                                detail: benefit.quota,
                                action: { detail = benefit.detail }
                            )
                            .accessibilityIdentifier("membership.benefit.\(benefit.id)")
                        }
                    }

                    if let membership = purchaseStore.membership, membership.tier == .member {
                        AISkinMembershipDetail(title: "析肤会员已开通", body: membership.validUntil.map { "有效期至 " + $0.formatted(date: .abbreviated, time: .omitted) } ?? "会员状态已确认")
                            .accessibilityIdentifier("membership.active")
                    }

                    HStack(alignment: .top, spacing: AISkinSpacing.small) {
                        ForEach(MembershipOffer.Period.allCases) { option in
                            AISkinMembershipPlanOption(
                                title: option.title,
                                price: product(for: option).map { formatPrice($0.amountFen) } ?? "—",
                                unit: option.unit,
                                note: option.note,
                                isSelected: selectedProductID == option.productID,
                                action: { period = option }
                            )
                            .disabled(purchaseStore.isBusy || purchaseStore.hasPendingPurchase)
                            .accessibilityIdentifier("membership.period.\(option.rawValue)")
                        }
                    }
                    if let message = purchaseStore.message {
                        AISkinMembershipDetail(title: purchaseStore.messageKind == .error ? "暂未完成" : "支付状态", body: message)
                            .accessibilityIdentifier("membership.payment-status")
                    }
                }
                .padding(.horizontal, AISkinSpacing.screenEdge)
                .padding(.top, AISkinSpacing.small)
                .padding(.bottom, AISkinSpacing.large)
            }
            .accessibilityIdentifier("membership.content")

            AISkinMembershipFooter(
                actionTitle: purchaseStore.hasPendingPurchase ? "继续处理这笔订单" : "支付宝购买",
                notice: paymentNotice,
                isLoading: purchaseStore.isBusy,
                isPurchaseEnabled: purchaseStore.canPurchase(productID: selectedProductID),
                continueTitle: purchaseStore.membership?.tier == .member ? "返回使用" : "继续免费使用",
                restoreTitle: "查询支付结果",
                onSubscribe: { purchaseConfirmation = selectedProduct },
                onContinue: { dismiss() },
                onRestore: { Task {
                    if purchaseStore.catalog == nil { await purchaseStore.load(ownerID: ownerID) }
                    else { await purchaseStore.refreshPendingPurchase() }
                } },
                onTerms: { detail = .terms },
                onPrivacy: { legalDocument = .privacy }
            )
        }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .accessibilityAction(.escape) { dismiss() }
        .task(id: ownerID) { await purchaseStore.load(ownerID: ownerID) }
        .onChange(of: ownerID) { _, _ in purchaseConfirmation = nil }
        .sheet(item: $detail) { item in
            AISkinBottomSheet(title: item.title, onClose: { detail = nil }) {
                VStack(alignment: .leading, spacing: AISkinSpacing.large) {
                    ForEach(Array(sections(for: item).enumerated()), id: \.offset) { _, section in
                        AISkinMembershipDetail(title: section.title, body: section.body)
                    }
                }
                .padding(.bottom, AISkinSpacing.medium)
            } footer: {
                AISkinButton(action: { detail = nil }) { Text("知道了") }
                    .accessibilityIdentifier("membership.detail.done")
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $legalDocument) { document in
            LegalDocumentView(document: document)
        }
        .alert(item: $purchaseConfirmation) { product in
            Alert(
                title: Text("确认购买"),
                message: Text("\(product.name) · \(formatPrice(product.amountFen))\n有效期 \(product.durationMonths) 个月，一次付款，不自动续费。"),
                primaryButton: .default(Text("前往支付宝")) {
                    Task {
                        // Do not pay a different amount if a catalog refresh raced the confirmation.
                        guard selectedProduct == product else { return }
                        await purchaseStore.purchase(productID: product.id)
                    }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    private func product(for option: MembershipOffer.Period) -> PaymentProduct? {
        purchaseStore.catalog?.products.first { $0.id == option.productID }
    }

    private func sections(for detail: MembershipOffer.Detail) -> [MembershipOffer.Section] {
        guard detail == .rules, purchaseStore.catalog?.available == true else { return detail.sections }
        return [MembershipOffer.Section(title: "会员购买说明", body: "月度与年度会员均为单次购买，到期不自动续费。请在付款前核对当前展示的套餐金额与期限。")]
            + Array(detail.sections.dropFirst())
    }

    private var selectedProductID: String {
        purchaseStore.pendingProductID ?? period.productID
    }

    private var selectedProduct: PaymentProduct? {
        purchaseStore.catalog?.products.first { $0.id == selectedProductID }
    }

    private var paymentNotice: String {
        if purchaseStore.isLoading { return "正在获取套餐与会员状态…" }
        if purchaseStore.catalog?.available != true { return "购买暂未开放，当前不会扣费。" }
        if purchaseStore.catalog?.environment == .sandbox { return "当前为支付测试环境，iPhone 暂不能付款。" }
        return "一次购买，到期不自动续费。完成付款后请返回查询到账状态。"
    }

    private func formatPrice(_ amountFen: Int) -> String {
        let whole = amountFen / 100
        let fraction = amountFen % 100
        return fraction == 0 ? "¥\(whole)" : "¥\(whole)." + String(format: "%02d", fraction)
    }
}
