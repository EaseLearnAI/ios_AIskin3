import SwiftUI

struct ProductInfo: View {
    let product: Product

    var body: some View {
        HStack(spacing: AISkinReportTokens.rowGap) {
            AISkinProductThumbnail(url: product.imageUrl.flatMap(URL.init(string:)), label: product.label, size: .report)
            VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                Text([product.label, "成分报告"].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary)
                Text(product.name).font(AISkinReportTokens.productTitle).foregroundStyle(AISkinColor.textPrimary).fixedSize(horizontal: false, vertical: true)
                Label("分析已完成", systemImage: "checkmark").font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.accent)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, AISkinSpacing.small)
    }
}
