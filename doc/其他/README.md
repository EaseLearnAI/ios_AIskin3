cd "/Users/terry/Downloads/aiskin 3/AISkin_backend-main" && npm start


cd "/Users/terry/Downloads/aiskin 3/aiskin-master" && chmod +x node_modules/.bin/vue-cli-service && npm run serve



# AIskin iOS App

这是一个基于Vue.js原型开发的iOS护肤助手应用，使用SwiftUI构建。

## 项目结构

```
AIskin/
├── Models/              # 数据模型
│   ├── User.swift       # 用户模型
│   ├── Product.swift    # 产品模型
│   ├── Conflict.swift   # 冲突检测模型
│   └── SkinPlan.swift   # 护肤计划模型
│
├── Services/            # 服务层
│   └── AuthService.swift # 认证服务
│
├── Components/          # 共享组件
│   ├── AppHeader.swift  # 应用头部
│   └── BottomNavigationView.swift # 底部导航
│
├── Views/               # 视图页面
│   ├── HomeView.swift           # 首页
│   ├── ProductView.swift         # 产品库
│   ├── IngredientView.swift      # 成分分析
│   ├── ConflictView.swift        # 冲突检测
│   ├── SkinStatusView.swift      # 肌肤检测
│   ├── SkincareSquareView.swift  # 护肤广场
│   ├── ProfileView.swift         # 个人资料
│   └── LoginView.swift           # 登录/注册
│
├── Extensions/          # 扩展
│   └── String+Identifiable.swift
│
├── ContentView.swift     # 主内容视图
└── AIskinApp.swift       # 应用入口
```

## 功能特性

### ✅ 已实现的功能

1. **用户认证**
   - 登录/注册界面
   - 状态管理

2. **首页**
   - 核心功能展示
   - 21天计划卡片
   - 每日护肤 routine

3. **产品管理**
   - 产品列表展示
   - 添加新产品（图片上传）
   - 产品详情查看
   - 成分分析

4. **冲突检测**
   - 多产品选择
   - 冲突分析展示
   - 安全组合推荐
   - 使用建议

5. **肌肤检测**
   - 照片拍摄/选择
   - AI分析结果展示
   - 健康评分

6. **护肤广场**
   - 方案浏览
   - 标签筛选
   - 我的方案管理

7. **个人资料**
   - 用户信息展示
   - 成就徽章
   - 设置菜单

## 设计风格

应用采用了与Vue原型一致的设计风格：
- 柔和的粉色/紫色渐变主题
- iOS系统设计规范
- 圆角卡片设计
- 流畅的动画过渡

## 技术栈

- **语言**: Swift
- **框架**: SwiftUI
- **架构**: MVVM
- **最低支持**: iOS 15.0+

## 运行说明

1. 打开 `AIskin.xcodeproj`
2. 选择目标设备或模拟器
3. 运行项目 (⌘R)

## 注意事项

- 当前使用模拟数据，实际API集成需要在Services层实现
- 图片上传功能需要实际的后端API支持
- 认证功能使用本地存储，生产环境需要JWT token验证

## 待完善功能

- [ ] 实际的API集成
- [ ] 图片缓存优化
- [ ] 数据持久化 (Core Data/SwiftData)
- [ ] 推送通知
- [ ] 更多动画效果

