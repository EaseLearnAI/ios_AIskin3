# AIskin 测试指南

## 📋 测试概述

本测试套件用于验证iOS应用与后端API的完整连接，确保所有功能正常工作。

## 🎯 测试目标

1. **验证前后端连接**: 确保iOS应用能够正确调用后端API
2. **功能完整性**: 验证所有API服务功能是否正常
3. **数据一致性**: 验证创建和获取的数据是否一致
4. **错误处理**: 验证错误处理机制是否正常工作

## 📁 测试文件结构

```
AIskinTests/
├── AIskinTests.swift                    # 测试套件入口
├── APIClientTests.swift                 # API客户端基础测试
├── UserApiServiceTests.swift            # 用户API服务测试
├── ProductApiServiceTests.swift         # 产品API服务测试
├── SkinAnalysisApiServiceTests.swift    # 皮肤分析API服务测试
├── PlanApiServiceTests.swift            # 护肤方案API服务测试
├── ConflictApiServiceTests.swift        # 冲突检测API服务测试
├── IngredientAnalysisApiServiceTests.swift # 成分分析API服务测试
├── AuthServiceTests.swift               # 认证服务测试
└── IntegrationTests.swift               # 综合集成测试
```

## 🚀 运行测试

### 方法1: 使用Xcode

1. 打开Xcode项目
2. 确保后端服务器运行在 `http://localhost:5000`
3. 选择测试目标: `AIskinTests`
4. 使用快捷键 `Cmd + U` 运行所有测试
5. 或点击测试按钮运行单个测试

### 方法2: 使用命令行

```bash
# 运行所有测试（自动检测可用模拟器）
./run_tests.sh

# 或手动指定可用的模拟器（根据你的系统，可能是 iPhone 17）
xcodebuild test -scheme AIskin -destination 'platform=iOS Simulator,name=iPhone 17'

# 运行特定测试类
xcodebuild test -scheme AIskin -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:AIskinTests/UserApiServiceTests

# 查看所有可用的模拟器
xcrun simctl list devices available | grep iPhone
```

## ✅ 测试前准备

### 1. 启动后端服务器

```bash
cd "/Users/terry/Downloads/aiskin 2/AISkin_backend-main"
npm start
```

确保看到以下输出：
```
Server running on port 5000
Connected to MongoDB
```

### 2. 检查MongoDB连接

确保MongoDB运行在本地：
```bash
mongod
```

### 3. 检查网络配置

确保iOS模拟器或设备能够访问 `http://localhost:5000`

**注意**: 如果使用真实iOS设备，需要将 `localhost` 改为你的Mac IP地址

## 📊 测试覆盖范围

### API服务测试

- ✅ **APIClient**: 基础网络请求、错误处理、URL构建
- ✅ **UserApiService**: 注册、登录、获取用户信息、更新用户信息
- ✅ **ProductApiService**: 创建、获取、更新、删除产品、提取成分
- ✅ **SkinAnalysisApiService**: 皮肤分析、获取历史、统计数据
- ✅ **PlanApiService**: 创建方案、获取方案、更新步骤状态
- ✅ **ConflictApiService**: 冲突分析、获取冲突记录
- ✅ **IngredientAnalysisApiService**: 成分分析、获取分析结果

### 集成测试

- ✅ **完整用户流程**: 注册 → 登录 → 使用功能 → 登出
- ✅ **API端点可访问性**: 验证所有API端点是否可访问
- ✅ **数据一致性**: 验证创建和获取的数据是否一致
- ✅ **错误处理**: 验证错误处理机制

## 🔍 测试结果解读

### 成功标志

- ✅ 所有测试通过
- ✅ 控制台显示详细的API调用日志
- ✅ 数据正确创建和获取

### 失败情况

#### 1. 网络连接失败
```
❌ 无法连接到服务器: Network error
```
**解决方案**: 
- 检查后端服务器是否运行
- 检查网络配置

#### 2. 认证失败
```
❌ 未授权 (401)
```
**解决方案**: 
- 检查token是否正确保存
- 检查后端认证中间件

#### 3. 数据解析错误
```
❌ 数据解析错误: DecodingError
```
**解决方案**: 
- 检查后端返回的数据格式
- 检查Swift模型定义是否匹配

## 📝 测试日志

所有测试都会在控制台输出详细的日志：

```
🎯 用户注册API调用开始
📊 注册数据:
   - 姓名: 测试用户_1234567890
   - 邮箱: test_1234567890@example.com
📡 API请求: POST /users/register
🔗 请求URL: http://localhost:5000/api/users/register
⏱️ 请求耗时: 0.52秒
📊 HTTP状态码: 201
✅ 注册成功
```

## 🐛 调试技巧

### 1. 使用断点

在测试代码中设置断点，可以：
- 检查变量值
- 单步执行代码
- 查看调用栈

### 2. 查看详细日志

所有API调用都会打印详细日志，包括：
- 请求URL和方法
- 请求参数
- 响应状态码
- 响应数据预览
- 执行时间

### 3. 检查网络请求

使用Xcode的网络调试工具查看实际的HTTP请求和响应。

### 4. 验证后端日志

检查后端服务器的控制台输出，确认请求是否到达。

## ⚠️ 注意事项

1. **测试数据清理**: 每个测试都会创建独立的测试数据，使用时间戳确保唯一性
2. **异步测试**: 所有API调用都是异步的，使用 `XCTestExpectation` 等待完成
3. **超时设置**: 某些测试（如AI分析）可能需要较长时间，超时时间已相应调整
4. **图片上传**: 皮肤分析测试需要真实的图片，使用模拟图片可能无法完成完整分析
5. **依赖顺序**: 某些测试依赖于之前的测试（如需要先创建产品），测试顺序很重要

## 🔄 持续集成

建议在CI/CD流程中运行这些测试：

```yaml
# GitHub Actions 示例
- name: Run Tests
  run: |
    xcodebuild test \
      -scheme AIskin \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -only-testing:AIskinTests
```

## 📚 参考文档

- [XCTest文档](https://developer.apple.com/documentation/xctest)
- [Swift Testing文档](https://developer.apple.com/documentation/testing)
- [后端API文档](../aiskin%202/AISkin_backend-main/COMPLETE_API_DOCUMENTATION_CN.md)

## 🆘 常见问题

### Q: 测试失败，提示无法连接服务器
**A**: 确保后端服务器正在运行，并且可以访问 `http://localhost:5000`

### Q: 测试时出现认证错误
**A**: 检查测试中是否正确设置了token，确保 `UserDefaults.standard.set(token, forKey: "authToken")`

### Q: 某些测试需要真实数据
**A**: 是的，比如皮肤分析需要真实图片，成分分析需要产品有成分信息。这些测试可能会跳过或标记为警告

### Q: 如何运行单个测试
**A**: 在Xcode中，点击测试方法旁边的菱形图标，或使用 `Cmd + U` 后选择特定测试

## 📈 测试统计

运行测试后，Xcode会显示：
- 通过的测试数量
- 失败的测试数量
- 执行时间
- 代码覆盖率（如果启用）

## 🎉 测试通过标准

所有测试通过的标准：
1. ✅ 所有API服务测试通过
2. ✅ 集成测试通过
3. ✅ 无网络错误
4. ✅ 数据一致性验证通过
5. ✅ 错误处理测试通过

---

**最后更新**: 2025-01-27
**维护者**: AI Assistant

