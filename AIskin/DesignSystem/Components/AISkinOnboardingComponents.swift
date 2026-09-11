import SwiftUI

struct AISkinOnboardingSlide: View {
    let number: String
    let title: String
    let accentTitle: String
    let detail: String
    let imageName: String
    let imageDescription: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var titleSize = AISkinOnboardingTokens.titleSize
    @ScaledMetric(relativeTo: .caption) private var bodySize = AISkinOnboardingTokens.bodySize
    @ScaledMetric(relativeTo: .caption) private var numberSize = AISkinOnboardingTokens.numberSize
    @ScaledMetric(relativeTo: .title) private var headingHeight = AISkinOnboardingTokens.headingHeight
    @State private var appeared = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < AISkinOnboardingTokens.compactHeight
            let artworkSize = min(AISkinOnboardingTokens.artworkMaxSize,
                                  geometry.size.width - AISkinOnboardingTokens.artworkInset * 2,
                                  max(AISkinOnboardingTokens.artworkMinimumSize, geometry.size.height - headingHeight))
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text(number)
                            .font(.system(size: numberSize, weight: .medium))
                            .monospacedDigit()
                            .tracking(AISkinOnboardingTokens.numberTracking)
                            .foregroundStyle(AISkinColor.accent)
                            .opacity(AISkinOnboardingTokens.numberOpacity)
                            .padding(.bottom, AISkinSpacing.medium)
                        VStack(spacing: AISkinOnboardingTokens.titleSpacing) {
                            Text(title).foregroundStyle(AISkinColor.textPrimary)
                            Text(accentTitle).foregroundStyle(AISkinColor.accent)
                        }
                        .font(.system(size: compact ? titleSize * AISkinOnboardingTokens.compactTitleSize / AISkinOnboardingTokens.titleSize : titleSize, weight: .semibold))
                        .tracking(AISkinOnboardingTokens.titleTracking)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                        Text(detail)
                            .font(.system(size: bodySize))
                            .lineSpacing(AISkinOnboardingTokens.copyLineSpacing)
                            .foregroundStyle(AISkinColor.textSecondary)
                            .padding(.top, AISkinSpacing.small)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, AISkinSpacing.large)
                    .padding(.top, compact ? AISkinOnboardingTokens.compactTopInset : AISkinOnboardingTokens.topInset)

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: artworkSize, height: artworkSize)
                        .mask {
                            LinearGradient(gradient: AISkinOnboardingTokens.verticalMask, startPoint: .top, endPoint: .bottom)
                                .mask(LinearGradient(gradient: AISkinOnboardingTokens.horizontalMask, startPoint: .leading, endPoint: .trailing))
                        }
                        .blendMode(.multiply)
                        .accessibilityLabel(imageDescription)
                        .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .opacity(appeared || reduceMotion ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : AISkinOnboardingTokens.entranceOffset)
        .onAppear {
            withAnimation(reduceMotion ? nil : AISkinOnboardingTokens.entranceAnimation) { appeared = true }
        }
    }
}

struct AISkinPageControl: View {
    let labels: [String]
    @Binding var selection: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { index in
                Button {
                    withAnimation(reduceMotion ? nil : AISkinMotion.standard) { selection = index }
                } label: {
                    Circle()
                        .fill(AISkinColor.accent.opacity(index == selection ? 1 : AISkinOnboardingTokens.inactiveDotOpacity))
                        .frame(width: AISkinOnboardingTokens.dotSize, height: AISkinOnboardingTokens.dotSize)
                        .frame(width: AISkinLayout.minimumTapHeight, height: AISkinLayout.minimumTapHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(AISkinPressableStyle())
                .accessibilityLabel("第 \(index + 1) 页：\(labels[index])")
                .accessibilityAddTraits(index == selection ? [.isSelected] : [])
                .accessibilityIdentifier("onboarding.page.\(index)")
            }
        }
    }
}

struct AISkinAuthFooter<Action: View>: View {
    let isLoading: Bool
    let errorMessage: String?
    let onLegalDocument: (LegalDocument) -> Void
    @ViewBuilder let action: () -> Action

    var body: some View {
        VStack(spacing: 0) {
            action()
            if isLoading {
                ProgressView("正在登录…")
                    .font(AISkinTypography.caption)
                    .tint(AISkinColor.accent)
                    .padding(.top, AISkinSpacing.xSmall)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(AISkinTypography.caption)
                    .foregroundStyle(AISkinColor.destructive)
                    .multilineTextAlignment(.center)
                    .padding(.top, AISkinSpacing.xSmall)
                    .accessibilityIdentifier("auth.error")
            }
            HStack(spacing: AISkinSpacing.xSmall) {
                legalButton(.terms)
                Text("·")
                legalButton(.privacy)
            }
            .font(AISkinAuthLayout.legal)
            .foregroundStyle(AISkinColor.textSecondary)
        }
        .padding(.horizontal, AISkinSpacing.screenEdge)
        .padding(.bottom, AISkinOnboardingTokens.footerBottom)
    }

    private func legalButton(_ document: LegalDocument) -> some View {
        Button { onLegalDocument(document) } label: {
            Text(document.title).underline().frame(minHeight: AISkinLayout.minimumTapHeight)
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityIdentifier("auth.legal.\(document.rawValue)")
    }
}
