import Foundation
import UIKit
import Combine

@MainActor
protocol FeatureSkinAnalysisClient {
    func history(page: Int, limit: Int) async throws -> [SkinAnalysis]
    func analyze(image: UIImage) async throws -> SkinAnalysis
    func result(from analysis: SkinAnalysis) -> AnalysisResult
}

@MainActor
struct LegacySkinAnalysisClient: FeatureSkinAnalysisClient {
    func history(page: Int, limit: Int) async throws -> [SkinAnalysis] {
        try await SkinAnalysisApiService.shared.getAnalysisHistory(page: page, limit: limit).analyses
    }

    func analyze(image: UIImage) async throws -> SkinAnalysis {
        try await SkinAnalysisApiService.shared.analyzeSkin(image: image)
    }

    func result(from analysis: SkinAnalysis) -> AnalysisResult {
        SkinAnalysisApiService.shared.convertToAnalysisResult(analysis)
    }
}

@MainActor
final class SkinAnalysisStore: ObservableObject {
    enum FlowState {
        case welcome
        case analyzing(progress: Double, status: String)
        case result(AnalysisResult)
        case failed(String)
    }

    @Published private(set) var flow: FlowState = .welcome
    @Published var selectedImage: UIImage?
    @Published private(set) var history: [AnalysisResult] = []
    @Published var isHistoryPresented = false

    private let client: any FeatureSkinAnalysisClient
    private var analysisTask: Task<Void, Never>?

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
        do {
            let analyses = try await client.history(page: 1, limit: 10)
            try Task.checkCancellation()
            history = analyses.map(client.result(from:))
        } catch is CancellationError {
            return
        } catch {
            // History is secondary content; a failure must not block a new analysis.
            history = []
        }
    }

    func selectHistory(_ result: AnalysisResult) {
        flow = .result(result)
        isHistoryPresented = false
    }

    func processSelectedImage() {
        guard let image = selectedImage else {
            flow = .failed("未选择图片")
            return
        }
        guard validate(image: image) else { return }

        analysisTask?.cancel()
        analysisTask = Task { [weak self] in
            guard let self else { return }
            self.flow = .analyzing(progress: 0.15, status: "正在上传图片到云端...")
            do {
                self.flow = .analyzing(progress: 0.45, status: "正在分析肌肤状况...")
                let analysis = try await self.client.analyze(image: image)
                try Task.checkCancellation()
                self.flow = .analyzing(progress: 1, status: "分析完成！")
                let result = self.client.result(from: analysis)
                self.flow = .result(result)
                await self.loadHistory()
            } catch is CancellationError {
                return
            } catch {
                self.flow = .failed("分析失败：\(error.localizedDescription)")
            }
        }
    }

    func reset() {
        analysisTask?.cancel()
        selectedImage = nil
        flow = .welcome
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
