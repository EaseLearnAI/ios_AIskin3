# AIskin 架构设计与迁移基线

> - 文档状态：架构重构已落地；下文保留 T0 基线作为迁移审计记录
> - 基线日期：2026-08-25
> - 基线分支：`codex/architecture-baseline`
> - 基线提交：`fb5f2f1f0342275f03559bb83f569748cd10f6b8`（与当时的 `main`、`origin/main` 一致）
> - 工程：`AIskin.xcodeproj` / Scheme：`AIskin` / App Bundle ID：`personal.AIskin`

## 0. 当前已落地架构（2026-08-25）

```text
AIskin/
├── App/                  # AppRootView、四个 Tab、类型化路由、依赖组合根
├── DesignSystem/         # 颜色/字体/间距等 Token 与通用 UI 状态组件
├── Core/
│   ├── Networking/       # APIRequest、HTTPClient、错误映射、multipart
│   └── Authentication/   # SessionStore、CredentialStore、Keychain 迁移
├── Features/             # Home/Plans、Products、SkinAnalysis、Profile 的 Store 与适配层
├── Models/               # 后端数据模型（API 合约保持不变）
├── Services/             # 旧 Service 兼容层，供尚未移除的调用方平滑过渡
├── Views/                # 现有页面外观与交互入口
└── Components/           # 现有业务组件；跨 Feature 的视觉基础逐步由 DesignSystem 接管
```

当前依赖方向固定为：

```text
App → Features → Core
App → DesignSystem
Features → DesignSystem / Core / Models
Core 与 DesignSystem 不依赖任何 Feature
```

落地规则：

- 四个一级入口统一由原生 `TabView` 和每 Tab 独立 `NavigationStack` 管理，跨 Tab 跳转只通过 `AppRouter`。
- `AppDependencies` 是唯一依赖组合根；页面使用注入的 Store/Client，不自行创建新全局状态。
- 登录态只有一个 `SessionStore`；Token 由 `CredentialStore` 存入 Keychain，并兼容迁移旧 UserDefaults 数据。
- 网络请求统一经 `HTTPClient + APIRequest`；旧 Service 保留为兼容边界，后端 URL、路径与 JSON 合约不变。
- Home 与个性化方案共享 `PlanStore`；产品、成分、冲突、肌肤检测和 Profile 均有独立 Store/流程状态。
- 只有无业务语义的视觉基础（颜色、间距、Card 外壳、Loading/Empty/Error）进入 DesignSystem；业务组件留在对应 Feature。
- 原工作区的 LookinServer 依赖、调试标记和 Xcode 工程修改全部保留。

新增 Feature 时，在 `Features/<FeatureName>/` 内优先放置 `Store`、Client 协议/适配器和 Feature 私有组件；由 `AppDependencies` 注入依赖，并由 `AppRouter` 暴露跨 Feature 入口。禁止让 DesignSystem/Core 反向引用 Feature，也禁止页面新增 Service singleton 直连。

## 1. 目的与边界

本文为渐进式架构迁移建立可复查的起点，回答以下问题：

- 当前代码放在哪里，应用如何启动，四个一级入口如何切换。
- 页面、模态窗口、API 服务与跨页面状态如何串联。
- 哪些文件过大，哪些组件语义重复，哪些文件当前没有调用入口。
- `.shared` 单例在哪里定义、在哪里被页面和服务直接访问。
- 目标目录、依赖方向、组件提升规则，以及 T1–T10 的严格任务边界。
- 迁移前构建和测试的真实结果，以及后续每个 MR 必须复验的清单。

T0 明确不做：不修改功能、页面结构、导航行为、API 路径、模型、测试源码或 Xcode 工程配置；不删除任何候选死代码；不处理原工作区未提交的 LookinServer、Xcode 工程或 UI 修改。

## 2. 当前工程基线

### 2.1 当前目录

```text
ios_aiskin/
├── AIskin.xcodeproj/
├── AIskin/
│   ├── AIskinApp.swift
│   ├── ContentView.swift
│   ├── Item.swift
│   ├── Assets.xcassets/
│   ├── Extensions/
│   │   └── String+Identifiable.swift
│   ├── Models/
│   │   ├── Conflict.swift
│   │   ├── Product.swift
│   │   ├── SkinAnalysis.swift
│   │   ├── SkinPlan.swift
│   │   └── User.swift
│   ├── Services/
│   │   ├── APIClient.swift
│   │   ├── AuthService.swift
│   │   ├── UserApiService.swift
│   │   ├── ProductApiService.swift
│   │   ├── IngredientAnalysisApiService.swift
│   │   ├── ConflictApiService.swift
│   │   ├── SkinAnalysisApiService.swift
│   │   └── PlanApiService.swift
│   ├── Views/
│   │   ├── LoginView.swift / RegisterView.swift
│   │   ├── HomeView.swift / ProductView.swift
│   │   ├── IngredientView.swift / ConflictView.swift
│   │   ├── SkinStatusView.swift / ProfileView.swift
│   │   └── SkincareSquareView.swift
│   └── Components/
│       ├── AppHeader.swift / BottomNavigationView.swift
│       ├── login/ / home/ / product/ / ingredient/
│       ├── conflict/ / skin-analysis/ / profile/
├── AIskinTests/
├── AIskinUITests/
└── doc/
```

当前组织方式是“全局技术分类”：页面放 `Views`，业务子视图放全局 `Components`，模型放 `Models`，服务放 `Services`。一个 Feature 的 UI、状态、模型和网络调用因此分散在多个顶层目录。

工程使用 `PBXFileSystemSynchronizedRootGroup`，目录内 Swift 文件会随同步组参与构建。Generic Simulator Debug 构建日志确认 `Item.swift`、`SkincareSquareView.swift` 和其他候选未引用文件仍会被编译；“未引用”不等同于“未加入 Target”。

### 2.2 构建设置快照

| 项目 | 当前值 | 说明 |
|---|---:|---|
| App deployment target | iOS 17.6 | `AIskin` Debug/Release |
| Unit Test deployment target | iOS 26.0 | 与 App 不一致，留给 T10 统一 |
| Swift language version | Swift 5 | 工程同时启用了 Xcode 的 upcoming features |
| Generic Simulator Debug | 通过 | 见第 10 节 |
| Unit/UI Test build | 失败 | 既有测试源码无法编译，见第 10 节 |

## 3. 应用入口与当前导航

### 3.1 启动与认证门

当前启动顺序：

```text
AIskinApp
  └─ @StateObject AuthService.shared
      └─ ContentView（再次持有 AuthService.shared）
          ├─ isAuthenticated == false → NavigationView → LoginView
          └─ isAuthenticated == true  → MainTabView
```

`AuthService` 初始化时从 `UserDefaults` 读取 `authToken` 和 `currentUser`。登录、注册成功后写入；退出和注销后清除，`@Published isAuthenticated` 驱动 `ContentView` 在登录页与主界面之间切换。

当前 `AIskinApp` 和 `ContentView` 都声明了 `@StateObject`，但二者引用同一个 `AuthService.shared`。登录、注册、Profile 等页面再通过 `environmentObject` 获取它，Preview 中又多次直接注入单例。

### 3.2 四个一级 Tab

当前并非原生 `TabView`。`MainTabView` 使用 `selectedTab: Int` 做 `switch`，并在底部叠加自定义 `BottomNavigationView`。

| 整数 | 底部名称 | 一级页面 | 页面入口与主要行为 |
|---:|---|---|---|
| 0 | 首页 | `HomeView` | 加载最新方案；展示核心功能、21 天计划占位入口和每日方案 |
| 1 | 产品分析 | `ProductView` | 产品列表、添加/上传、成分分析入口、冲突选择与冲突结果 |
| 2 | 肌肤检测 | `SkinStatusView` | 相册/相机、分析进度、分析结果、历史记录 |
| 3 | 我的 | `ProfileView` | 用户资料、成就、资料编辑、反馈、退出和注销 |

Tab 切换不会保存独立导航栈。`switch` 替换整个一级页面，页面自己的 `@State` 是否保留依赖 SwiftUI 当前身份计算，不是显式的每 Tab 路由状态。

### 3.3 非一级页面与跳转入口

| 来源 | 触发 | 目标 | 当前实现 |
|---|---|---|---|
| 未登录入口 | 注册 | `RegisterView` | `NavigationLink` |
| 登录表单 | 忘记密码 | `ForgotPasswordView` | `NavigationLink`，当前为表单内类型 |
| 注册表单 | 返回登录 | `LoginView` | `NavigationLink` |
| Home 核心功能 01 | 产品分析 | Tab 1 | 写 `selectedTab = 1` |
| Home 核心功能 02 | 冲突检测 | Tab 1 冲突选择态 | 先写 `shouldEnableConflictMode = true`，再写 `selectedTab = 1` |
| Home 核心功能 03 | 肌肤检测 | Tab 2 | 写 `selectedTab = 2` |
| Home 核心功能 04 | 个性化方案 | `PersonalizedRoutineModalView` | `.sheet` |
| Home | 21 天计划 | 占位 `Text("21天计划页面")` | `NavigationLink` |
| Products | 选择产品 | `IngredientView` | `.sheet` 内嵌 `NavigationView` |
| Products | 选择至少两个产品并分析 | `ConflictView` | `.sheet` |
| Skin Analysis | 历史项 | 当前页结果态 | 直接改 `analysisResult` 与 `showResults` |
| Profile | 设置项 | 用户名、性别、反馈 Sheet | 多个 Bool 控制 `.sheet` |

## 4. 当前模态窗口清单

这里同时记录系统 Sheet、Alert 和模拟模态的 Overlay。后续迁移时必须保持触发条件、关闭路径和副作用一致。

| 所属页面/组件 | 状态 | 展示内容 | 形式 | 关闭/后续行为 |
|---|---|---|---|---|
| `CoreFeaturesView` | `showPersonalizedRoutineModal` | `PersonalizedRoutineModalView` | `.sheet` | 保存后发 `PlanSaved` 通知并 dismiss |
| `ProductView` | `showAddModal` | `AddProductModal` | 自定义 `.overlay` | 成功后刷新列表，可继续进入成分页 |
| `ProductView` | `showIngredientViewForProduct != nil` | `IngredientView` | `.sheet` | 关闭后清 ID 并刷新产品列表 |
| `ProductView` | `showConflictView` | `ConflictView` | `.sheet` | 关闭后清冲突模式、选择和产品 ID |
| `IngredientView` | `showTagModal` | `TagSelectorModal` | `.sheet` | 保存后延迟 dismiss 成分页 |
| `IngredientView` | `showDeleteModal` | 删除确认 | `.alert` | 确认后删除产品 |
| `SkinStatusView` | `showPhotoPicker` | 相册 `SkinAnalysisImagePicker` | `.sheet` | 选图后触发分析 |
| `SkinStatusView` | `showCamera` | 相机 `SkinAnalysisImagePicker` | `.sheet` | 拍照后触发分析 |
| `SkinStatusView` | `isAnalyzing` | `AnalyzingModal` | `.overlay` | 成功/失败后状态切换 |
| `SkinStatusView` | `showHistoryModal` | `HistoryModal` | `.overlay` | 选择历史后切结果态 |
| `SkinStatusView` | `errorMessage != nil` | `ErrorToast` | `.overlay` | 用户关闭或后续清错 |
| `ProfileView` | `showUsernameModal` | `UsernameEditModal` | `.sheet` | 更新共享 Auth 用户并 dismiss |
| `ProfileView` | `showGenderModal` | `GenderEditModal` | `.sheet` | 更新共享 Auth 用户并 dismiss |
| `ProfileView` | `showFeedbackModal` | `FeedbackModal` | `.sheet` | 当前为本地表单 |
| `ProfileView` | `showLogoutModal` | 退出确认 | `.alert` | 调用 logout，认证门返回登录页 |
| `ProfileView` | `showDeleteAccountModal` | 注销确认 | `.alert` | 调用删除账户，认证门返回登录页 |
| `ProfileView` | `showDeleteAccountError` | 注销失败 | `.alert` | 仅关闭错误提示 |
| `ImageUploader` | `showImagePicker` | `ImagePicker` | `.sheet` | 回填产品图片 |
| `SkincareSquareView` | `showMyPlans` | `MyPlansModal` | `.sheet` | 当前根页面无调用入口 |

## 5. API 服务基线

### 5.1 网络入口

`APIClient.shared` 固定使用 `https://www.lunzo.site/api`，内部各自实现 `get`、`post`、`upload`、`put`、`patch`、`delete`。每种方法重复拼 URL、附加认证头、发送、打印、检查响应并解码；需要认证时由网络层反向读取 `AuthService.shared.getToken()`。

### 5.2 服务与端点

| 服务 | 当前职责 | 端点集合 |
|---|---|---|
| `UserApiService` | 注册、登录、当前用户、资料、统计、退出、注销 | `/users/register`、`/users/login`、`/users/me`、`/users/update-username`、`/users/update-gender`、`/users/update-age`、`/users/stats`、`/users/logout`、`/users/delete-account` |
| `AuthService` | 认证状态、token/用户持久化、调用 User API | 无独立端点；依赖 `UserApiService.shared` |
| `ProductApiService` | 产品 CRUD、图片上传、成分提取、用户/标签筛选 | `/products`、`/products/{id}`、`/products/{id}/upload-image`、`/products/{id}/extract-ingredients`、`/products/user/{userId}`、`/products/user/{userId}/label/{label}` |
| `IngredientAnalysisApiService` | 发起/读取成分分析 | `/products/{id}/analyze-ingredients`、`/products/{id}/ingredient-analysis` |
| `ConflictApiService` | 发起冲突分析、列表、详情、删除 | `/conflicts`、`/conflicts/{id}` |
| `SkinAnalysisApiService` | 上传分析、历史、详情、最新、统计、删除；兼做 API→UI 模型转换 | `/skin-analysis/analyze`、`/skin-analysis`、`/skin-analysis/{id}`、`/skin-analysis/latest`、`/skin-analysis/stats` |
| `PlanApiService` | 生成、读取、更新步骤、自定义方案、删除 | `/plans`、`/plans/{id}`、`/plans/{id}/step`、`/plans/custom` |

迁移硬约束：以上 base URL 语义、HTTP 方法、路径、请求字段、响应字段与错误语义不得因架构调整而改变。T3 只能添加统一网络层和兼容适配，不得批量改页面；实际调用方迁移由对应后续任务完成。

## 6. 跨页面与跨层状态流

### 6.1 Session/用户状态

```text
Login/Register View
  → AuthService.shared
    → UserApiService.shared
      → APIClient.shared
  → UserDefaults(authToken/currentUser)
  → @Published isAuthenticated/currentUser
  → ContentView 切换 Root；Profile 读取同一 currentUser
```

问题基线：全局单例同时承担依赖组合、业务状态和持久化；`APIClient` 反向依赖 `AuthService`；Token 位于 `UserDefaults`。目标由 T4 的 `AppDependencies + SessionStore + CredentialStore` 处理。

### 6.2 首页跨 Tab

```text
CoreFeaturesView
  ├─ 产品分析：selectedTab = 1
  ├─ 肌肤检测：selectedTab = 2
  └─ 冲突检测：shouldEnableConflictMode = true → selectedTab = 1
       → MainTabView 创建 ProductView(initialConflictMode: true)
       → ProductView.onAppear 打开 conflictMode
       → MainTabView 延迟 0.1 秒清 shouldEnableConflictMode
```

这是跨页面 Bool 握手，不是类型化路由。T2 负责替换为 `AppRouter` 行为；T6 负责冲突 Feature 内部状态，不得在 T2 提前拆 Store。

### 6.3 方案保存后刷新首页

```text
PersonalizedRoutineModalView 保存方案
  → NotificationCenter.post("PlanSaved", planId)
  → HomeView.onReceive
  → PlanApiService.shared.getUserPlans/getPlan
  → 更新 HomeView 本地 morning/evening/recommendations
```

通知名是字符串，发送方和接收方无类型约束。T8 由共享 `PlanStore` 替换；T0–T7 不删除此通知。

### 6.4 产品、成分与冲突

`ProductView` 同时持有产品列表、分类、冲突选择、添加产品四步进度、成分 Sheet 和冲突 Sheet 状态，并直接访问 Auth/Product/Ingredient Service 单例。`IngredientView` 再直接读取/更新/删除产品并发起成分分析；`ConflictView` 自己发起冲突 API。T5 只迁移产品库并保留两个分析入口；T6 才迁移成分和冲突内部实现。

### 6.5 肌肤检测

`SkinStatusView` 用多个 Bool 和可选值表达欢迎、选图、分析中、成功、错误和历史状态；它直接调用 `SkinAnalysisApiService.shared`，并由 Service 负责把 API 模型转换成页面 `AnalysisResult`。T7 收敛为可测试的流程状态，不改变相机/相册权限与分析 API。

## 7. 迁移风险清单

### 7.1 超大文件

本基线将 **400 行及以上** 标记为超大文件；它只是迁移排序信号，不代表 T0 可直接拆分。

| 行数 | 文件 | 当前混合职责 | 归属任务 |
|---:|---|---|---|
| 782 | `Views/ConflictView.swift` | 请求、加载/错误、Tab、结果 UI、路由关闭 | T6 |
| 768 | `Views/ProductView.swift` | 列表、添加流水线、成分/冲突路由、API | T5/T6 |
| 675 | `Components/home/CoreFeaturesView.swift` | 首页入口、方案表单、肌肤数据、方案 API | T8 |
| 632 | `Services/APIClient.swift` | 六种请求的重复构造、认证、日志、解码 | T3 |
| 557 | `Views/SkinStatusView.swift` | 选择图片、计时进度、API、历史、全部状态 | T7 |
| 498 | `Components/conflict/ConflictAnalysis.swift` | 另一套冲突结果组件树，当前无根调用 | T6/T10 |
| 484 | `Components/login/RegisterForm.swift` | 表单 UI、校验、异步认证、条款状态 | T4 |
| 469 | `Views/IngredientView.swift` | 产品/分析加载、保存标签、删除、路由 | T6 |
| 453 | `skin-analysis/.../SkinStatusOverview.swift` | 多种指标 UI 与页面内数据结构 | T7 |

### 7.2 语义重复组件

下表标记“需要判断是否统一”的组件族，不表示所有组件都应做成一个万能组件。

| 组件族 | 当前实现举例 | 迁移判断 |
|---|---|---|
| 一级 Header | `AppHeader`、`SkinAnalysisHeader`、`ConflictView.HeaderView`、`ConflictModeHeader` | 一级标题/按钮由 T2 原生 `navigationTitle/toolbar` 接管；业务态 Header 留在 Feature |
| Loading/进度 | `LoadingView`、`LoadingStateView`、`AnalyzingModal`、添加产品 Progress UI | 通用旋转/占位可进 DesignSystem；有业务步骤含义的留在 Feature |
| Error/重试/Toast | `ErrorView`、`ErrorStateView`、`PersonalizedErrorStateView`、`ErrorToast`、登录注册内联错误 | 统一视觉 Token 与通用错误/重试壳；字段校验和业务 Toast 留在 Feature |
| Tag/Chip | `TagView`、`ProductTag`、`ProductTagView`、`CategoryTagButton`、`TagButton`、`ConcernButton` | 只在交互语义一致且跨至少两个 Feature 时提升 |
| Card | `FeatureCardView`、`ProductCard`、`AnalysisCard`、`AchievementCard`、多个分析 Card | 提升 Card 容器样式和 Token，不提升业务内容模型 |
| 图片选择器 | `ImagePicker`、`SkinAnalysisImagePicker` | 系统适配可复用；相机权限和 Feature 流程仍各自管理 |
| Sheet 关闭按钮/容器 | 多个 Sheet 自己创建 `NavigationView`、标题和关闭按钮 | 可统一容器；目的地和保存副作用留在 Feature |

### 7.3 未引用文件/类型候选

以下结论来自全仓 Swift 标识符搜索，并由 Generic build 证明文件仍在 Target。T0 只记录，不删除；T10 删除前必须再次用编译、搜索和核心流程回归确认。

| 候选 | 证据 | 置信度/处理 |
|---|---|---|
| `AIskin/Item.swift` | `Item` 仅在自身声明出现；是 SwiftData 模板模型 | 高；T10 候选删除 |
| `Views/SkincareSquareView.swift` | 根类型只在自身声明出现，四 Tab 和 NavigationLink 均无入口 | 高；T10 候选删除 |
| `Components/conflict/ConflictAnalysis.swift` | 根类型 `ConflictAnalysis` 只在自身声明出现；实际冲突结果由 `ConflictView` 内部组件展示 | 高；T6 决定是否迁移有效片段，T10 清理 |
| `SearchBar`（位于 `AppHeader.swift`） | 仅声明，无调用；同文件 `AppHeader` 被四处使用 | 高；随 T2/T10 清理，不能删除整个文件直到 Header 迁移完成 |
| `Extensions/String+Identifiable.swift` | 当前无 `.sheet(item:)`，未发现显式依赖 | 中；全局一致性扩展可能产生隐式影响，T10 再确认 |
| `Components/login/aiskin 2.code-workspace` | 非 iOS 源码，位于业务组件目录 | 高；不影响编译，T10 决定是否移出仓库 |

### 7.4 `.shared` 基线

共有 8 个服务单例定义：

- `APIClient.shared`
- `AuthService.shared`
- `UserApiService.shared`
- `ProductApiService.shared`
- `IngredientAnalysisApiService.shared`
- `ConflictApiService.shared`
- `SkinAnalysisApiService.shared`
- `PlanApiService.shared`

全仓文本搜索发现 44 个“服务 `.shared`”引用，其中 `ConflictView` 有 2 个仅用于日志字符串，故可执行服务单例访问为 42 处；另有 1 处系统 `UIApplication.shared`，不属于依赖注入迁移目标。

| 单例 | 文本引用数 | 主要位置 |
|---|---:|---|
| `AuthService.shared` | 13 | `AIskinApp`、`ContentView`、`APIClient` 六种请求、`ProductView`、登录/注册 Preview |
| `ProductApiService.shared` | 8 | `ProductView`、`IngredientView` |
| `SkinAnalysisApiService.shared` | 6 | `SkinStatusView`、`CoreFeaturesView` |
| `APIClient.shared` | 6 | User/Product/Ingredient/Conflict/Skin/Plan API Service |
| `PlanApiService.shared` | 4 | `HomeView`、`CoreFeaturesView`、`DailyRoutineView` |
| `IngredientAnalysisApiService.shared` | 3 | `ProductView`、`IngredientView` |
| `ConflictApiService.shared` | 3 | `ConflictView`（1 次调用、2 次日志文本） |
| `UserApiService.shared` | 1 | `AuthService` |

按文件看，直接访问最密集的是 `ProductView`（7）、`SkinStatusView`（6）、`APIClient`（6）、`IngredientView`（5）、`ConflictView`（3）。迁移后允许 `AppDependencies` 在组合根创建正式实现，但 Feature View/Store 和新网络层不得直接读取业务单例。

## 8. 目标架构

### 8.1 目标目录

```text
AIskin/
├── App/
│   ├── AIskinApp.swift
│   ├── AppRootView.swift
│   ├── AppTab.swift
│   ├── AppRouter.swift
│   └── AppDependencies.swift
├── Core/
│   ├── Networking/
│   │   ├── HTTPClient.swift
│   │   ├── APIRequest.swift
│   │   ├── APIError.swift
│   │   └── MultipartBody.swift
│   ├── Authentication/
│   │   ├── SessionStore.swift
│   │   ├── CredentialStore.swift
│   │   └── KeychainCredentialStore.swift
│   ├── State/
│   │   └── Loadable.swift
│   └── Support/
│       ├── AppLogger.swift
│       └── Extensions/
├── DesignSystem/
│   ├── Foundation/
│   │   ├── AISkinTheme.swift
│   │   ├── AISkinColors.swift
│   │   ├── AISkinTypography.swift
│   │   ├── AISkinSpacing.swift
│   │   └── AISkinShape.swift
│   └── Components/
│       ├── AISkinCard.swift
│       ├── AISkinButtonStyles.swift
│       ├── AISkinIconButton.swift
│       ├── AsyncStateView.swift
│       ├── EmptyStateView.swift
│       └── ErrorStateView.swift
├── Features/
│   ├── Auth/{Models,Data,Views}/ + AuthStore.swift
│   ├── Home/ + HomeStore.swift
│   ├── Products/
│   │   ├── Models/ / Data/ / Views/Components/
│   │   ├── ProductsStore.swift
│   │   ├── IngredientAnalysis/
│   │   └── ConflictAnalysis/
│   ├── SkinAnalysis/{Models,Data,Views/Components}/ + SkinAnalysisStore.swift
│   ├── Plans/{Models,Data,Views/Components}/ + PlanStore.swift
│   └── Profile/Views/Components/ + ProfileStore.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.xcstrings
```

当前规模采用“模块化单体 + Feature-first”，暂不拆本地 Swift Package。只有出现多个 App Target、独立团队维护或明确构建性能收益时，才评估把 Core Networking/DesignSystem 拆包。

### 8.2 依赖方向

```text
App（组合根、Root、Router）
  ↓
Features（Screen、Store、Feature Client 协议/模型）
  ├────────→ Core（网络、认证持久化、通用状态、系统适配）
  └────────→ DesignSystem（Token 与跨 Feature 视觉组件）

Core ─X→ Features
DesignSystem ─X→ Features
Feature A ─X→ Feature B 的 View/Store
```

规则：

1. `AppDependencies` 是正式运行、Preview 和测试依赖的唯一组合根。
2. 跨 Feature 跳转交给 `AppRouter`；Feature 不持有另一个 Feature 的 View 或 Store。
3. Store 通过初始化参数接收协议；View 不直接访问业务 `.shared`。
4. Core 不导入 SwiftUI 页面；DesignSystem 不包含 API、路由或业务模型。
5. Feature 可拥有自己的 Client 协议和业务模型；共用传输/认证能力由 Core 提供。
6. 迁移期间旧 Service 通过兼容适配层继续工作，只有调用方全部迁移后才删除。

### 8.3 状态与导航目标

- `AppTab` 替代整数 Tab，仍保留：首页、产品分析、肌肤检测、我的。
- `AppRouter` 持有当前 Tab、每个 Tab 独立的 `NavigationStack` 路径和跨 Tab 跳转。
- `SessionStore` 是唯一认证状态与当前用户来源。
- `PlanStore` 被 Home 与个性化方案共享，替换 `PlanSaved` 字符串通知。
- Feature 根持有 Feature Store；全局环境只放真正的 App 级状态。
- 网络加载统一表达为 `idle/loading/loaded/failed`；View 只保留输入焦点、展开、临时选择等纯 UI 状态。
- 多个互斥 Bool Sheet 收敛为 `SheetDestination?` 或类型化路由，但每个 Feature 的迁移任务负责自己的目的地。

### 8.4 组件提升规则

按以下顺序决策：

1. **系统原生优先**：优先 `TabView`、`NavigationStack`、`toolbar`、`sheet(item:)`、`alert`，不重新包装无额外语义的系统能力。
2. **跨 Feature 且语义一致**：至少被两个 Feature 实际使用，输入、行为、可访问性和视觉语义一致，才提升到 `DesignSystem/Components`。
3. **仅视觉参数重复**：先提升颜色、字体、间距、圆角、阴影、动画 Token，不急于合并业务 View。
4. **单 Feature 业务组件**：留在 `Features/<Feature>/Views/Components`，即使它由多个小 View 组成。
5. **系统/基础设施适配**：图片选择、Keychain、日志等不属于 DesignSystem，放 Core。
6. **禁止过度抽象**：不创建 `GenericCard`、`AnyView` 页面工厂、万能 Header 或携带业务枚举的 DesignSystem 组件。

提升前验收：有两个真实调用点；API 不泄露 Feature 模型；支持 Dynamic Type、Dark Mode、VoiceOver；交互点击区域至少 44pt；有独立 Preview 或测试。

## 9. T0–T10 任务边界

### T0：架构基线（本任务）

- 交付：本文档、构建/测试基线、迁移与验收清单。
- 禁止：任何业务代码、工程设置、页面结构、API 或测试修复。

### T1：Design System

- 前置：T0 已合并；可与 T3 并行。
- 只做：Foundation Token，Card/按钮/图标按钮/Loading/Empty/Error 基础组件与 Preview。
- 不做：Tab、Feature 迁移、页面重写、删除旧组件。

### T2：App Shell 与原生导航

- 前置：T1、T3 已合并。
- 只做：`AppTab`、`AppRouter`、`AppRootView`，原生 `TabView`，每 Tab 独立 `NavigationStack`，一级原生 toolbar，Home 类型化跳转。
- 不做：网络调用迁移、Feature Store、页面内部业务重构。
- 必须保留四个一级入口及功能语义。

### T3：统一网络层

- 前置：T0 已合并；可与 T1 并行。
- 只做：`HTTPClient/APIRequest/APIError/Multipart`、Client 协议、旧 Service 兼容适配、敏感日志清理、URLProtocol mock 测试。
- 不做：页面、AuthService、API 路径/JSON 合约、旧 Service 删除。

### T4：认证、SessionStore 与依赖注入

- 前置：T2、T3 已合并。
- 只做：`AppDependencies`、唯一 `SessionStore`、Auth 协议注入、CredentialStore/Keychain、旧 Token 一次迁移、登录/退出/注销时重置路由和状态。
- 不做：产品、肌肤、计划、Profile 的完整 Feature 重写。

### T5：产品库 Feature

- 前置：T4 已合并；可与 T7/T8/T9 并行。
- 只做：Products 目录、列表/筛选/添加/上传/删除、`ProductsStore`、Product Client 注入与测试。
- 保留：进入成分和冲突的路由接口。
- 不做：成分/冲突内部迁移，留给 T6。

### T6：成分分析与冲突分析

- 前置：T5 已合并。
- 只做：Products 下两个子 Feature、产品详情/成分/标签/冲突选择与结果、类型化 Sheet/路由、拆分大文件、Store 测试。
- 不做：其他 Feature 或 API 合约修改。

### T7：肌肤检测 Feature

- 前置：T4 已合并；可与 T5/T8/T9 并行。
- 只做：SkinAnalysis 目录与 Store，相机/相册/上传/进度/结果/历史，明确流程状态，相关 Loading/Error/Toast/Header 收敛。
- 必须保留：相机、相册权限行为和现有分析 API 语义。

### T8：Home 与 Plans

- 前置：T4 已合并；可与 T5/T7/T9 并行。
- 只做：Home/Plans 目录、共享 `PlanStore`、首页计划/每日步骤/方案生成保存、移除 `PlanSaved`、通过 Router 跨 Tab。
- 不做：Profile、产品或肌肤内部迁移。

### T9：Profile

- 前置：T4 已合并；可与 T5/T7/T8 并行。
- 只做：Profile 目录、共享 SessionStore、用户名/性别/反馈/退出/注销、类型化 Sheet、设置/确认/错误状态统一。
- 不做：其他 Feature；不得重新引入 singleton。

### T10：集成清理与最终验收

- 前置：T6、T7、T8、T9 全部合并。
- 只做：删除已迁移旧文件和确认死代码、清重复组件、检查 Feature `.shared`/裸品牌 RGB、统一最低版本到 iOS 17.6、补全文档、完整构建/单测/UI 回归。
- 禁止：借清理之名改变产品能力或后端 API 合约。

推荐合并顺序：T0 →（T1、T3）→ T2 → T4 →（T5、T7、T8、T9）→ T6 → T10。

## 10. 迁移前验证基线

### 10.1 Generic Simulator Debug build

执行命令：

```bash
xcodebuild \
  -project AIskin.xcodeproj \
  -scheme AIskin \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/aiskin-t0-build.XoBPn1 \
  CODE_SIGNING_ALLOWED=NO \
  build
```

结果：**通过**，退出码 0，`** BUILD SUCCEEDED **`。构建目标为 iOS 17.6 Simulator，Xcode 使用 iPhoneSimulator 26.2 SDK。日志有 `Supported platforms for the buildables in the current scheme is empty` 信息和 AppIntents 无依赖提示，但未阻塞构建。

### 10.2 测试编译

执行命令：

```bash
xcodebuild \
  -project AIskin.xcodeproj \
  -scheme AIskin \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=3A9FB799-01E9-4BF6-B31B-2F0F2CC8271F' \
  -derivedDataPath /tmp/aiskin-t0-build.XoBPn1 \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
```

结果：**失败/既有阻塞**，退出码 65，`** TEST BUILD FAILED **`。

主要编译错误：

- `AIskinTests/SkinAnalysisApiServiceTests.swift` 第 83、84、89、90、91、123、165、166、199 行直接访问已经变为 Optional 的 `overallAssessment` / `skinType`。
- `AIskinTests/RealImageTests.swift` 第 169、170、180–186、210 行存在同类直接访问；首次并行编译报告该文件失败。
- 同一测试文件还产生 MainActor 隔离警告；在 Swift 6 language mode 下会升级为错误。

这些是基线提交已有问题。T0 不允许修改测试或业务模型，因此只记录阻塞。

### 10.3 安全用例执行

已尝试只运行不触网、只调用 `app.launch()` 的 UI 冒烟用例：

```bash
xcodebuild \
  -project AIskin.xcodeproj \
  -scheme AIskin \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=3A9FB799-01E9-4BF6-B31B-2F0F2CC8271F' \
  -derivedDataPath /tmp/aiskin-t0-ui-test \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:AIskinUITests/AIskinUITests/testExample \
  test
```

结果：**未运行/被测试 Target 编译阻塞**，退出码 65。即使指定 `-only-testing`，当前 Scheme 仍编译 `AIskinTests`，随后因上述 Optional 错误取消测试。结果包位于 `/tmp/aiskin-t0-ui-test/Logs/Test/Test-AIskin-2026.08.25_00-03-42-+0800.xcresult`（临时目录，不作为仓库交付物）。

未执行其余 API/集成/真实图片测试，原因不是忽略测试，而是它们直接连接 `https://www.lunzo.site/api`，并会注册用户、创建/更新/删除产品和方案、上传图片、生成肌肤/成分/冲突分析；在没有隔离测试环境和清理保证时不属于安全的 T0 验证。

当前测试基线结论：

- App Debug 构建可作为后续每个任务的硬门禁。
- 当前没有可从 Scheme 成功执行的单元或 UI 测试结果。
- 后续修复测试编译应单独纳入允许修改测试的任务；不得为了让 T0 变绿而改业务代码。
- T3 起应新增完全使用 URLProtocol/mock client、不访问生产服务的确定性测试。

## 11. 每个迁移 MR 的验收清单

### 11.1 通用门禁

- [ ] 从最新 `main` 创建独立分支/worktree，确认前置 MR 已合并。
- [ ] `git diff` 只覆盖该任务卡范围，不携带原工作区 LookinServer/Xcode/UI 修改。
- [ ] Generic Simulator Debug build 通过。
- [ ] 运行该任务可安全执行的单元/UI 测试；失败或未运行必须写明命令和原因。
- [ ] 不改变四个一级入口的产品语义，不改变后端 API 合约。
- [ ] 新异步路径具有 loading/success/empty/error 或对应业务状态。
- [ ] 新组件满足 Dynamic Type、Dark Mode、VoiceOver 和 44pt 点击区域要求。
- [ ] Preview/测试可注入 mock，不要求真实 Token 或生产服务。
- [ ] MR 标题为英文祈使语气；描述用中文包含背景、改动、影响面、验证与已知阻塞。

### 11.2 架构守卫

- [ ] `Core` 与 `DesignSystem` 不依赖 Feature。
- [ ] Feature 不直接持有另一个 Feature 的 View/Store。
- [ ] 新页面/Store 不新增业务 `.shared` 访问。
- [ ] 新网络层不从 `AuthService.shared` 反向取 Token。
- [ ] 跨 Feature 跳转只通过 `AppRouter`。
- [ ] 公共组件满足“跨两个以上 Feature 且语义一致”，否则留在 Feature。
- [ ] 不新增万能 Header、万能 Card、`AnyView` 页面工厂。
- [ ] 旧兼容层只在调用方迁移完成后删除。

### 11.3 T10 最终回归

- [ ] 登录、注册、恢复登录、退出、注销。
- [ ] 四 Tab 切换及各自导航历史。
- [ ] Home → 产品、冲突选择、肌肤检测、个性化方案。
- [ ] 产品列表、筛选、添加、上传、刷新、删除。
- [ ] 产品详情、成分分析、标签保存、冲突选择与结果返回。
- [ ] 肌肤欢迎、相机、相册、分析中、成功、失败、历史。
- [ ] 方案保存后首页自动刷新、每日步骤更新。
- [ ] Profile 用户名、性别、反馈、退出、注销。
- [ ] Generic Simulator Debug、单元测试和核心 UI 冒烟测试全部通过。
- [ ] `Features` 无业务 `.shared`，DesignSystem 外无新增裸品牌 RGB。
- [ ] 删除候选死代码前再次完成全仓引用搜索和核心流程回归。

## 12. T0 完成判定

- [x] 当前目录、入口、四个 Tab、模态、API 服务和状态流已记录。
- [x] 超大文件、语义重复组件、未引用候选和 `.shared` 位置已标记。
- [x] 目标目录、依赖方向和组件提升规则已明确。
- [x] T1–T10 的前置条件、范围与禁止项已明确。
- [x] Generic Simulator Debug build 通过。
- [x] 测试编译失败和安全执行阻塞已如实记录，未越界修业务/测试代码。
- [x] T0 交付只包含本文档。
