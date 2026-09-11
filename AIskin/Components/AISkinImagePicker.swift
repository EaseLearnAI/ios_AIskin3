import AVFoundation
import PhotosUI
import SwiftUI

/// One camera-first flow for product labels and skin photos.
struct AISkinCameraCapture: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var cameraAuthorized: Bool? = UIImagePickerController.isSourceTypeAvailable(.camera) ? nil : false
    @State private var showsLibrary = false
    @State private var librarySelectionMade = false

    var body: some View {
        Group {
            if cameraAuthorized == true {
                AISkinImagePicker(image: $image, sourceType: .camera)
                    .ignoresSafeArea()
            } else {
                AISkinScreenBackground {
                    VStack(spacing: AISkinSpacing.medium) {
                        if cameraAuthorized == nil {
                            AISkinStateView(content: .loading(message: "正在打开相机…"))
                        } else {
                            AISkinStateView(content: .empty(
                                title: "相机暂不可用",
                                message: UIImagePickerController.isSourceTypeAvailable(.camera)
                                    ? "请在设置中允许相机访问，或从相册选择照片。"
                                    : "此设备无法拍照，可以从相册选择照片。",
                                systemImage: "camera"))
                            AISkinButton(action: { showsLibrary = true }) {
                                Label("从相册上传", systemImage: "photo")
                            }
                            .accessibilityIdentifier("capture.choose-photo")
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                AISkinButton(variant: .secondary, action: openSettings) { Text("打开设置") }
                            }
                        }
                        AISkinButton(variant: .secondary, action: { dismiss() }) { Text("取消") }
                            .accessibilityIdentifier("capture.cancel")
                    }
                    .padding(AISkinSpacing.screenEdge)
                }
            }
        }
        .task { await checkCameraAccess() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await checkCameraAccess() } }
        }
        .sheet(isPresented: $showsLibrary, onDismiss: {
            if librarySelectionMade { dismiss() }
        }) {
            AISkinPhotoLibraryPicker { selectedImage in
                image = selectedImage
                librarySelectionMade = true
                showsLibrary = false
            }
        }
    }

    @MainActor
    private func checkCameraAccess() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAuthorized = false
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: cameraAuthorized = true
        case .notDetermined:
            let allowed = await AVCaptureDevice.requestAccess(for: .video)
            guard !Task.isCancelled else { return }
            cameraAuthorized = allowed
        default: cameraAuthorized = false
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct AISkinImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.mediaTypes = ["public.image"]
        picker.modalPresentationStyle = .fullScreen
        if sourceType == .camera {
            picker.showsCameraControls = true
            let albumButton = UIHostingController(rootView: AISkinIconButton(
                systemName: "photo.on.rectangle",
                accessibilityLabel: "从相册上传",
                variant: .surface,
                action: { [weak picker, weak coordinator = context.coordinator] in
                    guard let picker else { return }
                    coordinator?.openLibrary(from: picker)
                }
            ).accessibilityIdentifier("capture.choose-photo"))
            albumButton.view.backgroundColor = .clear
            context.coordinator.albumButton = albumButton
            let overlay = AISkinCameraLibraryOverlay(button: albumButton.view)
            overlay.frame = picker.view.bounds
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            picker.cameraOverlayView = overlay
        }
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: AISkinImagePicker
        var albumButton: UIViewController?
        private var libraryDelegate: AISkinPhotoSelectionDelegate?

        init(_ parent: AISkinImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let selectedImage = info[.originalImage] as? UIImage else { return }
            parent.image = selectedImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func openLibrary(from camera: UIImagePickerController) {
            guard camera.presentedViewController == nil else { return }
            let picker = AISkinPhotoLibraryPicker.makePicker()
            let delegate = AISkinPhotoSelectionDelegate { [weak self, weak picker] selectedImage in
                guard let picker else { return }
                picker.dismiss(animated: true) {
                    guard let self else { return }
                    self.parent.image = selectedImage
                    self.parent.dismiss()
                }
            } onCancel: { [weak picker] in
                // Cancel only the album; the system camera stays open underneath.
                picker?.dismiss(animated: true)
            }
            libraryDelegate = delegate
            picker.delegate = delegate
            camera.present(picker, animated: true)
        }
    }
}

struct AISkinPhotoLibraryPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    static func makePicker() -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        return PHPickerViewController(configuration: configuration)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let picker = Self.makePicker()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> AISkinPhotoSelectionDelegate {
        AISkinPhotoSelectionDelegate(onImage: onImage, onCancel: { dismiss() })
    }
}

final class AISkinPhotoSelectionDelegate: NSObject, PHPickerViewControllerDelegate {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.onImage = onImage
        self.onCancel = onCancel
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let provider = results.first?.itemProvider else { onCancel(); return }
        guard provider.canLoadObject(ofClass: UIImage.self) else { showError(in: picker); return }
        picker.view.isUserInteractionEnabled = false
        provider.loadObject(ofClass: UIImage.self) { [weak self, weak picker] object, _ in
            DispatchQueue.main.async {
                guard let self, let picker else { return }
                picker.view.isUserInteractionEnabled = true
                guard let image = object as? UIImage else { self.showError(in: picker); return }
                self.onImage(image)
            }
        }
    }

    private func showError(in picker: PHPickerViewController) {
        let alert = UIAlertController(title: "无法读取照片", message: "请确认照片已下载，或换一张照片重试。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "重新选择", style: .default))
        picker.present(alert, animated: true)
    }
}

/// Only the album button intercepts touches; system camera controls remain interactive.
private final class AISkinCameraLibraryOverlay: UIView {
    let button: UIView

    init(button: UIView) {
        self.button = button
        super.init(frame: .zero)
        addSubview(button)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = AISkinLayout.minimumTapHeight
        button.frame = CGRect(
            x: safeAreaInsets.left + AISkinSpacing.screenEdge,
            y: bounds.height - safeAreaInsets.bottom - AISkinLayout.cameraLibraryBottomClearance - size,
            width: size,
            height: size
        )
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0, isUserInteractionEnabled else { return nil }
        return button.hitTest(convert(point, to: button), with: event)
    }
}
