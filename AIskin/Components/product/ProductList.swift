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
    
    @State private var activeOptionsMenu: String?
    
    var filteredProducts: [Product] {
        if selectedCategory == "all" {
            return products
        }
        return products.filter { $0.label == selectedCategory }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.id) { category in
                        CategoryButton(
                            category: category,
                            isActive: selectedCategory == category.id,
                            action: {
                                selectedCategory = category.id
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .lookinName("product.category-filter")
            
            // Products List
            if filteredProducts.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredProducts) { product in
                            ProductCard(
                                product: product,
                                isSelected: selectedProductIds.contains(product.id),
                                isSelectionMode: selectionMode,
                                activeOptionsMenu: $activeOptionsMenu,
                                onSelect: {
                                    if selectionMode {
                                        onToggleSelection(product.id)
                                    } else {
                                        onProductSelected(product)
                                    }
                                },
                                onDelete: onDeleteProduct
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .lookinName("product.cards-scroll")
            }
        }
        .lookinName("product.library")
    }
}

struct ProductCategory: Identifiable {
    let id: String
    let name: String
    let color: Color?
    
    static let defaultCategories: [ProductCategory] = [
        ProductCategory(id: "all", name: "全部产品", color: nil),
        ProductCategory(id: "洁面", name: "洁面", color: Color(red: 0.129, green: 0.588, blue: 0.953)),
        ProductCategory(id: "精华", name: "精华", color: Color(red: 1.0, green: 0.596, blue: 0.0)),
        ProductCategory(id: "面膜", name: "面膜", color: Color(red: 0.612, green: 0.153, blue: 0.690)),
        ProductCategory(id: "防晒", name: "防晒", color: Color(red: 0.957, green: 0.263, blue: 0.212)),
        ProductCategory(id: "面霜", name: "面霜", color: Color(red: 0.298, green: 0.686, blue: 0.314)),
        ProductCategory(id: "爽肤水", name: "爽肤水", color: Color(red: 0.012, green: 0.663, blue: 0.957)),
        ProductCategory(id: "乳液", name: "乳液", color: Color(red: 0.545, green: 0.765, blue: 0.290)),
        ProductCategory(id: "眼霜", name: "眼霜", color: Color(red: 0.404, green: 0.227, blue: 0.718))
    ]
}

struct CategoryButton: View {
    let category: ProductCategory
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let color = category.color {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                
                Text(category.name)
                    .font(.system(size: 12))
            }
            .foregroundColor(isActive ? .white : Color(red: 0.380, green: 0.380, blue: 0.380))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color(red: 0.973, green: 0.741, blue: 0.816) : Color.white)
            .cornerRadius(20)
        }
        .lookinName("product.category.\(category.id)")
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let isSelectionMode: Bool
    @Binding var activeOptionsMenu: String?
    let onSelect: () -> Void
    let onDelete: ((String) -> Void)?
    
    // 处理图片URL，将HTTP转换为HTTPS以符合ATS策略
    private func safeImageUrl(_ urlString: String?) -> URL? {
        guard let urlString = urlString else {
            return URL(string: "https://images.unsplash.com/photo-1556228578-af63f552e1bc?w=200")
        }
        
        // 将HTTP转换为HTTPS以符合iOS ATS策略
        var processedUrlString = urlString
        if processedUrlString.hasPrefix("http://") {
            processedUrlString = processedUrlString.replacingOccurrences(of: "http://", with: "https://")
        }
        
        return URL(string: processedUrlString)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Checkbox (if in selection mode)
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? Color(red: 0.973, green: 0.741, blue: 0.816) : Color.gray.opacity(0.3))
                }
                
                // Product Image
                AsyncImage(url: safeImageUrl(product.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 64, height: 64)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 64, height: 64)
                .cornerRadius(8)
                .background(Color.gray.opacity(0.1))
                .clipped()
                
                // Product Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(product.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if !isSelectionMode {
                            Menu {
                                Button(role: .destructive, action: {
                                    onDelete?(product.id)
                                    activeOptionsMenu = nil
                                }) {
                                    Label("删除产品", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 0.741, green: 0.741, blue: 0.741))
                                    .padding(8)
                            }
                        }
                    }
                    
                    if let description = product.description {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 6) {
                        if let label = product.label, !label.isEmpty {
                            ProductTagView(text: label, style: .category)
                        }
                        
                        // Add other tags if needed
                    }
                }
                
                if !isSelectionMode {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(isSelected && isSelectionMode ? Color(red: 0.973, green: 0.741, blue: 0.816).opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected && isSelectionMode ? Color(red: 0.973, green: 0.741, blue: 0.816) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .lookinName("product.card.\(product.id)")
    }
}

struct ProductTagView: View {
    let text: String
    let style: TagStyle
    
    enum TagStyle {
        case category
        case feature
        case rating
        
        var backgroundColor: Color {
            switch self {
            case .category:
                return Color(red: 0.890, green: 0.949, blue: 0.992)
            case .feature:
                return Color(red: 1.0, green: 0.953, blue: 0.878)
            case .rating:
                return Color(red: 0.953, green: 0.898, blue: 0.961)
            }
        }
        
        var textColor: Color {
            switch self {
            case .category:
                return Color(red: 0.098, green: 0.463, blue: 0.824)
            case .feature:
                return Color(red: 0.902, green: 0.318, blue: 0.0)
            case .rating:
                return Color(red: 0.612, green: 0.153, blue: 0.690)
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 10))
            .foregroundColor(style.textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(style.backgroundColor)
            .cornerRadius(8)
            .lookinName("product.tag.\(text)")
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 0.741, green: 0.741, blue: 0.741))
            
            Text("暂无产品")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .lookinName("product.empty-state")
    }
}



