import SwiftUI

enum ProductCaptureSource { case camera, library }

struct AddProduct: View {
    let onCapture: (ProductCaptureSource) -> Void
    @State private var selectedFeature: CabinetFeature?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: AISkinSpacing.small) {
                Text("拍一张，就能分析")
                    .font(AISkinTypography.cabinetEmptyTitle)
                    .foregroundStyle(AISkinColor.textPrimary)
                Text("对准成分表，剩下交给 AI")
                    .font(AISkinTypography.reportBody)
                    .foregroundStyle(AISkinColor.textSecondary)
            }
            AISkinCaptureGuide(kind: .product)
                .padding(.vertical, AISkinSpacing.xLarge)
            AISkinButton(action: { onCapture(.camera) }) {
                Label("拍照分析", systemImage: "camera")
            }
            .accessibilityIdentifier("cabinet.add-product")
            Button("从相册上传") { onCapture(.library) }
                .font(AISkinTypography.routineTitle)
                .foregroundStyle(AISkinColor.textSecondary)
                .frame(minHeight: AISkinLayout.minimumTapHeight)
                .buttonStyle(AISkinPressableStyle())
                .accessibilityIdentifier("cabinet.empty.choose-photo")
            AISkinDivider().padding(.top, AISkinSpacing.xLarge)
            HStack {
                ForEach(CabinetFeature.allCases) { feature in
                    AISkinSkinReportAction(title: feature.rawValue, systemImage: feature.icon) {
                        selectedFeature = feature
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("cabinet.empty.\(feature.id)")
                }
            }
            .padding(.top, AISkinSpacing.xLarge)
        }
        .padding(.vertical, AISkinSpacing.large)
        .lookinName("product.add-panel")
        .sheet(item: $selectedFeature, onDismiss: {
            if pendingCapture { pendingCapture = false; onCapture(.library) }
        }) { feature in
            AISkinBottomSheet(title: feature.rawValue, onClose: { selectedFeature = nil }) {
                AISkinReportTextItem(text: feature.description)
            } footer: {
                AISkinButton(action: {
                    pendingCapture = true
                    selectedFeature = nil
                }) { Text("添加成分表照片") }
            }
            .presentationDetents([.height(AISkinReportTokens.explanationSheetHeight), .large])
        }

    }

    @State private var pendingCapture = false
}

private enum CabinetFeature: String, CaseIterable, Identifiable {
    case advice = "AI 建议", risk = "风险告知", conflict = "冲突检测"
    var id: String { switch self { case .advice: "advice"; case .risk: "risk"; case .conflict: "conflict" } }
    var icon: String { switch self { case .advice: "sparkles"; case .risk: "shield.lefthalf.filled"; case .conflict: "square.3.layers.3d" } }
    var description: String {
        switch self {
        case .advice: "添加成分表照片，查看这件护肤品的使用建议。"
        case .risk: "添加成分表照片，了解配方中需要留意的成分。"
        case .conflict: "添加至少 2 件护肤品，再检查它们的成分搭配。"
        }
    }
}
