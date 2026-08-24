//
//  ImageUploader.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI
import PhotosUI

struct ImageUploader: View {
    @Binding var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    let placeholder: String
    
    var body: some View {
        VStack(spacing: 0) {
            if let image = selectedImage {
                // Preview with actions
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 270)
                        .cornerRadius(12)
                        .clipped()
                        .lookinName("product.add-modal.image-preview")
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            selectedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(width: 36, height: 36)
                                )
                        }
                        .lookinName("product.add-modal.image-remove")
                    }
                    .padding(12)
                }
                
                // Image name
                Text("已选择图片")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.557, green: 0.557, blue: 0.576))
                    .padding(.top, 8)
            } else if isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("上传中...")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.557, green: 0.557, blue: 0.576))
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.961, green: 0.961, blue: 0.969))
                .cornerRadius(12)
                .lookinName("product.add-modal.image-loading")
            } else {
                // Placeholder
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.204, green: 0.780, blue: 0.349),
                                            Color(red: 0.188, green: 0.820, blue: 0.345)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Color(red: 0.204, green: 0.780, blue: 0.349).opacity(0.25), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Text(placeholder)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.557, green: 0.557, blue: 0.576))
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.961, green: 0.961, blue: 0.969))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            .foregroundColor(Color(red: 0.780, green: 0.780, blue: 0.800))
                    )
                }
                .lookinName("product.add-modal.image-picker")
            }
        }
        .lookinName("product.add-modal.image-uploader")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}



