#if DEBUG
import Foundation

/// Debug-only in-process backend for complete UI and interaction iteration.
/// It speaks the same JSON contract as the live API, so screens and stores stay unchanged.
final class MockBackendHTTPClient: HTTPClient {
    private let backend = MockBackend()
    private let decoder: JSONDecoder
    private let latencyNanoseconds: UInt64

    init(
        decoder: JSONDecoder = .apiDecoder,
        latencyNanoseconds: UInt64 = 450_000_000
    ) {
        self.decoder = decoder
        self.latencyNanoseconds = latencyNanoseconds
    }

    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response {
        try await Task.sleep(nanoseconds: latency(for: request.path))
        let data = try await backend.response(
            path: request.path,
            method: request.method.rawValue,
            queryItems: request.queryItems,
            body: request.body
        )

        print("🧪 MOCK \(request.method.rawValue) \(request.path) → 200, \(data.count) bytes")

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            print("❌ Mock 响应解析失败：\(request.method.rawValue) \(request.path) / \(error)")
            throw APIError.decodingError
        }
    }

    private func latency(for path: String) -> UInt64 {
        if path.contains("analyze") || path == "/conflicts" || path == "/plans" {
            // UI regressions can hold a real in-process request long enough to
            // exercise cancellation; the live transport never reads this value.
            let milliseconds = ProcessInfo.processInfo.environment["AISKIN_MOCK_ANALYSIS_LATENCY_MS"]
                .flatMap(UInt64.init).map { min($0, 10_000) } ?? 900
            return max(latencyNanoseconds, milliseconds * 1_000_000)
        }
        return latencyNanoseconds
    }
}

private actor MockBackend {
    private var currentUser: [String: Any] = [
        "_id": "mock-user-001",
        "name": "UI 演示用户",
        "phone": "13800138000",
        "email": "demo@aiskin.local",
        "gender": "女"
    ]

    private var products: [[String: Any]] = [
        [
            "_id": "mock-product-cleanser",
            "name": "温和氨基酸洁面",
            "description": "低刺激日常洁面，适合晨间和晚间使用。",
            "ingredients": ["水", "椰油酰甘氨酸钾", "甘油", "泛醇"],
            "label": "洁面",
            "safetyScore": 92.0,
            "efficacyScore": 4.2,
            "overallRating": 4.6
        ],
        [
            "_id": "mock-product-serum",
            "name": "烟酰胺修护精华",
            "description": "用于提亮肤色并改善屏障状态。",
            "ingredients": ["水", "烟酰胺", "透明质酸钠", "神经酰胺NP"],
            "label": "精华",
            "safetyScore": 88.0,
            "efficacyScore": 4.55,
            "overallRating": 4.7
        ],
        [
            "_id": "mock-product-retinol",
            "name": "视黄醇焕肤精华",
            "description": "夜间使用的进阶功效精华。",
            "ingredients": ["水", "视黄醇", "角鲨烷", "生育酚"],
            "label": "精华",
            "safetyScore": 76.0,
            "efficacyScore": 4.65,
            "overallRating": 4.3
        ],
        [
            "_id": "mock-product-acid",
            "name": "温和水杨酸精华",
            "description": "针对黑头和毛孔的夜间护理产品。",
            "ingredients": ["水", "水杨酸", "甜菜碱", "泛醇"],
            "label": "精华",
            "safetyScore": 81.0,
            "efficacyScore": 4.45,
            "overallRating": 4.4
        ],
        [
            "_id": "mock-product-sunscreen",
            "name": "轻透防晒乳 SPF50+",
            "description": "通勤场景使用的轻薄型防晒。",
            "ingredients": ["氧化锌", "二氧化钛", "角鲨烷", "生育酚"],
            "label": "防晒",
            "safetyScore": 90.0,
            "efficacyScore": 4.65,
            "overallRating": 4.8
        ]
    ]

    // A demo account must start without a plan. A plan is created only after
    // the user completes the personalization form and explicitly generates it.
    private var plans: [[String: Any]] = []
    private var analyses: [[String: Any]] = []
    private var conflicts: [[String: Any]] = []
    private var activePlanID: String?
    private var dailyRecords: [String: [String: Any]] = [:]
    private var sequence = 100

    init() {
        // Explicit, in-process UI fixtures. Live accounts never use this backend.
        switch ProcessInfo.processInfo.environment["AISKIN_MOCK_PLAN_PREREQUISITES"] {
        case "empty":
            products = []
        case "report-only":
            products = []
            analyses = [Self.sampleAnalysis(id: "mock-plan-source")]
        case "complete":
            analyses = [Self.sampleAnalysis(id: "mock-plan-source")]
        default:
            break
        }
    }

    func response(path: String, method: String, queryItems: [URLQueryItem], body: Data?) throws -> Data {
        let payload = decodedBody(body)

        // Read-only membership preview. Mock mode can never create a payable order.
        if path == "/payments/catalog", method == "GET" {
            return try json(["success": true, "data": [
                "provider": "alipay", "environment": "sandbox", "available": false,
                "products": [
                    ["id": "member_month", "name": "月度会员", "amountFen": 1200, "currency": "CNY", "durationMonths": 1, "autoRenew": false],
                    ["id": "member_year", "name": "年度会员", "amountFen": 8800, "currency": "CNY", "durationMonths": 12, "autoRenew": false]
                ],
                "channels": [["provider": "alipay", "available": false], ["provider": "apple", "available": false, "status": "planned"]]
            ]])
        }
        if path == "/payments/membership", method == "GET" {
            return try json(["success": true, "data": [
                "tier": "free", "validUntil": NSNull(), "provider": NSNull(), "environment": "sandbox", "autoRenew": false
            ]])
        }

        if path.hasPrefix("/users/") {
            return try json(userResponse(path: path, method: method, payload: payload))
        }
        if path == "/products" || path.hasPrefix("/products/") {
            return try json(productResponse(path: path, method: method, payload: payload))
        }
        if path == "/plans" || path.hasPrefix("/plans/") {
            return try json(planResponse(path: path, method: method, payload: payload, queryItems: queryItems))
        }
        if path == "/skin-analysis" || path.hasPrefix("/skin-analysis/") {
            return try json(skinResponse(path: path, method: method, payload: payload))
        }
        if path == "/conflicts" || path.hasPrefix("/conflicts/") {
            return try json(conflictResponse(path: path, method: method, payload: payload))
        }

        throw APIError.serverError("Mock 接口尚未配置：\(method) \(path)")
    }

    private func userResponse(path: String, method: String, payload: [String: Any]) -> [String: Any] {
        switch (method, path) {
        case ("POST", "/users/register"):
            currentUser = compact([
                "_id": nextID("user"),
                "name": payload["name"] as? String ?? "新用户",
                "email": payload["email"],
                "phone": payload["phone"],
                "gender": payload["gender"]
            ])
            return authEnvelope(message: "Mock 注册成功")

        case ("POST", "/users/login"):
            if let email = payload["email"] as? String { currentUser["email"] = email }
            if let phone = payload["phone"] as? String { currentUser["phone"] = phone }
            return authEnvelope(message: "Mock 登录成功")

        case ("POST", "/users/password-reset/request"):
            return ["success": true, "message": "验证码已发送（Mock 验证码：123456）"]

        case ("POST", "/users/password-reset/confirm"):
            return ["success": true, "message": "密码已更新"]

        case ("GET", "/users/me"):
            return userEnvelope(message: "获取用户成功")

        case ("PATCH", "/users/update-username"):
            currentUser["name"] = payload["name"] as? String ?? currentUser["name"]
            return userEnvelope(message: "用户名已更新")

        case ("PATCH", "/users/update-gender"):
            currentUser["gender"] = payload["gender"] as? String ?? currentUser["gender"]
            return userEnvelope(message: "性别已更新")

        case ("PATCH", "/users/update-age"):
            currentUser["age"] = payload["age"] as? Int ?? currentUser["age"]
            return userEnvelope(message: "年龄已更新")

        case ("GET", "/users/stats"):
            return [
                "success": true,
                "data": ["stats": ["ideasCount": 6, "ideaCategories": [], "accountAge": 21]]
            ]

        case ("POST", "/users/logout"):
            return ["success": true, "message": "已退出 Mock 账号"]

        case ("DELETE", "/users/delete-account"):
            products.removeAll()
            plans.removeAll()
            analyses.removeAll()
            conflicts.removeAll()
            activePlanID = nil
            dailyRecords.removeAll()
            return ["success": true, "message": "Mock 账号已删除"]

        default:
            return failure("Mock 用户接口尚未配置：\(method) \(path)")
        }
    }

    private func productResponse(path: String, method: String, payload: [String: Any]) -> [String: Any] {
        if method == "GET", path == "/products" {
            return productsEnvelope(products)
        }
        if method == "POST", path == "/products" {
            var product = compact([
                "_id": nextID("product"),
                "name": payload["name"] as? String ?? "未命名产品",
                "description": payload["description"],
                "ingredients": [String](),
                "label": payload["label"],
                "openingDate": payload["openingDate"],
                "openingStatus": payload["openingStatus"]
            ])
            updateOpeningState(&product, payload: payload)
            products.insert(product, at: 0)
            return productEnvelope(product, message: "产品已创建")
        }
        if method == "GET", path.hasPrefix("/products/user/") {
            if let marker = path.range(of: "/label/") {
                let label = String(path[marker.upperBound...]).removingPercentEncoding ?? ""
                return productsEnvelope(products.filter { ($0["label"] as? String) == label })
            }
            return productsEnvelope(products)
        }

        let parts = path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return failure("无效的 Mock 产品路径") }
        let productID = parts[1]

        if method == "POST", parts.count == 3, parts[2] == "upload-image" {
            mutateProduct(productID) { product in
                product["imageUrl"] = "mock://product/\(productID)/image"
            }
            return [
                "success": true,
                "message": "图片上传成功",
                "data": ["imageUrl": "mock://product/\(productID)/image"]
            ]
        }
        if method == "POST", parts.count == 3, parts[2] == "extract-ingredients" {
            let ingredients = ["水", "甘油", "透明质酸钠", "泛醇", "神经酰胺NP"]
            mutateProduct(productID) { product in
                product["name"] = product["name"] as? String == "未命名产品" ? "AI 识别修护精华" : product["name"]
                product["ingredients"] = ingredients
                product["safetyScore"] = 91.0
                product["efficacyScore"] = 4.4
                product["overallRating"] = 4.6
            }
            return [
                "success": true,
                "message": "成分提取完成",
                "data": ["name": product(productID)?["name"] ?? "AI 识别产品", "ingredients": ingredients]
            ]
        }
        if method == "POST", parts.count == 3, parts[2] == "analyze-ingredients" {
            return ingredientEnvelope(productID: productID, includeProduct: false)
        }
        if method == "GET", parts.count == 3, parts[2] == "ingredient-analysis" {
            return ingredientEnvelope(productID: productID, includeProduct: true)
        }
        if method == "GET", parts.count == 2, let product = product(productID) {
            return productEnvelope(product)
        }
        if method == "PUT", parts.count == 2 {
            guard let productIndex = products.firstIndex(where: { identifier($0) == productID }) else { return failure("产品不存在") }
            updateOpeningState(&products[productIndex], payload: payload)
            mutateProduct(productID) { product in
                for key in ["name", "description", "label"] where payload[key] != nil {
                    product[key] = payload[key]
                }
            }
            guard let product = product(productID) else { return failure("产品不存在") }
            return productEnvelope(product, message: "产品已更新")
        }
        if method == "DELETE", parts.count == 2 {
            products.removeAll { identifier($0) == productID }
            return ["success": true, "message": "产品已删除"]
        }
        return failure("Mock 产品接口尚未配置：\(method) \(path)")
    }

    private func planResponse(path: String, method: String, payload: [String: Any], queryItems: [URLQueryItem]) throws -> [String: Any] {
        if path == "/plans/active" {
            if method == "PUT" {
                if payload["planId"] is NSNull {
                    activePlanID = nil
                } else if let id = payload["planId"] as? String, plans.contains(where: { identifier($0) == id }) {
                    activePlanID = id
                } else {
                    throw APIError.serverError("方案不存在")
                }
            }
            guard method == "GET" || method == "PUT" else { return failure("不支持的当前方案操作") }
            let active: Any = plans.first(where: { identifier($0) == activePlanID }) as Any? ?? NSNull()
            return ["success": true, "data": ["plan": active]]
        }
        if method == "GET", path == "/plans" {
            return ["success": true, "count": plans.count, "data": ["plans": plans]]
        }
        if method == "POST", path == "/plans" {
            var plan = Self.samplePlan(id: nextID("plan"))
            if let concerns = payload["skinConcerns"] as? [String], !concerns.isEmpty {
                plan["tags"] = concerns
            }
            if let requirements = payload["customRequirements"] as? String, !requirements.isEmpty {
                plan["notes"] = requirements
            }
            plans.insert(plan, at: 0)
            return planEnvelope(plan, message: "个性化方案已生成")
        }
        if method == "POST", path == "/plans/custom" {
            let plan = compact([
                "_id": nextID("plan"),
                "name": payload["name"] as? String ?? "我的护肤方案",
                "tags": payload["tags"] as? [String] ?? ["自定义"],
                "notes": payload["notes"],
                "morning": payload["morning"] as? [[String: Any]] ?? [],
                "evening": payload["evening"] as? [[String: Any]] ?? [],
                "recommendations": payload["recommendations"] as? [String] ?? [],
                "createdAt": isoDate(),
                "origin": "custom"
            ])
            plans.insert(plan, at: 0)
            return planEnvelope(plan, message: "自定义方案已创建")
        }

        let parts = path.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return failure("无效的 Mock 方案路径") }
        let planID = parts[1]

        if parts.count >= 3, parts[2] == "daily" {
            let query = queryItems.reduce(into: [String: String]()) { result, item in result[item.name] = item.value }
            return try dailyResponse(planID: planID, method: method, parts: parts, payload: payload, query: query)
        }

        if method == "PATCH", parts.count == 3, parts[2] == "step" {
            guard let index = plans.firstIndex(where: { identifier($0) == planID }) else {
                return failure("方案不存在")
            }
            let period = payload["period"] as? String ?? "morning"
            let step = payload["step"] as? Int ?? 1
            let completed = payload["completed"] as? Bool ?? false
            var routine = plans[index][period] as? [[String: Any]] ?? []
            if let itemIndex = routine.firstIndex(where: { ($0["step"] as? Int) == step }) {
                routine[itemIndex]["completed"] = completed
                routine[itemIndex]["done"] = completed
                plans[index][period] = routine
            }
            return planEnvelope(plans[index], message: "步骤状态已更新")
        }
        if method == "GET", parts.count == 2,
           let plan = plans.first(where: { identifier($0) == planID }) {
            return planEnvelope(plan)
        }
        if method == "DELETE", parts.count == 2 {
            plans.removeAll { identifier($0) == planID }
            if activePlanID == planID { activePlanID = nil }
            dailyRecords = dailyRecords.filter { !$0.key.hasPrefix(planID + "|") }
            return ["success": true, "message": "方案已删除"]
        }
        return failure("Mock 方案接口尚未配置：\(method) \(path)")
    }

    private func skinResponse(path: String, method: String, payload: [String: Any]) -> [String: Any] {
        if method == "POST", path == "/skin-analysis/analyze" {
            let analysis = Self.sampleAnalysis(id: nextID("analysis"))
            analyses.insert(analysis, at: 0)
            var data = analysis
            data["analysisId"] = data.removeValue(forKey: "_id")
            return ["success": true, "message": "Mock 肌肤分析完成", "data": data]
        }
        if method == "GET", path == "/skin-analysis" {
            return [
                "success": true,
                "data": [
                    "analyses": analyses,
                    "pagination": ["page": 1, "limit": 10, "total": analyses.count, "pages": 1]
                ]
            ]
        }
        if method == "GET", path == "/skin-analysis/latest" {
            guard let latest = analyses.first else {
                return ["success": false, "message": "暂无分析记录"]
            }
            return ["success": true, "data": ["analysis": latest]]
        }
        if method == "GET", path == "/skin-analysis/stats" {
            return [
                "success": true,
                "data": ["stats": [
                    "totalAnalyses": analyses.count,
                    "averageHealthScore": 82.0,
                    "latestSkinCondition": "状态稳定",
                    "latestAnalysisDate": isoDate()
                ]]
            ]
        }

        let parts = path.split(separator: "/").map(String.init)
        if method == "PATCH", parts.count == 3, parts[2] == "context" {
            guard let index = analyses.firstIndex(where: { identifier($0) == parts[1] }) else { return failure("分析记录不存在") }
            guard ["condition", "light", "feelings"].contains(where: { payload[$0] != nil }) else { return failure("请提供检测备注") }
            for key in ["condition", "light"] where payload[key] != nil {
                guard let text = payload[key] as? String, text.count <= 200 else { return failure("备注不能超过 200 字符") }
            }
            if let value = payload["feelings"] {
                guard let feelings = value as? [String], feelings.count <= 20,
                      Set(feelings).count == feelings.count,
                      feelings.allSatisfy({ !$0.isEmpty && $0.count <= 100 }) else { return failure("感受备注格式无效") }
            }
            var context = analyses[index]["context"] as? [String: Any] ?? [:]
            for key in ["condition", "light", "feelings"] where payload[key] != nil { context[key] = payload[key] }
            analyses[index]["context"] = context
            return ["success": true, "data": ["analysis": analyses[index]]]
        }
        guard parts.count == 2 else { return failure("无效的 Mock 肌肤分析路径") }
        let analysisID = parts[1]
        if method == "GET", let analysis = analyses.first(where: { identifier($0) == analysisID }) {
            return ["success": true, "data": ["analysis": analysis]]
        }
        if method == "DELETE" {
            analyses.removeAll { identifier($0) == analysisID }
            return ["success": true, "message": "分析记录已删除"]
        }
        return failure("Mock 肌肤分析接口尚未配置：\(method) \(path)")
    }

    private func conflictResponse(path: String, method: String, payload: [String: Any]) -> [String: Any] {
        if method == "POST", path == "/conflicts" {
            let selectedIDs = payload["productIds"] as? [String] ?? []
            let selectedProducts = selectedIDs.compactMap(product).map { product -> [String: Any] in
                compact([
                    "id": identifier(product),
                    "name": product["name"],
                    "description": product["description"],
                    "ingredients": product["ingredients"],
                    "label": product["label"],
                    "imageUrl": product["imageUrl"]
                ])
            }
            let pairs: [[String: Any]] = selectedIDs.enumerated().flatMap { index, id in
                selectedIDs.dropFirst(index + 1).map { other in
                    ["productIds": [id, other], "status": "caution",
                     "explanation": "这是产品搭配报告的界面测试数据，请分别确认耐受后再叠加。"]
                }
            }
            let result: [String: Any] = [
                "conflictId": nextID("conflict"), "reportVersion": 2,
                "riskScore": 2.5, "summary": "所选产品叠加需注意耐受情况。",
                "productPairs": pairs,
                "recommendations": ["advice": [
                    ["productIds": selectedIDs, "title": "逐步叠加", "detail": "先分别确认所选产品耐受，再少量叠加。"],
                    ["productIds": selectedIDs, "title": "观察使用反应", "detail": "出现不适时暂停叠加使用。"]
                ]],
                "products": selectedProducts
            ]
            var record = result
            record["_id"] = result["conflictId"]
            record["createdAt"] = isoDate()
            conflicts.insert(record, at: 0)
            return ["success": true, "message": "冲突分析完成", "data": result]
        }
        if method == "GET", path == "/conflicts" {
            return ["success": true, "count": conflicts.count, "data": ["conflicts": conflicts.map(conflictSnapshot)]]
        }
        let parts = path.split(separator: "/").map(String.init)
        guard parts.count == 2 else { return failure("无效的 Mock 冲突路径") }
        let conflictID = parts[1]
        if method == "GET", let conflict = conflicts.first(where: { identifier($0) == conflictID }) {
            return ["success": true, "data": ["conflict": conflictSnapshot(conflict)]]
        }
        if method == "DELETE" {
            conflicts.removeAll { identifier($0) == conflictID }
            return ["success": true, "message": "冲突记录已删除"]
        }
        return failure("Mock 冲突接口尚未配置：\(method) \(path)")
    }

    private func dailyResponse(planID: String, method: String, parts: [String], payload: [String: Any], query: [String: String]) throws -> [String: Any] {
        guard let plan = plans.first(where: { identifier($0) == planID }) else { throw APIError.serverError("方案不存在") }
        let isWrite = method == "PUT" && parts.count == 4 && parts[3] == "steps"
        guard isWrite || (method == "GET" && parts.count == 3) else { throw APIError.serverError("无效的每日步骤操作") }
        let date = isWrite ? payload["date"] as? String : query["date"]
        let zone = isWrite ? payload["timezone"] as? String : query["timezone"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date, let parsedDate = formatter.date(from: date), formatter.string(from: parsedDate) == date,
              let zone, let timeZone = TimeZone(identifier: zone) else {
            throw APIError.serverError("日期或时区无效")
        }
        let key = planID + "|" + date
        var daily = dailyRecords[key] ?? [
            "planId": planID, "date": date, "timezone": timeZone.identifier,
            "morning": dailySteps(plan["morning"]), "evening": dailySteps(plan["evening"])
        ]
        guard daily["timezone"] as? String == timeZone.identifier else {
            throw APIError.serverError("DAILY_TIMEZONE_CONFLICT：该日记录已使用其他时区")
        }
        if isWrite {
            guard let period = payload["period"] as? String, ["morning", "evening"].contains(period),
                  let step = payload["step"] as? Int, let completed = payload["completed"] as? Bool,
                  var steps = daily[period] as? [[String: Any]],
                  let index = steps.firstIndex(where: { $0["step"] as? Int == step }) else {
                throw APIError.serverError("护肤步骤无效")
            }
            steps[index]["completed"] = completed
            daily[period] = steps
        }
        let allSteps = (daily["morning"] as? [[String: Any]] ?? []) + (daily["evening"] as? [[String: Any]] ?? [])
        daily["totalCount"] = allSteps.count
        daily["completedCount"] = allSteps.filter { $0["completed"] as? Bool == true }.count
        if isWrite { dailyRecords[key] = daily }
        return ["success": true, "data": ["daily": daily]]
    }

    private func dailySteps(_ value: Any?) -> [[String: Any]] {
        (value as? [[String: Any]] ?? []).enumerated().map { index, step in
            ["step": step["step"] as? Int ?? index + 1, "completed": false]
        }
    }

    private func normalizedProduct(_ value: [String: Any]) -> [String: Any] {
        var normalized = value
        if normalized["openingStatus"] == nil {
            normalized["openingStatus"] = normalized["openingDate"] as? String == nil ? "unknown" : "opened"
        }
        return normalized
    }

    private func updateOpeningState(_ product: inout [String: Any], payload: [String: Any]) {
        if let status = payload["openingStatus"] as? String, ["unknown", "unopened", "opened"].contains(status) {
            product["openingStatus"] = status
            if status != "opened" {
                product.removeValue(forKey: "openingDate")
            } else if let date = payload["openingDate"] {
                if date is NSNull { product.removeValue(forKey: "openingDate") } else { product["openingDate"] = date }
            }
        } else if let date = payload["openingDate"] {
            if date is NSNull {
                product["openingStatus"] = "unknown"
                product.removeValue(forKey: "openingDate")
            } else {
                product["openingStatus"] = "opened"
                product["openingDate"] = date
            }
        }
    }

    private func conflictSnapshot(_ value: [String: Any]) -> [String: Any] {
        var result = value
        result["products"] = (value["products"] as? [[String: Any]] ?? []).map { snapshot in
            var item = snapshot
            // Names and ingredients remain the analysis-time snapshot; photos are live references.
            item.removeValue(forKey: "imageUrl")
            if let image = product(identifier(snapshot))?["imageUrl"] { item["imageUrl"] = image }
            return item
        }
        return result
    }

    private func authEnvelope(message: String) -> [String: Any] {
        [
            "success": true,
            "message": message,
            "token": "mock-token-\(UUID().uuidString)",
            "data": ["user": currentUser]
        ]
    }

    private func userEnvelope(message: String) -> [String: Any] {
        ["success": true, "message": message, "data": ["user": currentUser]]
    }

    private func productsEnvelope(_ value: [[String: Any]]) -> [String: Any] {
        ["success": true, "count": value.count, "total": value.count, "data": ["products": value.map(normalizedProduct)]]
    }

    private func productEnvelope(_ value: [String: Any], message: String? = nil) -> [String: Any] {
        compact(["success": true, "message": message, "data": ["product": normalizedProduct(value)]])
    }

    private func planEnvelope(_ value: [String: Any], message: String? = nil) -> [String: Any] {
        compact(["success": true, "message": message, "data": ["plan": value]])
    }

    private func ingredientEnvelope(productID: String, includeProduct: Bool) -> [String: Any] {
        let analysis: [String: Any] = [
            "safetyIndex": 91.0,
            "efficacyScore": 4.4,
            "activeIngredients": 4,
            "acneRisk": ["level": "低", "percentage": 12.0],
            "irritationRisk": ["level": "低", "percentage": 18.0],
            "allergyRisk": ["level": "低", "percentage": 9.0],
            "efficacyAnalysis": [
                "神经酰胺帮助修护肌肤屏障",
                "透明质酸钠提供即时保湿",
                "泛醇能够舒缓干燥不适"
            ],
            "potentialRisks": ["敏感肌首次使用建议先进行局部测试"],
            "recommendations": ["早晚洁面后使用", "白天注意配合防晒", "功效产品逐步建立耐受"],
            "overallRating": 4.6,
            "summary": "整体配方温和，兼顾保湿、舒缓与屏障修护。"
        ]
        if includeProduct {
            guard let existingProduct = product(productID) else { return failure("产品不存在") }
            return [
                "success": true,
                "data": [
                    "product": normalizedProduct(existingProduct),
                    "ingredientAnalysis": analysis
                ]
            ]
        }
        return [
            "success": true,
            "message": "成分分析完成",
            "data": ["ingredientAnalysis": analysis, "description": "Mock 成分分析结果"]
        ]
    }

    private func product(_ id: String) -> [String: Any]? {
        products.first { identifier($0) == id }
    }

    private func mutateProduct(_ id: String, mutation: (inout [String: Any]) -> Void) {
        guard let index = products.firstIndex(where: { identifier($0) == id }) else { return }
        mutation(&products[index])
    }

    private func nextID(_ prefix: String) -> String {
        sequence += 1
        return "mock-\(prefix)-\(sequence)"
    }

    private func decodedBody(_ data: Data?) -> [String: Any] {
        guard let data,
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else { return [:] }
        return dictionary
    }

    private func json(_ object: [String: Any]) throws -> Data {
        guard JSONSerialization.isValidJSONObject(object) else {
            throw APIError.serverError("Mock 数据不是有效 JSON")
        }
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private func failure(_ message: String) -> [String: Any] {
        ["success": false, "message": message]
    }

    private func identifier(_ object: [String: Any]) -> String {
        object["_id"] as? String ?? object["id"] as? String ?? ""
    }

    private func compact(_ dictionary: [String: Any?]) -> [String: Any] {
        dictionary.reduce(into: [:]) { result, item in
            if let value = item.value { result[item.key] = value }
        }
    }

    private func isoDate() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static func samplePlan(id: String) -> [String: Any] {
        [
            "_id": id,
            "name": "21 天屏障修护计划",
            "tags": ["补水", "修护", "敏感肌友好"],
            "creatorNote": "先稳定屏障，再逐步加入功效产品。",
            "notes": "模拟示例方案，可自由操作步骤状态。",
            "morning": [
                ["step": 1, "product": "温和洁面", "reason": "减少过度清洁", "done": true, "completed": true],
                ["step": 2, "product": "保湿精华", "reason": "补充水分", "done": false, "completed": false],
                ["step": 3, "product": "SPF50+ 防晒", "reason": "降低紫外线刺激", "done": false, "completed": false]
            ],
            "evening": [
                ["step": 1, "product": "温和洁面", "reason": "清洁日间残留", "done": false, "completed": false],
                ["step": 2, "product": "修护精华", "reason": "舒缓并补充水分", "done": false, "completed": false],
                ["step": 3, "product": "神经酰胺面霜", "reason": "夜间修护屏障", "done": false, "completed": false]
            ],
            "recommendations": [
                "连续使用 7 天后再观察变化",
                "功效型产品逐步建立耐受",
                "出现持续刺痛时暂停功效产品"
            ],
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "createdByName": "AISkin Mock",
            "origin": "ai"
        ]
    }

    private static func sampleAnalysis(id: String) -> [String: Any] {
        [
            "_id": id,
            "imageName": "模拟检测图片",
            "skinType": ["type": "混合偏干", "subtype": "轻度敏感", "basis": "固定演示样本"],
            "blackheads": ["exists": true, "severity": "少量", "distribution": ["鼻翼"], "description": "鼻翼有少量黑头"],
            "acne": ["exists": true, "count": "少量", "types": ["闭口"], "activity": "稳定", "distribution": ["下巴"], "severity": "轻度", "description": "下巴有少量闭口"],
            "pores": ["enlarged": true, "severity": "轻度", "distribution": ["鼻翼", "面颊内侧"], "description": "局部毛孔轻微明显"],
            "otherIssues": [
                "redness": ["exists": true, "severity": "轻度", "distribution": ["面颊"]],
                "hyperpigmentation": ["exists": false, "types": [], "distribution": [], "severity": "无", "description": "肤色整体均匀"],
                "fineLines": ["exists": false, "severity": "无", "distribution": [], "description": "未见明显细纹"],
                "sensitivity": ["exists": true, "signs": ["轻微泛红"], "severity": "轻度", "description": "建议温和修护"],
                "skinToneEvenness": ["score": 8, "description": "整体均匀，面颊略有泛红"]
            ],
            "overallAssessment": [
                "healthScore": 82.0,
                "summary": "模拟分析结果：整体状态稳定，当前重点是补水和屏障修护。",
                "recommendations": [
                    "当前为固定模拟数据，仅用于验证界面和交互",
                    "使用温和洁面并加强基础保湿",
                    "白天使用 SPF30+ 广谱防晒"
                ],
                "skinCondition": "状态稳定"
            ],
            "analysisConfig": ["model": "debug-mock-v1", "analysisDate": ISO8601DateFormatter().string(from: Date()), "processingTime": 1.0],
            "moisture": 58.0,
            "glossiness": 66.0,
            "elasticity": 78.0,
            "problemAreaScore": 24.0,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "updatedAt": ISO8601DateFormatter().string(from: Date())
        ]
    }
}
#endif
