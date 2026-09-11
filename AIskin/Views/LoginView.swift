import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var appleLogin = AppleLoginStore()
    @State private var legalDocument: LegalDocument?
    @State private var page = 0
    @GestureState private var isDragging = false
    @State private var voiceOverRunning = UIAccessibility.isVoiceOverRunning
    @State private var lastPageInteraction = ContinuousClock.now
    @State private var autoAdvanceEnabled = false
    var onContinueSession: (() -> Void)? = nil

    private let pages: [OnboardingPage] = [
        .init(number: "01", name: "拍照看肌肤问题", title: "肌肤有哪些问题？", accentTitle: "拍一下，看看。",
              detail: "拍下清晰的正面照片，\n查看泛红、痘痘、毛孔等肤况分析。", image: "OnboardingSkin",
              imageDescription: "拍照取景中的卡通人物，两颊泛红、鼻部毛孔和下巴痘痘均被圈出并标注"),
        .init(number: "02", name: "混合冲突检测", title: "这几瓶混着用，", accentTitle: "会不会「烂脸」？",
              detail: "担心混用出问题？\n上脸前，先查成分搭配中的潜在冲突。", image: "OnboardingConflict",
              imageDescription: "精华与面霜汇聚到同一块脸颊，出现泛红与起痘的混用风险示意"),
        .init(number: "03", name: "拍照查功效与风险", title: "拍一下成分表，", accentTitle: "功效、风险一起看。",
              detail: "基于成分，了解主要功效与潜在风险。\n不只听宣传，多一份判断依据。", image: "OnboardingIngredient",
              imageDescription: "手机正在拍摄长方体护肤品包装盒上的成分列表")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    let item = pages[index]
                    AISkinOnboardingSlide(number: item.number, title: item.title, accentTitle: item.accentTitle,
                                          detail: item.detail, imageName: item.image, imageDescription: item.imageDescription)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityIdentifier("onboarding.carousel")
            .simultaneousGesture(DragGesture().updating($isDragging) { _, dragging, _ in dragging = true })
            AISkinPageControl(labels: pages.map(\.name), selection: $page)
                .padding(.bottom, AISkinOnboardingTokens.footerGap)
            AISkinAuthFooter(isLoading: appleLogin.isLoading, errorMessage: appleLogin.errorMessage,
                             onLegalDocument: { legalDocument = $0 }) {
                if sessionStore.isAuthenticated, let onContinueSession {
                    AISkinButton(action: onContinueSession) { Text("进入析肤") }
                        .accessibilityIdentifier("onboarding.continue-session")
                } else {
                    AISkinAppleSignInButton(isLoading: appleLogin.isLoading, presentation: .onboarding) { request in
                        appleLogin.prepare(request)
                    } onCompletion: { result in
                        Task { await appleLogin.complete(result, session: sessionStore) }
                    }
                }
            }
        }
        .frame(maxWidth: AISkinOnboardingTokens.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .sheet(item: $legalDocument, onDismiss: { lastPageInteraction = .now }) { LegalDocumentView(document: $0) }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            lastPageInteraction = .now
            while !Task.isCancelled {
                do { try await Task.sleep(for: AISkinOnboardingTokens.autoAdvanceCheckInterval) }
                catch { return }
                let now = ContinuousClock.now
                guard autoAdvanceEnabled else {
                    lastPageInteraction = now
                    continue
                }
                guard now - lastPageInteraction >= AISkinOnboardingTokens.autoAdvanceInterval else { continue }
                lastPageInteraction = now
                withAnimation(AISkinMotion.standard) { page = (page + 1) % pages.count }
            }
        }
        .onChange(of: page) { _, _ in lastPageInteraction = .now }
        .onChange(of: canAutoAdvance, initial: true) { _, enabled in
            // A long-lived task must read current state, not its captured scene environment.
            autoAdvanceEnabled = enabled
            lastPageInteraction = .now
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
            voiceOverRunning = UIAccessibility.isVoiceOverRunning
        }
        .onChange(of: sessionStore.isAuthenticated) { _, authenticated in
            if authenticated { onContinueSession?() }
        }
    }

    private var canAutoAdvance: Bool {
        scenePhase == .active && legalDocument == nil && !appleLogin.isLoading
            && !isDragging && !reduceMotion && !voiceOverRunning
    }
}

private struct OnboardingPage {
    let number: String
    let name: String
    let title: String
    let accentTitle: String
    let detail: String
    let image: String
    let imageDescription: String
}
