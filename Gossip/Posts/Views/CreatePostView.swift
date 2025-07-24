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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pealkiri")
                        .font(.headline)
                    TextField("", text: $title)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    Text("Sisu")
                        .font(.headline)
                    TextEditor(text: $content)
                        .frame(height: 200)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    
                    Text("Pilt")
                        .font(.headline)

                    HStack {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Vali pilt")
                            }
                            .padding()
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if selectedPhotoItem != nil {
                            Button {
                                selectedPhotoItem = nil
                                selectedImage = nil
                            } label: {
                                Text("Eemalda pilt")
                            }
                        }
                    }

                    if let selectedImage = selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                }
                .padding()
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
                    Button("Tühista") {
                        dismiss()
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
