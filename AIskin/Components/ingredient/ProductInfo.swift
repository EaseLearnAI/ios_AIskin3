//
//  ProductInfo.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ProductInfo: View {
    let product: Product
    @State private var isFavorite: Bool = false
    
    // 处理图片URL，确保正确解码，并将HTTP转换为HTTPS以符合ATS策略
    private var productImageUrl: URL? {
        guard let imageUrlString = product.imageUrl else {
            print("🖼️ 图片URL为空，使用默认图片")
            return URL(string: "https://images.unsplash.com/photo-1556228578-af63f552e1bc?w=200")
        }
        
        print("\n===== 🖼️ 处理产品图片URL ======")
        print("📋 原始URL字符串: \(imageUrlString)")
        
        // 将HTTP转换为HTTPS以符合iOS ATS策略
        var processedUrlString = imageUrlString
        if processedUrlString.hasPrefix("http://") {
            processedUrlString = processedUrlString.replacingOccurrences(of: "http://", with: "https://")
            print("🔒 将HTTP转换为HTTPS: \(processedUrlString)")
        }
        
        // 如果URL已经包含http://或https://，直接使用
        if processedUrlString.hasPrefix("https://") {
            // 尝试解码URL编码的字符
            if let decodedString = processedUrlString.removingPercentEncoding {
                print("📋 解码后的URL字符串: \(decodedString)")
                if let url = URL(string: decodedString) {
                    print("✅ URL创建成功: \(url.absoluteString)")
                    return url
                } else {
                    print("❌ 解码后的URL无法创建URL对象")
                }
            }
            
            // 如果解码失败，尝试直接使用处理后的字符串
            if let url = URL(string: processedUrlString) {
                print("✅ 使用处理后的URL字符串创建URL: \(url.absoluteString)")
                return url
            } else {
                print("❌ 处理后的URL字符串无法创建URL对象")
            }
        }
        
        // 如果都不行，尝试直接创建
        if let url = URL(string: processedUrlString) {
            print("✅ 直接创建URL: \(url.absoluteString)")
            return url
        }
        
        print("❌ 所有URL创建方式都失败，使用默认图片")
        return URL(string: "https://images.unsplash.com/photo-1556228578-af63f552e1bc?w=200")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Product Image
                AsyncImage(url: productImageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 96, height: 96)
                            .onAppear {
                                print("🖼️ AsyncImage状态: empty - 正在加载图片")
                                if let url = productImageUrl {
                                    print("🖼️ 加载URL: \(url.absoluteString)")
                                }
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .onAppear {
                                print("🖼️ AsyncImage状态: success - 图片加载成功")
                                if let url = productImageUrl {
                                    print("✅ 图片已成功显示在界面上，URL: \(url.absoluteString)")
                                }
                            }
                    case .failure(let error):
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                            .onAppear {
                                print("🖼️ AsyncImage状态: failure - 图片加载失败")
                                print("❌ 错误信息: \(error.localizedDescription)")
                                if let url = productImageUrl {
                                    print("❌ 失败的URL: \(url.absoluteString)")
                                }
                            }
                    @unknown default:
                        EmptyView()
                            .onAppear {
                                print("🖼️ AsyncImage状态: unknown")
                            }
                    }
                }
                .frame(width: 96, height: 96)
                .cornerRadius(8)
                .background(Color.gray.opacity(0.1))
                .clipped()
                .onAppear {
                    if let url = productImageUrl {
                        print("\n===== 🖼️ 图片视图已出现 ======")
                        print("📋 图片URL: \(url.absoluteString)")
                        print("📋 URL Scheme: \(url.scheme ?? "无")")
                        print("📋 URL Host: \(url.host ?? "无")")
                        print("📋 URL Path: \(url.path)")
                    } else {
                        print("❌ 图片URL为空")
                    }
                }
                
                // Product Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.133, green: 0.133, blue: 0.200))
                        .lineLimit(2)
                    
                    // Product Description
                    if let description = product.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.459, green: 0.459, blue: 0.459))
                            .lineLimit(2)
                    }
                    
                    // Product Tags - 使用真实数据
                    HStack(spacing: 8) {
                        if let label = product.label, !label.isEmpty {
                            ProductTag(icon: "tag.fill", text: label, color: Color(red: 0.204, green: 0.557, blue: 0.239))
                        }
                        
                        // 根据产品成分显示标签
                        if !product.ingredients.isEmpty {
                            ProductTag(icon: "checkmark.circle.fill", text: "已提取成分", color: Color(red: 0.098, green: 0.463, blue: 0.824))
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(red: 1.0, green: 0.714, blue: 0.757).opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

struct ProductTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 12))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}




