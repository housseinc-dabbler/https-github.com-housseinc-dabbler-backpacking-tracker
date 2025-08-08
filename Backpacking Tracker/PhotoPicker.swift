// PhotoPicker.swift
import SwiftUI
import PhotosUI

struct PhotoPicker: View {
    @Binding var imageData: Data?

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        HStack {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            withAnimation {
                                self.imageData = nil
                                self.selectedItem = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, .red)
                        }
                        .offset(x: 8, y: -8)
                    }
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                Label("Select Image", systemImage: "photo")
            }
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
    }
}
