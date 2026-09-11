import Foundation
import UIKit
import Combine

@MainActor
protocol FeatureSkinAnalysisClient {
    var usesSimulatedData: Bool { get }
    func history(page: Int, limit: Int) async throws -> [SkinAnalysis]
    func analyze(image: UIImage) async throws -> SkinAnalysis
    func result(from analysis: SkinAnalysis) -> AnalysisResult
    func updateContext(analysisID: String, condition: String?, light: String?, feelings: [String]?) async throws -> SkinAnalysis
}

extension FeatureSkinAnalysisClient {
    var usesSimulatedData: Bool { false }
    func updateContext(analysisID: String, condition: String?, light: String?, feelings: [String]?) async throws -> SkinAnalysis {
        throw APIError.serverError("检测备注服务不可用")
    }
}

@MainActor
struct LegacySkinAnalysisClient: FeatureSkinAnalysisClient {
    func updateContext(analysisID: String, condition: String?, light: String?, feelings: [String]?) async throws -> SkinAnalysis {
        try await SkinAnalysisApiService.shared.updateContext(analysisID: analysisID, condition: condition, light: light, feelings: feelings)
    }
    var usesSimulatedData: Bool {
        AppBackendConfiguration.mode == .mock
    }

    func history(page: Int, limit: Int) async throws -> [SkinAnalysis] {
        try await SkinAnalysisApiService.shared.getAnalysisHistory(page: page, limit: limit).analyses
    }

    func analyze(image: UIImage) async throws -> SkinAnalysis {
        try await SkinAnalysisApiService.shared.analyzeSkin(image: image)
    }

    func result(from analysis: SkinAnalysis) -> AnalysisResult {
        var result = SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
        result.isSimulated = usesSimulatedData
        return result
    }
}

@MainActor
final class SkinAnalysisStore: ObservableObject {
    enum FlowState {
        case welcome
        case analyzing(status: String)
        case result(AnalysisResult)
        case failed(String)
    }

    @Published private(set) var flow: FlowState = .welcome
    @Published var selectedImage: UIImage?
    @Published private(set) var history: [AnalysisResult] = []
    @Published var isHistoryPresented = false
    @Published private(set) var historyError: String?
    @Published private(set) var isLoadingHistory = false
    @Published private(set) var hasMoreHistory = false
    @Published private(set) var contextSaveError: String?
    @Published private(set) var isSavingContext = false

    private let client: any FeatureSkinAnalysisClient
    private var analysisTask: Task<Void, Never>?
    private var analysisRequestID: UUID?
    private let historyPageSize = 10
    private var loadedHistoryPage = 0
    private var failedHistoryPage: Int?

    init(client: (any FeatureSkinAnalysisClient)? = nil) {
        self.client = client ?? LegacySkinAnalysisClient()
    }

    deinit { analysisTask?.cancel() }

    var result: AnalysisResult? {
        if case let .result(result) = flow { return result }
        return nil
    }

    var lastResult: AnalysisResult? { history.first }
    var hasHistory: Bool { !history.isEmpty }

    func loadHistory() async {
        await loadHistoryPage(1, replacing: true)
    }

    func loadMoreHistory() async {
        guard hasMoreHistory else { return }
        await loadHistoryPage(loadedHistoryPage + 1, replacing: false)
    }

    func retryHistory() async {
        let page = failedHistoryPage ?? 1
        await loadHistoryPage(page, replacing: page == 1)
    }

    private func loadHistoryPage(_ page: Int, replacing: Bool) async {
        guard !isLoadingHistory else { return }
        isLoadingHistory = true
        historyError = nil
        defer { isLoadingHistory = false }
        do {
            let analyses = try await client.history(page: page, limit: historyPageSize)
            try Task.checkCancellation()
            let incoming = analyses.map(client.result(from:))
            if replacing {
                history = incoming
            } else {
                // New analyses can shift page boundaries while the user is browsing.
                // Keep each saved report once and retain already loaded snapshots.
                var knownIDs = Set(history.compactMap(\.sourceID))
                for result in incoming {
                    if let id = result.sourceID, !knownIDs.insert(id).inserted { continue }
                    history.append(result)
                }
            }
            loadedHistoryPage = page
            failedHistoryPage = nil
            hasMoreHistory = analyses.count == historyPageSize
        } catch is CancellationError {
            return
        } catch {
            // Retain rows and the page cursor so retry requests the same page.
            failedHistoryPage = page
            historyError = "获取检测历史失败：\(error.localizedDescription)"
        }
    }

    func updateContext(analysisID: String, condition: String?, light: String?, feelings: [String]?) async -> Bool {
        guard !isSavingContext else { return false }
        isSavingContext = true
        contextSaveError = nil
        defer { isSavingContext = false }
        do {
            let analysis = try await client.updateContext(analysisID: analysisID, condition: condition, light: light, feelings: feelings)
            guard analysis.id == analysisID else { throw APIError.serverError("服务端返回的检测记录不一致") }
            let updated = client.result(from: analysis)
            if let index = history.firstIndex(where: { $0.sourceID == analysisID }) { history[index] = updated }
            if result?.sourceID == analysisID { flow = .result(updated) }
            return true
        } catch {
            contextSaveError = "保存检测备注失败：\(error.localizedDescription)"
            return false
        }
    }

    func selectHistory(_ result: AnalysisResult) {
        cancelAnalysis()
        flow = .result(result)
        isHistoryPresented = false
    }

    func processSelectedImage() {
        cancelAnalysis()
        guard let image = selectedImage else {
            flow = .failed("未选择图片")
            return
        }
        guard validate(image: image) else { return }

        let requestID = UUID()
        analysisRequestID = requestID
        flow = .analyzing(status: client.usesSimulatedData ? "正在生成模拟检测报告…" : "正在上传并分析肌肤照片…")
        analysisTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.analysisRequestID == requestID {
                    self.analysisTask = nil
                    self.analysisRequestID = nil
                }
            }
            do {
                try Task.checkCancellation()
                let analysis = try await self.client.analyze(image: image)
                try Task.checkCancellation()
                guard self.analysisRequestID == requestID else { return }
                let result = self.client.result(from: analysis)
                self.flow = .result(result)
                await self.loadHistory()
            } catch is CancellationError {
                if self.analysisRequestID == requestID { self.flow = .welcome }
                return
            } catch {
                guard !Task.isCancelled, self.analysisRequestID == requestID else { return }
                self.flow = .failed("分析失败：\(error.localizedDescription)")
            }
        }
    }

    func reset() {
        cancelAnalysis()
        selectedImage = nil
        flow = .welcome
    }

    private func cancelAnalysis() {
        analysisRequestID = nil
        analysisTask?.cancel()
        analysisTask = nil
    }

    func dismissError() {
        if case .failed = flow { flow = .welcome }
    }

    private func validate(image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 1) else {
            flow = .failed("无法读取图片，请重新选择")
            return false
        }
        guard data.count <= 10 * 1024 * 1024 else {
            flow = .failed("图片文件过大，请选择小于10MB的图片")
            return false
        }
        return true
    }
}
