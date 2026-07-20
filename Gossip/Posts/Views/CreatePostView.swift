//
//  CreatePostView.swift
//  Gossip
//
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: Image?
    @State private var imageData: Data?
    @State private var fileName: String?
    @State private var mimeType: String?
    
    private var isContentOrImagePresent: Bool {
        if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        if imageData != nil, fileName != nil, mimeType != nil {
            return true
        }
        
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pealkiri") {
                    TextField("", text: $title)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("Sisu") {
                    TextField("", text: $content, axis: .vertical)
                        .lineLimit(8...20)
                }

                Section("Pilt") {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Vali pilt", systemImage: "photo")
                    }

                    if selectedPhotoItem != nil {
                        Button("Eemalda pilt", role: .destructive) {
                            selectedPhotoItem = nil
                            selectedImage = nil
                        }
                    }

                    if let selectedImage = selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .onChange(of: selectedPhotoItem) {
                if let selectedPhotoItem {
                    Task {
                        do {
                            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                
                                selectedImage = Image(uiImage: uiImage)
                                imageData = data
                                
                                let type = mimeType(for: data)
                                mimeType = type
                                
                                // The server will name the file after the hash anyways, so we do not care about the file name.
                                if let ext = type.components(separatedBy: "/").last {
                                    fileName = "\(UUID().uuidString).\(ext)"
                                } else {
                                    fileName = nil
                                }

                            } else {
                                imageData = nil
                                fileName = nil
                                mimeType = nil
                            }
                        } catch {
                            print("DEBUG: Failed loading image: \(error)")
                            imageData = nil
                            fileName = nil
                            mimeType = nil
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Postita") {
                        Task {
                            await submitPost()
                        }
                    }
                    .disabled(isSubmitting || title.isEmpty || !isContentOrImagePresent)
                }
                ToolbarItem(placement: .principal) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .close) {
                            dismiss()
                        }
                    } else {
                        Button("Tühista") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    func submitPost() async {
        errorMessage = nil
        
        if (title.isEmpty) {
            errorMessage = "Pealkiri on puudu!"
            return
        }
        
        let image: UploadImage? = {
            guard let data = imageData,
                  let name = fileName,
                  let type = mimeType else {
                return nil
            }
            return UploadImage(data: data, fileName: name, mimeType: type)
        }()
        
        if (!isContentOrImagePresent) {
            errorMessage = "Postitus peab sisaldama vähemalt sisu või pilti!"
            return
        }
        
        isSubmitting = true
        
        do {
            let _ = try await PostService.createPost(title: title, content: content, image: image)
            dismiss()
        } catch let error as JSendFailError<UploadImageFailResponseData> {
            errorMessage = error.data.message
        } catch let error as JSendFailError<CreatePostFailResponseData> {
            errorMessage = error.data.message
        } catch {
            print("DEBUG: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
    
    func mimeType(for data: Data) -> String {
        var byte: UInt8 = 0
        data.copyBytes(to: &byte, count: 1)

        switch byte {
        case 0xFF: return "image/jpeg"
        case 0x89: return "image/png"
        case 0x47: return "image/gif"
        case 0x49, 0x4D: return "image/tiff"
        default:   return "application/octet-stream"
        }
    }
}

#Preview {
    CreatePostView()
        .tint(.pink)
}
