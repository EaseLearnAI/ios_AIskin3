import SwiftUI

struct PersonalInformationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionStore
    @State private var showsAgeEditor = false

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(title: "个人信息", backAction: { dismiss() })
            ScrollView {
                AISkinCard(inset: .none) {
                    PersonalAgeRow(age: session.currentUser?.age) { showsAgeEditor = true }
                }
                .padding(AISkinSpacing.screenEdge)
            }
        }
        .sheet(isPresented: $showsAgeEditor) { AgeEditorView() }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

/// Both entry points edit the same persisted account field.
struct AgeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionStore
    @State private var age = ""
    @State private var isSaving = false
    @State private var error: String?
    @FocusState private var isFocused: Bool

    private var validAge: Int? {
        guard let value = Int(age), User.ageRange.contains(value) else { return nil }
        return value
    }

    var body: some View {
        AISkinBottomSheet(title: "年龄", detail: "保存后将用于定制护肤方案，也可在个人信息中修改。", closeLabel: "取消", isBusy: isSaving, onClose: { dismiss() }) {
            VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                AISkinField(state: error != nil ? .error : (isFocused ? .focused : .normal), variant: .form) {
                    TextField("请输入年龄", text: $age)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .accessibilityIdentifier("personal-information.age.input")
                        .onChange(of: age) { _, _ in error = nil }
                    Text("岁")
                }
                if let error {
                    AISkinStateView(content: .error(title: "年龄保存失败", message: error))
                } else if !age.isEmpty && validAge == nil {
                    AISkinStateView(content: .error(title: "请检查年龄", message: "请输入 13–120 的整数。"))
                }
            }
        } footer: {
            AISkinButton(isLoading: isSaving, action: save) { Text("保存") }
                .disabled(validAge == nil)
                .accessibilityIdentifier("personal-information.age.save")
        }
        .presentationDetents([.medium, .large])
        .onAppear { age = session.currentUser?.age.map(String.init) ?? "" }
    }

    private func save() {
        guard let value = validAge, !isSaving else { return }
        isFocused = false
        isSaving = true
        error = nil
        Task { @MainActor in
            defer { isSaving = false }
            do {
                try await session.updateAge(age: value)
                dismiss()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
