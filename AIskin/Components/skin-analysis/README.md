# 肌肤分析前端结构

本文对应当前 SwiftUI 实现。肌肤检测、成分分析、冲突检测与方案生成复用 DesignSystem；肌肤模块只保留自己的数据绑定、业务流程和报告内容。

## 职责与文件

| 层 | 当前实现 | 职责 |
| --- | --- | --- |
| 页面 | `Views/SkinStatusView.swift` | 检测入口、照片选择、报告与历史导航 |
| 状态 | `Features/SkinAnalysis/SkinAnalysisStore.swift` | 分析任务、取消、错误恢复、历史分页及拍摄备注保存 |
| 服务 | `Services/SkinAnalysisApiService.swift` | API 调用与接口模型到报告模型的转换 |
| 数据 | `Models/AnalysisResult.swift`、`Models/SkinObservationData.swift`、`Models/SkinTypeData.swift` | 报告数据与肤况观察值；不包含 View |
| 展示映射 | `SkinReportPresentation.swift` | 将已保存数据转为指标、状态说明和报告文案 |
| 完整报告 | `SkinReportView.swift` | 汇总、原图、观察详情、建议、历史对比与操作入口 |
| 历史 | `HistoryModal.swift` | `SkinHistorySheet`、`SkinHistoryList`、`SkinHistoryRow`，供肌肤入口、报告与个人记录复用 |
| 欢迎内容 | `welcomeContentView/SkinDetectionWelcome.swift` | 首次检测引导及拍摄入口 |
| 报告内容 | `resultsContentView/AIRecommendations.swift`、`SkinPlanCallToAction.swift` | 建议内容及定制方案入口 |

## 共享界面规则

- 全局背景由 `AISkinScreenBackground` 与 `AISkinColor` 统一提供。
- 分析等待态统一使用 `AISkinProcessingScreen`：完整背景、共享 Header 和居中 `AISkinProcessingPanel`，不使用蒙层。预估曲线由 Foundation 中的 `AISkinProcessingEstimate` 统一管理，约 3 秒 60%、8 秒 84%，随后减速并停在 98%；真实请求完成立即结束等待。页面只传标题、文案及取消/重试行为。
- 标题栏、按钮、卡片、加载/空/错误状态分别复用 `AISkinHeader`、`AISkinButton`、`AISkinCard`、`AISkinStateView`。
- 概览与完整报告共用 `AISkinSkinSummaryCard`。报告相关结构集中在 `DesignSystem/Components/AISkinSkinReportComponents.swift` 等共享组件中。
- 颜色、字体、尺寸等视觉值由 `DesignSystem/Foundation` 提供；数据模型位于 `Models`，不放在组件目录。

## 数据与流程

```text
照片选择 → SkinAnalysisStore.processSelectedImage()
         → FeatureSkinAnalysisClient.analyze(image:)
         → SkinAnalysisApiService → 接口模型
         → AnalysisResult → 同一套概览 / SkinReportView

历史入口 → SkinAnalysisStore.loadHistory() / loadMoreHistory()
         → SkinHistoryList → selectHistory(选中的记录)
         → 同一个 SkinReportView
```

`SkinAnalysisStore.flow` 是检测任务状态来源：`welcome`、`analyzing`、`result`、`failed`。取消时会使当前请求标识失效，避免迟到结果覆盖新流程。历史加载与检测任务分别保存错误和加载状态，已有记录会在分页失败时保留。

正常运行的数据来源由后端配置决定；Mock 仅用于本地调试与测试，不代表真实分析验收。缺失的评分、原图或观察信息应明确显示未提供，不能用另一条记录补齐。

旧的 `AnalyzingModal`、`SkinAnalysisHeader`、`HealthScoreCard`、`WeatherCard`、`SkinTypeAnalysis`、`HistorySection` 已移除。原 `SkinStatusOverview.swift` 剩余的纯数据结构已迁到 `Models/SkinObservationData.swift`，避免保留看似仍在使用的旧页面副本。
