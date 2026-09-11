//
//  ProductList.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ProductList: View {
    let products: [Product]
    let categories: [ProductCategory]
    @Binding var selectedCategory: String
    @Binding var selectionMode: Bool
    @Binding var selectedProductIds: Set<String>
    let onProductSelected: (Product) -> Void
    let onToggleSelection: (String) -> Void
    let onDeleteProduct: ((String) -> Void)?
    var onBeginConflict: ((String?) -> Void)? = nil
    var onCancelConflict: (() -> Void)? = nil
    var onAddProduct: (() -> Void)? = nil
    var onEditProduct: ((Product) -> Void)? = nil

    private var filteredProducts: [Product] {
        guard selectedCategory != "all" else { return products }
        return products.filter { $0.label == selectedCategory }
    }

    var body: some View {
        VStack(spacing: AISkinSpacing.xxSmall) {
            AISkinUnderlineTabs(
                items: categories.map(\.id),
                selection: $selectedCategory,
                title: { id in categories.first { $0.id == id }?.name ?? id },
                size: .regular,
                itemAccessibilityIdentifier: { "cabinet.category.\($0)" }
            )
            .overlay(alignment: .bottom) { AISkinDivider() }
            .lookinName("product.category-filter")

            HStack {
                Text(selectionMode ? "已选 \(selectedProductIds.count) 件" : "共 \(filteredProducts.count) 件")
                    .font(AISkinTypography.callout)
                    .foregroundStyle(AISkinColor.textSecondary)
                Spacer()
                Button {
                    if selectionMode { onCancelConflict?() } else { onBeginConflict?(nil) }
                } label: {
                    Label(selectionMode ? "取消检测" : "冲突检测", systemImage: "square.3.layers.3d")
                        .font(AISkinTypography.callout)
                        .foregroundStyle(AISkinColor.textSecondary)
                        .frame(minHeight: AISkinLayout.regularUnderlineTabHeight)
                }
                .buttonStyle(AISkinPressableStyle())
                .accessibilityIdentifier("cabinet.conflict-mode")
            }
            .padding(.bottom, AISkinSpacing.xSmall)

            if filteredProducts.isEmpty {
                AISkinCard {
                    AISkinStateView(
                        content: .empty(
                            title: selectedCategory == "all" ? "还没有护肤产品" : "还没有\(selectedCategory)产品",
                            message: "添加你的\(selectedCategory == "all" ? "护肤" : selectedCategory)产品，查看成分分析与搭配建议。",
                            systemImage: "shippingbox"
                        ),
                        actionTitle: selectedCategory == "all" ? "添加产品" : "添加\(selectedCategory)产品",
                        action: onAddProduct
                    )
                }
            } else {
                LazyVStack(spacing: AISkinSpacing.cabinetCardGap) {
                    ForEach(filteredProducts) { product in
                        ProductCard(
                            product: product,
                            isSelected: selectedProductIds.contains(product.id),
                            isSelectionMode: selectionMode,
                            onSelect: {
                                if selectionMode {
                                    onToggleSelection(product.id)
                                } else {
                                    onProductSelected(product)
                                }
                            },
                            onDelete: onDeleteProduct,
                            onConflict: { onBeginConflict?(product.id) },
                            onEdit: onEditProduct.map { edit in { edit(product) } }
                        )
                    }
                }
                .lookinName("product.cards-list")
            }
        }
        .lookinName("product.library")
    }
}

struct ProductCategory: Identifiable {
    let id: String
    let name: String

    static let defaultCategories: [ProductCategory] = [
        ProductCategory(id: "all", name: "全部"),
        ProductCategory(id: "精华", name: "精华"),
        ProductCategory(id: "面霜", name: "面霜"),
        ProductCategory(id: "防晒", name: "防晒"),
        ProductCategory(id: "洁面", name: "洁面")
    ]

    static let registrationCategories = ["洁面", "精华", "面膜", "防晒", "面霜", "爽肤水", "乳液", "眼霜", "其他"]
        .map { ProductCategory(id: $0, name: $0) }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let isSelectionMode: Bool
    let onSelect: () -> Void
    let onDelete: ((String) -> Void)?
    var onConflict: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil

    @State private var showsDeleteConfirmation = false

    var body: some View {
        AISkinCard(inset: .none, state: isSelected && isSelectionMode ? .selected : .normal) {
            AISkinProductRow(
                title: product.name,
                summary: product.description,
                category: product.label,
                imageURL: product.imageUrl.flatMap(URL.init(string:)),
                accessibilityIdentifier: "cabinet.product.\(product.id)",
                accessibilityValue: isSelectionMode ? (isSelected ? "已选择" : "未选择") : "查看成分分析",
                onSelect: onSelect
            ) {
                if isSelectionMode {
                    Button(action: onSelect) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(AISkinTypography.iconMedium)
                            .foregroundStyle(isSelected ? AISkinColor.accent : AISkinColor.textSecondary)
                            .frame(width: AISkinLayout.minimumTapHeight, height: AISkinLayout.minimumTapHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(AISkinPressableStyle())
                    .accessibilityLabel(isSelected ? "取消选择\(product.name)" : "选择\(product.name)")
                } else if onDelete != nil || onConflict != nil || onEdit != nil {
                    optionsMenu
                }
            }
        }
        .lookinName("product.card.\(product.id)")
        .confirmationDialog(
            "删除产品？",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除\(product.name)", role: .destructive) {
                onDelete?(product.id)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后将无法恢复该产品及其分析结果。")
        }
    }

    private var optionsMenu: some View {
        Menu {
            if let onEdit {
                Button("编辑产品", systemImage: "pencil", action: onEdit)
                    .accessibilityIdentifier("cabinet.edit.\(product.id)")
            }
            if let onConflict {
                Button("冲突检测", systemImage: "square.3.layers.3d", action: onConflict)
            }
            if onDelete != nil {
                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Label("删除产品", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(AISkinTypography.iconSmall)
                .foregroundStyle(AISkinColor.textSecondary)
                .frame(width: AISkinLayout.minimumTapHeight, height: AISkinLayout.minimumTapHeight)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("更多产品操作")
        .accessibilityIdentifier("cabinet.more.\(product.id)")
    }

}
