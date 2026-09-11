import SwiftUI

/// A shared, explicitly estimated waiting state. Only the feature's actual
/// request result dismisses it; the estimate can never complete a request.
struct AISkinProcessingPanel: View {
    let title: String
    var message: String = "稍等一下，细节也想照顾到"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title2) private var ringDiameter = AISkinLayout.processingRingDiameter
    @State private var progress = 0.0
    private var percentage: Int { Int(progress.rounded()) }

    var body: some View {
        panel
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("analysis.processing")
        .task {
            // Scoped to this presentation: disappearing cancels updates, and
            // a new request starts from zero instead of inheriting old progress.
            progress = 0
            let clock = ContinuousClock()
            let start = clock.now
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(AISkinMotion.processingUpdateInterval))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                let elapsed = start.duration(to: clock.now).components
                let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
                progress = AISkinProcessingEstimate.progress(elapsed: seconds)
                if percentage == AISkinProcessingEstimate.ceiling { return }
            }
        }
    }

    private var panel: some View {
        AISkinCard(inset: .none) {
            VStack(spacing: AISkinSpacing.large) {
                ring
                VStack(spacing: AISkinSpacing.xxSmall) {
                    Text(title)
                        .font(AISkinTypography.processingTitle)
                        .foregroundStyle(AISkinColor.textPrimary)
                    Text(message)
                        .font(AISkinTypography.caption)
                        .foregroundStyle(AISkinColor.textSecondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(AISkinSpacing.xLarge)
        }
        .frame(maxWidth: AISkinLayout.processingPanelMaxWidth)
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(AISkinColor.surfaceSelected, lineWidth: AISkinLayout.progressRingStroke)
            Circle()
                .trim(from: 0, to: CGFloat(progress) / 100)
                .stroke(AISkinColor.accent, style: StrokeStyle(
                    lineWidth: AISkinLayout.progressRingStroke, lineCap: .round
                ))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : AISkinMotion.processingAdvance, value: progress)
            VStack(spacing: AISkinSpacing.xxSmall) {
                Text("\(percentage)%")
                    .font(AISkinTypography.processingPercentage)
                    .monospacedDigit()
                    .foregroundStyle(AISkinColor.accent)
                Text("预估")
                    .font(AISkinTypography.caption)
                    .foregroundStyle(AISkinColor.textSecondary)
            }
        }
        .frame(width: ringDiameter, height: ringDiameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("预估进度")
        .accessibilityValue("\(percentage)%")
        .accessibilityIdentifier("analysis.processing.estimated-progress")
    }
}

#Preview("统一预估等待页") {
    AISkinProcessingScreen(title: "肌肤检测", message: "正在分析肌肤照片", onCancel: {})
}
