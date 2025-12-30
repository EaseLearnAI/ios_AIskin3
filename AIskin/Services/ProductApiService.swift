//
//  ProductApiService.swift
//  AIskin
//
//  Created by AI Assistant
//

import Foundation
import UIKit

/// 产品API响应数据结构
struct ProductResponse: Codable {
    var success: Bool
    var message: String?
    var data: ProductData?
}

struct ProductData: Codable {
    var product: Product
}

struct ProductsListResponse: Codable {
    var success: Bool
    var count: Int?
    var total: Int?
    var data: ProductsListData?
}

struct ProductsListData: Codable {
    var products: [Product]
}

/// 创建产品请求
struct CreateProductRequest: Codable {
    var name: String?
    var description: String?
    var label: String?
    var openingDate: String? // ISO 8601格式
}

/// 更新产品请求
struct UpdateProductRequest: Codable {
    var name: String?
    var description: String?
    var label: String?
}

/// 提取成分响应
struct ExtractIngredientsResponse: Codable {
    var success: Bool
    var message: String?
    var data: ExtractIngredientsData?
}

struct ExtractIngredientsData: Codable {
    var name: String
    var ingredients: [String]
    var rawContent: String?
}

/// 上传图片响应
struct UploadImageResponse: Codable {
    var success: Bool
    var message: String?
    var data: UploadImageData?
}

struct UploadImageData: Codable {
    var imageUrl: String
}

/// 产品API服务
class ProductApiService {
    static let shared = ProductApiService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    /// 创建产品
    func createProduct(
        name: String? = nil,
        description: String? = nil,
        label: String? = nil,
        openingDate: Date? = nil
    ) async throws -> Product {
        print("🎯 创建产品API调用开始")
        print("📊 产品数据:")
        print("   - 名称: \(name ?? "未命名产品")")
        print("   - 标签: \(label ?? "未设置")")
        
        let formatter = ISO8601DateFormatter()
        let openingDateString = openingDate.map { formatter.string(from: $0) }
        
        let request = CreateProductRequest(
            name: name,
            description: description,
            label: label,
            openingDate: openingDateString
        )
        
        let response: ProductResponse = try await apiClient.post(
            endpoint: "/products",
            body: request,
            requiresAuth: true
        )
        
        guard response.success, let product = response.data?.product else {
            print("❌ 创建产品失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "创建产品失败")
        }
        
        print("✅ 创建产品成功")
        print("📋 产品信息:")
        print("   - 产品ID: \(product.id)")
        print("   - 产品名称: \(product.name)")
        
        return product
    }
    
    /// 上传产品图片
    func uploadProductImage(productId: String, image: UIImage) async throws -> String {
        print("🎯 上传产品图片API调用开始")
        print("📷 产品ID: \(productId)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 错误: 无法将图片转换为数据")
            throw APIError.unknown
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        
        let response: UploadImageResponse = try await apiClient.upload(
            endpoint: "/products/\(productId)/upload-image",
            fileData: imageData,
            fileName: fileName,
            fieldName: "productImage",
            mimeType: "image/jpeg",
            requiresAuth: true
        )
        
        guard response.success, let imageUrl = response.data?.imageUrl else {
            print("❌ 上传图片失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "上传图片失败")
        }
        
        print("✅ 上传图片成功")
        print("📋 图片URL: \(imageUrl)")
        
        return imageUrl
    }
    
    /// 提取产品成分
    func extractIngredients(productId: String) async throws -> (name: String, ingredients: [String]) {
        print("🎯 提取产品成分API调用开始")
        print("📊 产品ID: \(productId)")
        
        struct ExtractRequest: Codable {}
        
        let response: ExtractIngredientsResponse = try await apiClient.post(
            endpoint: "/products/\(productId)/extract-ingredients",
            body: ExtractRequest(),
            requiresAuth: true
        )
        
        guard response.success, let data = response.data else {
            print("❌ 提取成分失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "提取成分失败")
        }
        
        print("✅ 提取成分成功")
        print("📋 提取结果:")
        print("   - 产品名称: \(data.name)")
        print("   - 成分数量: \(data.ingredients.count)")
        print("   - 成分列表: \(data.ingredients.joined(separator: ", "))")
        
        return (data.name, data.ingredients)
    }
    
    /// 获取产品列表
    func getProducts(page: Int = 1, limit: Int = 10) async throws -> [Product] {
        print("🎯 获取产品列表API调用开始")
        print("📊 分页参数:")
        print("   - 页码: \(page)")
        print("   - 每页数量: \(limit)")
        
        let response: ProductsListResponse = try await apiClient.get(
            endpoint: "/products",
            requiresAuth: true,
            queryParams: [
                "page": "\(page)",
                "limit": "\(limit)"
            ]
        )
        
        guard response.success, let products = response.data?.products else {
            print("❌ 获取产品列表失败")
            throw APIError.serverError("获取产品列表失败")
        }
        
        print("✅ 获取产品列表成功")
        print("📋 产品信息:")
        print("   - 总数: \(response.total ?? 0)")
        print("   - 当前页数量: \(products.count)")
        for product in products {
            print("     • \(product.name) (ID: \(product.id))")
        }
        
        return products
    }
    
    /// 获取单个产品详情
    func getProduct(productId: String) async throws -> Product {
        print("🎯 获取产品详情API调用开始")
        print("📊 产品ID: \(productId)")
        
        let response: ProductResponse = try await apiClient.get(
            endpoint: "/products/\(productId)",
            requiresAuth: true
        )
        
        guard response.success, let product = response.data?.product else {
            print("❌ 获取产品详情失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "获取产品详情失败")
        }
        
        print("✅ 获取产品详情成功")
        print("📋 产品信息:")
        print("   - 名称: \(product.name)")
        print("   - 标签: \(product.label ?? "未设置")")
        print("   - 成分数量: \(product.ingredients.count)")
        
        return product
    }
    
    /// 获取用户的所有产品
    func getUserProducts(userId: String) async throws -> [Product] {
        print("🎯 获取用户产品API调用开始")
        print("📊 用户ID: \(userId)")
        
        let response: ProductsListResponse = try await apiClient.get(
            endpoint: "/products/user/\(userId)",
            requiresAuth: true
        )
        
        guard response.success, let products = response.data?.products else {
            print("❌ 获取用户产品失败")
            throw APIError.serverError("获取用户产品失败")
        }
        
        print("✅ 获取用户产品成功")
        print("📋 产品数量: \(products.count)")
        
        return products
    }
    
    /// 根据标签获取用户产品
    func getUserProductsByLabel(userId: String, label: String) async throws -> [Product] {
        print("🎯 根据标签获取用户产品API调用开始")
        print("📊 用户ID: \(userId)")
        print("📊 标签: \(label)")
        
        let response: ProductsListResponse = try await apiClient.get(
            endpoint: "/products/user/\(userId)/label/\(label)",
            requiresAuth: true
        )
        
        guard response.success, let products = response.data?.products else {
            print("❌ 获取用户产品失败")
            throw APIError.serverError("获取用户产品失败")
        }
        
        print("✅ 获取用户产品成功")
        print("📋 产品数量: \(products.count)")
        
        return products
    }
    
    /// 更新产品
    func updateProduct(
        productId: String,
        name: String? = nil,
        description: String? = nil,
        label: String? = nil
    ) async throws -> Product {
        print("🎯 更新产品API调用开始")
        print("📊 产品ID: \(productId)")
        
        let request = UpdateProductRequest(
            name: name,
            description: description,
            label: label
        )
        
        let response: ProductResponse = try await apiClient.put(
            endpoint: "/products/\(productId)",
            body: request,
            requiresAuth: true
        )
        
        guard response.success, let product = response.data?.product else {
            print("❌ 更新产品失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "更新产品失败")
        }
        
        print("✅ 更新产品成功")
        print("📋 更新后的产品信息:")
        print("   - 名称: \(product.name)")
        
        return product
    }
    
    /// 删除产品
    func deleteProduct(productId: String) async throws {
        print("🎯 删除产品API调用开始")
        print("📊 产品ID: \(productId)")
        
        struct DeleteResponse: Codable {
            var success: Bool
            var message: String?
        }
        
        let response: DeleteResponse = try await apiClient.delete(
            endpoint: "/products/\(productId)",
            requiresAuth: true
        )
        
        guard response.success else {
            print("❌ 删除产品失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "删除产品失败")
        }
        
        print("✅ 删除产品成功")
    }
}




