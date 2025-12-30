//
//  APIClient.swift
//  AIskin
//
//  Created by AI Assistant
//

import Foundation
import Combine

/// 通用API响应结构
struct APIResponse<T: Codable>: Codable {
    var success: Bool
    var message: String?
    var data: T?
    var error: String?
}

/// API错误类型
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case networkError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有返回数据"
        case .decodingError:
            return "数据解析错误"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .unauthorized:
            return "未授权，请重新登录"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .unknown:
            return "未知错误"
        }
    }
}

/// 通用API客户端
class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "https://www.lunzo.site/api"
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120.0 // 2分钟超时
        configuration.timeoutIntervalForResource = 120.0
        self.session = URLSession(configuration: configuration)
    }
    
    /// 执行GET请求
    func get<T: Codable>(
        endpoint: String,
        requiresAuth: Bool = true,
        queryParams: [String: String]? = nil
    ) async throws -> T {
        print("\n===== 🌐 API GET 请求 ======")
        print("📡 请求开始")
        
        var urlString = "\(baseURL)\(endpoint)"
        
        // 添加查询参数
        if let params = queryParams, !params.isEmpty {
            let queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            var components = URLComponents(string: urlString)
            components?.queryItems = queryItems
            urlString = components?.url?.absoluteString ?? urlString
            print("📋 查询参数: \(params)")
        }
        
        guard let url = URL(string: urlString) else {
            print("❌ 错误: 无效的URL - \(urlString)")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证头
        var headers: [String: String] = ["Content-Type": "application/json"]
        if requiresAuth {
            if let token = AuthService.shared.getToken() {
                let authHeader = "Bearer \(token)"
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                headers["Authorization"] = "Bearer \(token.prefix(20))..." // 只显示前20个字符
                print("🔐 已添加认证Token")
            } else {
                print("⚠️ 警告: 需要认证但未找到Token")
            }
        }
        
        print("🔗 URL: \(urlString)")
        print("📋 Method: GET")
        print("📦 Headers: \(headers)")
        
        var responseData: Data?
        
        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: request)
            responseData = data
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 错误: 无效的HTTP响应")
                throw APIError.unknown
            }
            
            print("\n✅ 收到响应")
            print("📊 Status Code: \(httpResponse.statusCode)")
            print("📋 Response Headers: \(httpResponse.allHeaderFields)")
            print("⏱️ 请求耗时: \(String(format: "%.2f", duration))秒")
            
            // 打印完整响应数据
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response Body: \(responseString)")
            } else {
                print("📦 Response Body: (无法解析为字符串，数据长度: \(data.count) bytes)")
            }
            
            // 检查状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    print("❌ 错误: 未授权 (401)")
                    throw APIError.unauthorized
                }
                
                // 404错误可能表示端点不存在，但服务器在运行
                if httpResponse.statusCode == 404 {
                    // 尝试解析错误消息
                    if let errorData = try? JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: data) {
                        print("⚠️ 端点不存在 (404): \(errorData.message ?? "未找到")")
                        throw APIError.serverError("HTTP 404 - 端点不存在: \(errorData.message ?? "未找到")")
                    } else {
                        // 如果不是JSON响应，可能是简单的404
                        print("⚠️ 端点不存在 (404)")
                        throw APIError.serverError("HTTP 404 - 端点不存在")
                    }
                }
                
                // 尝试解析错误消息
                if let errorData = try? JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: data) {
                    print("❌ 服务器错误: \(errorData.message ?? "未知错误")")
                    throw APIError.serverError(errorData.message ?? "服务器错误")
                }
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            // 解析响应
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let result = try decoder.decode(T.self, from: data)
            print("✅ API响应成功")
            print("📋 解析后的数据: \(String(describing: result))")
            print("===== ✅ GET 请求完成 =====\n")
            
            return result
        } catch let error as DecodingError {
            print("❌ 数据解析错误: \(error)")
            if let data = responseData, let jsonString = String(data: data, encoding: .utf8) {
                print("📄 原始JSON: \(jsonString)")
            }
            throw APIError.decodingError
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ 网络错误: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    /// 执行POST请求
    func post<T: Codable, U: Codable>(
        endpoint: String,
        body: U,
        requiresAuth: Bool = true
    ) async throws -> T {
        print("\n===== 🌐 API POST 请求 ======")
        print("📡 请求开始")
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("❌ 错误: 无效的URL")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证头
        var headers: [String: String] = ["Content-Type": "application/json"]
        if requiresAuth {
            if let token = AuthService.shared.getToken() {
                let authHeader = "Bearer \(token)"
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                headers["Authorization"] = "Bearer \(token.prefix(20))..." // 只显示前20个字符
                print("🔐 已添加认证Token")
            } else {
                print("⚠️ 警告: 需要认证但未找到Token")
            }
        }
        
        // 编码请求体
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        print("🔗 URL: \(url.absoluteString)")
        print("📋 Method: POST")
        print("📦 Headers: \(headers)")
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        
        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 错误: 无效的HTTP响应")
                throw APIError.unknown
            }
            
            print("\n✅ 收到响应")
            print("📊 Status Code: \(httpResponse.statusCode)")
            print("📋 Response Headers: \(httpResponse.allHeaderFields)")
            print("⏱️ 请求耗时: \(String(format: "%.2f", duration))秒")
            
            // 打印完整响应数据
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response Body: \(responseString)")
            } else {
                print("📦 Response Body: (无法解析为字符串，数据长度: \(data.count) bytes)")
            }
            
            // 检查状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    print("❌ 错误: 未授权 (401)")
                    throw APIError.unauthorized
                }
                
                // 尝试解析错误消息
                if let errorData = try? JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: data) {
                    print("❌ 服务器错误: \(errorData.message ?? "未知错误")")
                    throw APIError.serverError(errorData.message ?? "服务器错误")
                }
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            // 解析响应
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let result = try decoder.decode(T.self, from: data)
            print("✅ API响应成功")
            print("📋 解析后的数据: \(String(describing: result))")
            print("===== ✅ POST 请求完成 =====\n")
            
            return result
        } catch let error as DecodingError {
            print("❌ 数据解析错误: \(error)")
            throw APIError.decodingError
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ 网络错误: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    /// 执行POST请求（上传文件）
    func upload<T: Codable>(
        endpoint: String,
        fileData: Data,
        fileName: String,
        fieldName: String,
        mimeType: String = "image/jpeg",
        requiresAuth: Bool = true
    ) async throws -> T {
        print("\n===== 🌐 API POST (文件上传) 请求 ======")
        print("📡 请求开始")
        print("📷 上传文件信息:")
        print("   - 文件名: \(fileName)")
        print("   - 文件大小: \(String(format: "%.2f", Double(fileData.count) / 1024.0)) KB")
        print("   - MIME类型: \(mimeType)")
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("❌ 错误: 无效的URL")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 创建multipart/form-data边界
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var headers: [String: String] = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        // 添加认证头
        if requiresAuth {
            if let token = AuthService.shared.getToken() {
                let authHeader = "Bearer \(token)"
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                headers["Authorization"] = "Bearer \(token.prefix(20))..."
                print("🔐 已添加认证Token")
            } else {
                print("⚠️ 警告: 需要认证但未找到Token")
            }
        }
        
        // 构建multipart body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🔗 URL: \(url.absoluteString)")
        print("📋 Method: POST (multipart/form-data)")
        print("📦 Headers: \(headers)")
        
        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 错误: 无效的HTTP响应")
                throw APIError.unknown
            }
            
            print("\n✅ 收到响应")
            print("📊 Status Code: \(httpResponse.statusCode)")
            print("⏱️ 上传耗时: \(String(format: "%.2f", duration))秒")
            
            // 打印响应数据
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response Body: \(responseString)")
            } else {
                print("📦 Response Body: (无法解析为字符串，数据长度: \(data.count) bytes)")
            }
            
            // 检查状态码
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    print("❌ 错误: 未授权 (401)")
                    throw APIError.unauthorized
                }
                
                if let errorData = try? JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: data) {
                    print("❌ 服务器错误: \(errorData.message ?? "未知错误")")
                    throw APIError.serverError(errorData.message ?? "服务器错误")
                }
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            // 解析响应
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let result = try decoder.decode(T.self, from: data)
            print("✅ 文件上传成功")
            print("===== ✅ UPLOAD 请求完成 =====\n")
            
            return result
        } catch let error as DecodingError {
            print("❌ 数据解析错误: \(error)")
            throw APIError.decodingError
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ 网络错误: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    /// 执行PUT请求
    func put<T: Codable, U: Codable>(
        endpoint: String,
        body: U,
        requiresAuth: Bool = true
    ) async throws -> T {
        print("\n===== 🌐 API PUT 请求 ======")
        print("📡 请求开始")
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("❌ 错误: 无效的URL")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var headers: [String: String] = ["Content-Type": "application/json"]
        if requiresAuth {
            if let token = AuthService.shared.getToken() {
                let authHeader = "Bearer \(token)"
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                headers["Authorization"] = "Bearer \(token.prefix(20))..."
                print("🔐 已添加认证Token")
            }
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        print("🔗 URL: \(url.absoluteString)")
        print("📋 Method: PUT")
        print("📦 Headers: \(headers)")
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        
        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 错误: 无效的HTTP响应")
                throw APIError.unknown
            }
            
            print("\n✅ 收到响应")
            print("📊 Status Code: \(httpResponse.statusCode)")
            print("⏱️ 请求耗时: \(String(format: "%.2f", duration))秒")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response Body: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("请求失败")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(T.self, from: data)
            print("✅ API响应成功")
            print("===== ✅ PUT 请求完成 =====\n")
            
            return result
        } catch {
            print("❌ 请求失败: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    /// 执行PATCH请求
    func patch<T: Codable, U: Codable>(
        endpoint: String,
        body: U,
        requiresAuth: Bool = true
    ) async throws -> T {
        print("\n===== 🌐 API PATCH 请求 ======")
        print("📡 请求开始")
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("❌ 错误: 无效的URL")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var headers: [String: String] = ["Content-Type": "application/json"]
        if requiresAuth {
            if let token = AuthService.shared.getToken() {
                let authHeader = "Bearer \(token)"
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                headers["Authorization"] = "Bearer \(token.prefix(20))..."
                print("🔐 已添加认证Token")
            }
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        print("🔗 URL: \(url.absoluteString)")
        print("📋 Method: PATCH")
        print("📦 Headers: \(headers)")
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("📤 Request Body: \(bodyString)")
        }
        
        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 错误: 无效的HTTP响应")
                throw APIError.unknown
            }
            
            print("\n✅ 收到响应")
            print("📊 Status Code: \(httpResponse.statusCode)")
            print("⏱️ 请求耗时: \(String(format: "%.2f", duration))秒")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response Body: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("请求失败")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(T.self, from: data)
            print("✅ API响应成功")
            print("===== ✅ PATCH 请求完成 =====\n")
            
            return result
        } catch {
            print("❌ 请求失败: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    /// 执行DELETE请求
    func delete<T: Codable>(
        endpoint: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        print("\n===== 🌐 API DELETE 请求 ======")
        print("📡 请求开始")
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("❌ 错误: 无效的URL")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var headers: [String: String] = ["Content-Type": "application/json"]
        if requiresAuth {
            if let token = AuthService.shared.getToken() {
                let authHeader = "Bearer \(token)"
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                headers["Authorization"] = "Bearer \(token.prefix(20))..."
                print("🔐 已添加认证Token")
            }
        }
        
        print("🔗 URL: \(url.absoluteString)")
        print("📋 Method: DELETE")
        print("📦 Headers: \(headers)")
        
        var responseData: Data?
        
        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: request)
            responseData = data
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 错误: 无效的HTTP响应")
                throw APIError.unknown
            }
            
            print("\n✅ 收到响应")
            print("📊 Status Code: \(httpResponse.statusCode)")
            print("⏱️ 请求耗时: \(String(format: "%.2f", duration))秒")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response Body: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    print("❌ 错误: 未授权 (401)")
                    throw APIError.unauthorized
                }
                
                // 尝试解析错误消息
                if let errorData = try? JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: data) {
                    print("❌ 服务器错误: \(errorData.message ?? "未知错误")")
                    throw APIError.serverError(errorData.message ?? "删除失败")
                }
                throw APIError.serverError("HTTP \(httpResponse.statusCode) - 删除失败")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(T.self, from: data)
            print("✅ 删除成功")
            print("===== ✅ DELETE 请求完成 =====\n")
            
            return result
        } catch let error as DecodingError {
            print("❌ 数据解析错误: \(error)")
            if let data = responseData, let jsonString = String(data: data, encoding: .utf8) {
                print("📄 原始JSON: \(jsonString)")
            }
            throw APIError.decodingError
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ 删除失败: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
}

/// 空响应类型（用于某些API调用）
struct EmptyResponse: Codable {}

